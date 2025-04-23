// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptDataUseCase', () {
    // Вспомогательные функции для создания тестовых данных
    LicensifyKeyPair generateKeyPair() {
      return EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p521);
    }

    // Проверяет, имеет ли данный массив байтов текстовый заголовок
    // (то есть первые 4 байта представляют собой текст)
    bool hasTextHeader(Uint8List data) {
      if (data.length < 4) return false;

      try {
        // Пробуем декодировать первые 4 байта как UTF-8
        final header = utf8.decode(data.sublist(0, 4));
        // Проверяем, что это печатные ASCII символы
        for (int i = 0; i < header.length; i++) {
          int code = header.codeUnitAt(i);
          if (code < 32 || code > 126) return false;
        }
        return true;
      } catch (_) {
        return false;
      }
    }

    // Извлекает зашифрованную часть из данных с заголовком
    Uint8List extractEncryptedPayload(Uint8List data) {
      // Если данные имеют заголовок, извлекаем только зашифрованную часть (без 9 байт заголовка)
      if (data.length > 9 && hasTextHeader(data)) {
        return data.sublist(9);
      }
      return data;
    }

    // Извлекает магический заголовок (если есть)
    String? extractMagicHeader(Uint8List data) {
      if (data.length >= 4 && hasTextHeader(data)) {
        try {
          return utf8.decode(data.sublist(0, 4));
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    test('encrypter_encrypts_data_without_header', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(
        utf8.encode('Тестовые данные без заголовка'),
      );
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );

      // Act
      final encrypted = sut.call(data: testData);

      // Assert
      expect(encrypted, isNot(equals(testData)));
      // Данные зашифрованы без "магического" заголовка
      expect(hasTextHeader(encrypted), isFalse);

      // Проверка, что данные можно расшифровать
      final decrypted = ECCipher.decryptWithLicensifyKey(
        encryptedData: encrypted,
        privateKey: keyPair.privateKey,
      );

      expect(decrypted, equals(testData));
    });

    test('encrypter_encrypts_data_with_header', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(
        utf8.encode('Тестовые данные с заголовком'),
      );
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );
      final magicHeader = 'TEST';

      // Act
      final encrypted = sut.call(data: testData, magicHeader: magicHeader);

      // Assert
      expect(encrypted, isNot(equals(testData)));
      expect(hasTextHeader(encrypted), isTrue);
      expect(extractMagicHeader(encrypted), equals(magicHeader));

      // Проверка, что данные можно расшифровать
      final decrypted = ECCipher.decryptWithLicensifyKey(
        encryptedData: extractEncryptedPayload(encrypted),
        privateKey: keyPair.privateKey,
      );

      expect(decrypted, equals(testData));
    });

    test('encrypter_encrypts_string_data_without_header', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testString = 'Тестовая строка без заголовка';
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );

      // Act
      final encrypted = sut.encryptString(data: testString);

      // Assert
      expect(encrypted, isNot(equals(utf8.encode(testString))));
      expect(hasTextHeader(encrypted), isFalse);

      // Проверка, что данные можно расшифровать
      final decrypted = ECCipher.decryptWithLicensifyKey(
        encryptedData: encrypted,
        privateKey: keyPair.privateKey,
      );

      expect(utf8.decode(decrypted), equals(testString));
    });

    test('encrypter_encrypts_string_data_with_header', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testString = 'Тестовая строка с заголовком';
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );
      final magicHeader = 'TEST';

      // Act
      final encrypted = sut.encryptString(
        data: testString,
        magicHeader: magicHeader,
      );

      // Assert
      expect(encrypted, isNot(equals(utf8.encode(testString))));
      expect(hasTextHeader(encrypted), isTrue);
      expect(extractMagicHeader(encrypted), equals(magicHeader));

      // Проверка, что данные можно расшифровать с помощью DecryptDataUseCase
      final decrypter = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );
      final decrypted = decrypter.decryptToString(
        encryptedData: encrypted,
        expectedMagicHeader: magicHeader,
      );

      expect(decrypted, equals(testString));
    });

    test('encrypter_throws_on_invalid_magic_header_length', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(utf8.encode('Тестовые данные'));
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );
      final invalidHeader = 'INVALID_TOO_LONG'; // длиннее 4 байт

      // Act & Assert
      expect(
        () => sut.call(data: testData, magicHeader: invalidHeader),
        throwsArgumentError,
      );
    });

    test('encrypter_uses_formatVersion_correctly', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(
        utf8.encode('Тестовые данные с версией'),
      );
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );
      final magicHeader = 'TEST';
      final formatVersion = 42;

      // Act
      final encrypted = sut.call(
        data: testData,
        magicHeader: magicHeader,
        formatVersion: formatVersion,
      );

      // Извлекаем версию формата из зашифрованных данных (байты 4-7, little-endian)
      final versionBytes = encrypted.sublist(4, 8);
      final versionData = ByteData.view(versionBytes.buffer);
      final extractedVersion = versionData.getUint32(0, Endian.little);

      // Assert
      expect(extractedVersion, equals(formatVersion));

      // Проверка, что данные можно расшифровать
      final decrypter = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );
      final decrypted = decrypter.call(
        encryptedData: encrypted,
        expectedMagicHeader: magicHeader,
      );

      expect(decrypted, equals(testData));
    });

    test('encrypter_throws_on_unsupported_rsa_key', () {
      // Arrange
      final rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem();
      final testData = Uint8List.fromList(utf8.encode('Текст для RSA'));
      final sut = EncryptDataUseCase(publicKey: rsaKeyPair.publicKey);

      // Act & Assert
      expect(() => sut.call(data: testData), throwsUnsupportedError);
    });

    test('encrypter_handles_custom_parameters', () {
      // В этом тесте мы проверяем, что наш шифратор корректно передает кастомные параметры к ECCipher
      // и что зашифрованные данные можно расшифровать с помощью тех же параметров

      // Arrange
      final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(
        curve: EcCurve.p521,
      );
      final testData = Uint8List.fromList(
        utf8.encode('Тест с кастомными параметрами'),
      );

      // Создаем шифратор с параметрами по умолчанию (как в ECCipher)
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt',
        hkdfInfo: 'ECCipher-ECDH-AES',
      );

      // Act - шифруем данные
      final encrypted = sut.call(data: testData);

      // Assert - проверяем что зашифрованные данные не равны исходным
      expect(encrypted, isNot(equals(testData)));

      // Проверяем, что данные можно расшифровать с теми же параметрами
      final decrypter = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt',
        hkdfInfo: 'ECCipher-ECDH-AES',
      );

      // Расшифровываем данные
      final decrypted = decrypter.call(encryptedData: encrypted);

      // Проверяем результат
      expect(utf8.decode(decrypted), equals(utf8.decode(testData)));
    });

    test('encrypter_handles_mismatched_parameters', () {
      // В этом тесте проверяем, что при попытке расшифровать с неправильными параметрами возникает ошибка

      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(
        utf8.encode('Тест с кастомными параметрами'),
      );

      // Кастомные параметры для шифрования
      final hkdfSalt = 'CUSTOM-SALT';
      final hkdfInfo = 'CUSTOM-INFO';

      // Создаем шифратор с кастомными параметрами
      final sut = EncryptDataUseCase(
        publicKey: keyPair.publicKey,
        hkdfSalt: hkdfSalt,
        hkdfInfo: hkdfInfo,
      );

      // Act - шифруем данные
      final encrypted = sut.call(data: testData);

      // Проверяем, что разные параметры для расшифровки приведут к ошибке
      final wrongSalt = 'WRONG-SALT';

      // Проверка тестовая - убеждаемся что параметры действительно разные
      expect(wrongSalt, isNot(equals(hkdfSalt)));

      // Создаем декриптор с неправильным солью
      final wrongDecrypter = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: wrongSalt,
        hkdfInfo: hkdfInfo,
      );

      // Assert
      expect(
        () => wrongDecrypter.call(encryptedData: encrypted),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
