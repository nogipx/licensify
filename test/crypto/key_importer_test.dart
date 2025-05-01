// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('LicensifyKeyImporter', () {
    late LicensifyKeyPair rsaKeyPair;
    late LicensifyKeyPair ecdsaKeyPair;
    late Uint8List rsaPrivateKeyBytes;
    late Uint8List rsaPublicKeyBytes;
    late Uint8List ecdsaPrivateKeyBytes;
    late Uint8List ecdsaPublicKeyBytes;

    // Тестовые параметры для ECDSA ключей
    const testPrivateScalar =
        'd1b71758e219652b8c4ff3edd77a337d536c65a4278c93a41887d132b1cb8673';
    const testCurveName = 'prime256v1';

    setUpAll(() {
      // Генерируем тестовые ключи
      rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem();
      ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem();

      // Конвертируем строки ключей в байты
      rsaPrivateKeyBytes = Uint8List.fromList(
        utf8.encode(rsaKeyPair.privateKey.content),
      );
      rsaPublicKeyBytes = Uint8List.fromList(
        utf8.encode(rsaKeyPair.publicKey.content),
      );

      ecdsaPrivateKeyBytes = Uint8List.fromList(
        utf8.encode(ecdsaKeyPair.privateKey.content),
      );
      ecdsaPublicKeyBytes = Uint8List.fromList(
        utf8.encode(ecdsaKeyPair.publicKey.content),
      );
    });

    test('Импорт RSA ключей из строк', () {
      // Act
      final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(
        rsaKeyPair.privateKey.content,
      );
      final publicKey = LicensifyKeyImporter.importPublicKeyFromString(
        rsaKeyPair.publicKey.content,
      );

      // Assert
      expect(privateKey.keyType, equals(LicensifyKeyType.rsa));
      expect(publicKey.keyType, equals(LicensifyKeyType.rsa));
      expect(privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт пары RSA ключей из строк', () {
      // Act
      final keyPair = LicensifyKeyImporter.importKeyPairFromStrings(
        privateKeyPem: rsaKeyPair.privateKey.content,
        publicKeyPem: rsaKeyPair.publicKey.content,
      );

      // Assert
      expect(keyPair.keyType, equals(LicensifyKeyType.rsa));
      expect(keyPair.isConsistent, isTrue);
      expect(keyPair.privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(keyPair.publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт RSA ключей из байтов', () {
      // Act
      final privateKey = LicensifyKeyImporter.importPrivateKeyFromBytes(
        rsaPrivateKeyBytes,
      );
      final publicKey = LicensifyKeyImporter.importPublicKeyFromBytes(
        rsaPublicKeyBytes,
      );

      // Assert
      expect(privateKey.keyType, equals(LicensifyKeyType.rsa));
      expect(publicKey.keyType, equals(LicensifyKeyType.rsa));
      expect(privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт пары RSA ключей из байтов', () {
      // Act
      final keyPair = LicensifyKeyImporter.importKeyPairFromBytes(
        privateKeyBytes: rsaPrivateKeyBytes,
        publicKeyBytes: rsaPublicKeyBytes,
      );

      // Assert
      expect(keyPair.keyType, equals(LicensifyKeyType.rsa));
      expect(keyPair.isConsistent, isTrue);
      expect(keyPair.privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(keyPair.publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт ECDSA ключей из байтов', () {
      // Act
      final privateKey = LicensifyKeyImporter.importPrivateKeyFromBytes(
        ecdsaPrivateKeyBytes,
      );
      final publicKey = LicensifyKeyImporter.importPublicKeyFromBytes(
        ecdsaPublicKeyBytes,
      );

      // Assert
      expect(privateKey.keyType, equals(LicensifyKeyType.ecdsa));
      expect(publicKey.keyType, equals(LicensifyKeyType.ecdsa));
      expect(privateKey.content, equals(ecdsaKeyPair.privateKey.content));
      expect(publicKey.content, equals(ecdsaKeyPair.publicKey.content));
    });

    test('Импорт пары ECDSA ключей из байтов', () {
      // Act
      final keyPair = LicensifyKeyImporter.importKeyPairFromBytes(
        privateKeyBytes: ecdsaPrivateKeyBytes,
        publicKeyBytes: ecdsaPublicKeyBytes,
      );

      // Assert
      expect(keyPair.keyType, equals(LicensifyKeyType.ecdsa));
      expect(keyPair.isConsistent, isTrue);
    });

    test('Ошибка при несовместимых типах ключей', () {
      // Act & Assert
      expect(
        () => LicensifyKeyImporter.importKeyPairFromStrings(
          privateKeyPem: rsaKeyPair.privateKey.content,
          publicKeyPem: ecdsaKeyPair.publicKey.content,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LicensifyKeyImporter.importKeyPairFromBytes(
          privateKeyBytes: rsaPrivateKeyBytes,
          publicKeyBytes: ecdsaPublicKeyBytes,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Ошибка при неверном формате ключа', () {
      // Act & Assert
      expect(
        () =>
            LicensifyKeyImporter.importPrivateKeyFromString('not a valid key'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LicensifyKeyImporter.importPublicKeyFromString(''),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LicensifyKeyImporter.importPrivateKeyFromBytes(
          Uint8List.fromList(utf8.encode('not a valid key')),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    // Новые тесты для новых методов

    group('Импорт из параметров ECDSA', () {
      test('importEcdsaPublicKeyFromCoordinates создает корректный ключ', () {
        // Сначала получаем координаты из приватного ключа для теста
        final coordinates = EcdsaParamsConverter.derivePublicKeyCoordinates(
          d: testPrivateScalar,
          curveName: testCurveName,
        );

        // Act
        final publicKey =
            LicensifyKeyImporter.importEcdsaPublicKeyFromCoordinates(
              x: coordinates['x']!,
              y: coordinates['y']!,
              curveName: testCurveName,
            );

        // Assert
        expect(publicKey, isA<LicensifyPublicKey>());
        expect(publicKey.keyType, equals(LicensifyKeyType.ecdsa));
        expect(publicKey.content, contains('-----BEGIN PUBLIC KEY-----'));
        expect(publicKey.content, contains('-----END PUBLIC KEY-----'));
      });

      test('importEcdsaPrivateKeyFromScalar создает корректный ключ', () {
        // Act
        final privateKey = LicensifyKeyImporter.importEcdsaPrivateKeyFromScalar(
          d: testPrivateScalar,
          curveName: testCurveName,
        );

        // Assert
        expect(privateKey, isA<LicensifyPrivateKey>());
        expect(privateKey.keyType, equals(LicensifyKeyType.ecdsa));
        expect(privateKey.content, contains('-----BEGIN EC PRIVATE KEY-----'));
        expect(privateKey.content, contains('-----END EC PRIVATE KEY-----'));
      });

      test(
        'importEcdsaKeyPairFromPrivateScalar создает корректную пару ключей',
        () {
          // Act
          final keyPair =
              LicensifyKeyImporter.importEcdsaKeyPairFromPrivateScalar(
                d: testPrivateScalar,
                curveName: testCurveName,
              );

          // Assert
          expect(keyPair, isA<LicensifyKeyPair>());
          expect(keyPair.keyType, equals(LicensifyKeyType.ecdsa));
          expect(keyPair.isConsistent, isTrue);
          expect(keyPair.privateKey.keyType, equals(LicensifyKeyType.ecdsa));
          expect(keyPair.publicKey.keyType, equals(LicensifyKeyType.ecdsa));

          // Проверяем, что публичный ключ соответствует приватному
          // Используем ту же пару для подписи и проверки
          final testData = 'test data for signing';
          final signDataUseCase = SignDataUseCase();
          final verifySignatureUseCase = VerifySignatureUseCase();

          // Подписываем данные приватным ключом
          final signature = signDataUseCase(
            data: testData,
            privateKey: keyPair.privateKey,
          );

          // Проверяем подпись публичным ключом той же пары
          final isValid = verifySignatureUseCase(
            data: testData,
            signature: signature,
            publicKey: keyPair.publicKey,
          );

          expect(
            isValid,
            isTrue,
            reason: 'Signature should be valid with corresponding public key',
          );
        },
      );

      test('ключи из параметров работают с операциями подписи/проверки', () {
        // Arrange - получаем согласованную пару ключей
        final keyPair =
            LicensifyKeyImporter.importEcdsaKeyPairFromPrivateScalar(
              d: testPrivateScalar,
              curveName: testCurveName,
            );

        final testData = 'data to be signed';
        final signDataUseCase = SignDataUseCase();
        final verifySignatureUseCase = VerifySignatureUseCase();

        // Act
        final signature = signDataUseCase(
          data: testData,
          privateKey: keyPair.privateKey,
        );

        final isValid = verifySignatureUseCase(
          data: testData,
          signature: signature,
          publicKey: keyPair.publicKey,
        );

        // Assert
        expect(isValid, isTrue, reason: 'Signature should be valid');
      });
    });
  });
}
