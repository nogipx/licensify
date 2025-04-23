// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:test/test.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

void main() {
  group('SignDataUseCase', () {
    late LicensifyKeyPair ecdsaKeyPair;
    late SignDataUseCase sut;

    setUpAll(() {
      // Генерируем тестовые ECDSA ключи
      ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem();
    });

    setUp(() {
      // Создаем новый экземпляр тестируемого класса перед каждым тестом
      sut = SignDataUseCase();
    });

    test('создает_правильную_подпись_для_валидных_данных', () {
      // Arrange
      final testData = 'test data to sign';
      final privateKey = ecdsaKeyPair.privateKey;

      // Act
      final signature = sut(data: testData, privateKey: privateKey);

      // Assert
      expect(signature, isNotEmpty);
      expect(signature, isA<String>());

      // Verify signature with VerifySignatureUseCase
      final verifier = VerifySignatureUseCase();
      final isValid = verifier(
        data: testData,
        signature: signature,
        publicKey: ecdsaKeyPair.publicKey,
      );

      expect(isValid, isTrue);
    });

    test('создает_разные_подписи_для_разных_данных', () {
      // Arrange
      final testData1 = 'test data 1';
      final testData2 = 'test data 2';
      final privateKey = ecdsaKeyPair.privateKey;

      // Act
      final signature1 = sut(data: testData1, privateKey: privateKey);

      final signature2 = sut(data: testData2, privateKey: privateKey);

      // Assert
      expect(signature1, isNot(equals(signature2)));
    });

    test('использует_указанный_алгоритм_хеширования', () {
      // Arrange
      final testData = 'test data to sign';
      final privateKey = ecdsaKeyPair.privateKey;
      final digest = SHA256Digest();

      // Act
      final signature = sut(
        data: testData,
        privateKey: privateKey,
        digest: digest,
      );

      // Assert
      expect(signature, isNotEmpty);

      // Verify with same digest algorithm
      final verifier = VerifySignatureUseCase();
      final isValid = verifier(
        data: testData,
        signature: signature,
        publicKey: ecdsaKeyPair.publicKey,
        digest: digest,
      );

      expect(isValid, isTrue);

      // Should fail if verified with different digest
      final isValidWithWrongDigest = verifier(
        data: testData,
        signature: signature,
        publicKey: ecdsaKeyPair.publicKey,
        digest: SHA512Digest(), // Different digest
      );

      expect(isValidWithWrongDigest, isFalse);
    });

    test('выбрасывает_исключение_при_использовании_RSA_ключа', () {
      // Arrange
      final rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem();
      final testData = 'test data';

      // Act & Assert
      expect(
        () => sut(data: testData, privateKey: rsaKeyPair.privateKey),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('выбрасывает_исключение_при_некорректном_ключе', () {
      // Arrange
      // Создаем поврежденную копию рабочего ключа (удаляем часть содержимого)
      final validKey = ecdsaKeyPair.privateKey.content;
      final corruptedKeyContent =
          validKey.substring(0, 30) + validKey.substring(validKey.length - 30);

      final invalidKey = LicensifyPrivateKey.ecdsa(corruptedKeyContent);

      final testData = 'test data';

      // Act & Assert
      expect(
        () => sut(data: testData, privateKey: invalidKey),
        throwsA(isA<Exception>()),
      );
    });
  });
}
