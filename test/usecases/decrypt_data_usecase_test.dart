// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:test/test.dart';

void main() {
  group('DecryptDataUseCase', () {
    // Вспомогательные функции для создания тестовых данных
    LicensifyKeyPair generateKeyPair() {
      return EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p521);
    }

    // Непосредственно шифрует данные используя ECCipher без декоратора
    Uint8List encryptWithECCipher({
      required Uint8List data,
      required LicensifyPublicKey publicKey,
      String? hkdfSalt,
      String? hkdfInfo,
      int aesKeySize = 256,
    }) {
      return ECCipher.encryptWithLicensifyKey(
        data: data,
        publicKey: publicKey,
        hkdfSalt: hkdfSalt,
        hkdfInfo: hkdfInfo,
        aesKeySize: aesKeySize,
      );
    }

    // Создает зашифрованные данные с заголовком
    Uint8List createEncryptedDataWithHeader({
      required Uint8List originalData,
      required LicensifyPublicKey publicKey,
      required String magicHeader,
      int formatVersion = 1,
      String? hkdfSalt,
      String? hkdfInfo,
      int aesKeySize = 256,
    }) {
      // Сначала шифруем данные
      final encryptedPayload = encryptWithECCipher(
        data: originalData,
        publicKey: publicKey,
        hkdfSalt: hkdfSalt,
        hkdfInfo: hkdfInfo,
        aesKeySize: aesKeySize,
      );

      // Добавляем заголовок и информацию о формате
      final result = BytesBuilder();

      // Добавляем магический заголовок (4 байта)
      final headerBytes = utf8.encode(magicHeader);
      if (headerBytes.length != 4) {
        throw ArgumentError('Magic header must be exactly 4 bytes long');
      }
      result.add(headerBytes);

      // Добавляем версию формата (4 байта, little-endian)
      final versionBytes = Uint8List(4);
      final versionData = ByteData.view(versionBytes.buffer);
      versionData.setUint32(0, formatVersion, Endian.little);
      result.add(versionBytes);

      // Добавляем тип ключа (1 байт, 1 для ECDSA)
      result.add([1]);

      // Добавляем зашифрованные данные
      result.add(encryptedPayload);

      return result.toBytes();
    }

    test('decrypter_decrypts_data_without_header', () {
      // Arrange
      final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(
        curve: EcCurve.p521,
      );

      final testData = Uint8List.fromList(
        utf8.encode('Тестовые данные без заголовка'),
      );
      final encryptedData = encryptWithECCipher(
        data: testData,
        publicKey: keyPair.publicKey,
        hkdfSalt: 'ECCipher-ECDH-Salt',
        hkdfInfo: 'ECCipher-ECDH-AES',
      );
      final sut = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );

      // Act
      final decrypted = sut.call(encryptedData: encryptedData);

      // Assert
      expect(decrypted, equals(testData));
      expect(utf8.decode(decrypted), equals('Тестовые данные без заголовка'));
    });

    test('decrypter_decrypts_data_with_header', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(
        utf8.encode('Тестовые данные с заголовком'),
      );
      final encryptedData = createEncryptedDataWithHeader(
        originalData: testData,
        publicKey: keyPair.publicKey,
        magicHeader: 'TEST',
        hkdfSalt: 'ECCipher-ECDH-Salt',
        hkdfInfo: 'ECCipher-ECDH-AES',
      );
      final sut = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );

      // Act
      final decrypted = sut.call(
        encryptedData: encryptedData,
        expectedMagicHeader: 'TEST',
      );

      // Assert
      expect(decrypted, equals(testData));
      expect(utf8.decode(decrypted), equals('Тестовые данные с заголовком'));
    });

    test('decrypter_decrypts_string_data_with_header', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testString = 'Тестовая строка с заголовком';
      final testData = Uint8List.fromList(utf8.encode(testString));
      final encryptedData = createEncryptedDataWithHeader(
        originalData: testData,
        publicKey: keyPair.publicKey,
        magicHeader: 'TEST',
        hkdfSalt: 'ECCipher-ECDH-Salt',
        hkdfInfo: 'ECCipher-ECDH-AES',
      );
      final sut = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );

      // Act
      final decrypted = sut.decryptToString(
        encryptedData: encryptedData,
        expectedMagicHeader: 'TEST',
      );

      // Assert
      expect(decrypted, equals(testString));
    });

    test('decrypter_throws_on_wrong_magic_header', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(utf8.encode('Тестовые данные'));
      final encryptedData = createEncryptedDataWithHeader(
        originalData: testData,
        publicKey: keyPair.publicKey,
        magicHeader: 'TEST',
        hkdfSalt: 'ECCipher-ECDH-Salt',
        hkdfInfo: 'ECCipher-ECDH-AES',
      );
      final sut = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );

      // Act & Assert
      expect(
        () =>
            sut.call(encryptedData: encryptedData, expectedMagicHeader: 'DIFF'),
        throwsFormatException,
      );
    });

    test('decrypter_works_with_different_format_versions', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(
        utf8.encode('Данные с другой версией формата'),
      );
      final encryptedData = createEncryptedDataWithHeader(
        originalData: testData,
        publicKey: keyPair.publicKey,
        magicHeader: 'TEST',
        formatVersion: 2,
        hkdfSalt: 'ECCipher-ECDH-Salt',
        hkdfInfo: 'ECCipher-ECDH-AES',
      );
      final sut = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        hkdfSalt: 'ECCipher-ECDH-Salt', // совпадает с ECCipher
        hkdfInfo: 'ECCipher-ECDH-AES', // совпадает с ECCipher
      );

      // Act
      final decrypted = sut.call(
        encryptedData: encryptedData,
        expectedMagicHeader: 'TEST',
      );

      // Assert
      expect(decrypted, equals(testData));
    });

    test('decrypter_throws_on_unsupported_rsa_key', () {
      // Arrange
      final rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem();
      final testData = Uint8List.fromList(utf8.encode('Текст для RSA'));
      final sut = DecryptDataUseCase(privateKey: rsaKeyPair.privateKey);

      // Act & Assert
      expect(() => sut.call(encryptedData: testData), throwsUnsupportedError);
    });

    test('decrypter_handles_custom_parameters', () {
      // Arrange
      final keyPair = generateKeyPair();
      final testData = Uint8List.fromList(
        utf8.encode('Тест с кастомными параметрами'),
      );

      // Кастомные параметры
      final hkdfSalt = 'CUSTOM-SALT';
      final hkdfInfo = 'CUSTOM-INFO';
      final aesKeySize = 192;

      // Шифрование с использованием кастомных параметров
      final encryptedData = encryptWithECCipher(
        data: testData,
        publicKey: keyPair.publicKey,
        hkdfSalt: hkdfSalt,
        hkdfInfo: hkdfInfo,
        aesKeySize: aesKeySize,
      );

      // Создаем декриптор с теми же параметрами
      final sut = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        aesKeySize: aesKeySize,
        hkdfSalt: hkdfSalt,
        hkdfInfo: hkdfInfo,
      );

      // Act
      final decrypted = sut.call(encryptedData: encryptedData);

      // Assert
      expect(decrypted, equals(testData));

      // Проверка, что с другими параметрами не работает
      final wrongSalt = 'WRONG-SALT';
      expect(wrongSalt, isNot(equals(hkdfSalt))); // Проверка теста

      final wrongDecrypter = DecryptDataUseCase(
        privateKey: keyPair.privateKey,
        aesKeySize: aesKeySize,
        hkdfSalt: wrongSalt,
        hkdfInfo: hkdfInfo,
      );

      expect(
        () => wrongDecrypter.call(encryptedData: encryptedData),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
