// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:test/test.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

void main() {
  group('VerifySignatureUseCase', () {
    late LicensifyKeyPair ecdsaKeyPair;
    late SignDataUseCase signDataUseCase;
    late VerifySignatureUseCase sut;

    setUpAll(() {
      // Генерируем тестовые ECDSA ключи
      ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem();
    });

    setUp(() {
      // Создаем экземпляры классов перед каждым тестом
      signDataUseCase = SignDataUseCase();
      sut = VerifySignatureUseCase();
    });

    test('верифицирует_правильную_подпись', () {
      // Arrange
      final testData = 'test data to verify';
      final signature = signDataUseCase(
        data: testData,
        privateKey: ecdsaKeyPair.privateKey,
      );

      // Act
      final isValid = sut(
        data: testData,
        signature: signature,
        publicKey: ecdsaKeyPair.publicKey,
      );

      // Assert
      expect(isValid, isTrue);
    });

    test('отклоняет_неверную_подпись', () {
      // Arrange
      final testData = 'test data to verify';
      final differentData = 'different data';
      final signature = signDataUseCase(
        data: testData,
        privateKey: ecdsaKeyPair.privateKey,
      );

      // Act - проверяем подпись с другими данными
      final isValid = sut(
        data: differentData,
        signature: signature,
        publicKey: ecdsaKeyPair.publicKey,
      );

      // Assert
      expect(isValid, isFalse);
    });

    test('отклоняет_поврежденную_подпись', () {
      // Arrange
      final testData = 'test data to verify';
      final signature = signDataUseCase(
        data: testData,
        privateKey: ecdsaKeyPair.privateKey,
      );
      final corruptedSignature = 'corrupted${signature.substring(8)}';

      // Act
      final isValid = sut(
        data: testData,
        signature: corruptedSignature,
        publicKey: ecdsaKeyPair.publicKey,
      );

      // Assert
      expect(isValid, isFalse);
    });

    test('использует_указанный_алгоритм_хеширования', () {
      // Arrange
      final testData = 'test data to verify';
      final digest = SHA256Digest();
      final signature = signDataUseCase(
        data: testData,
        privateKey: ecdsaKeyPair.privateKey,
        digest: digest,
      );

      // Act - проверяем с тем же алгоритмом хеширования
      final isValidSameDigest = sut(
        data: testData,
        signature: signature,
        publicKey: ecdsaKeyPair.publicKey,
        digest: digest,
      );

      // Проверяем с другим алгоритмом хеширования
      final isValidDifferentDigest = sut(
        data: testData,
        signature: signature,
        publicKey: ecdsaKeyPair.publicKey,
        digest: SHA512Digest(), // другой алгоритм
      );

      // Assert
      expect(isValidSameDigest, isTrue);
      expect(isValidDifferentDigest, isFalse);
    });

    test('отклоняет_проверку_с_неподходящим_публичным_ключом', () {
      // Arrange
      final testData = 'test data to verify';
      final signature = signDataUseCase(
        data: testData,
        privateKey: ecdsaKeyPair.privateKey,
      );

      // Создаем другую пару ключей
      final anotherKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem();

      // Act
      final isValid = sut(
        data: testData,
        signature: signature,
        publicKey: anotherKeyPair.publicKey, // другой публичный ключ
      );

      // Assert
      expect(isValid, isFalse);
    });

    test('выбрасывает_исключение_при_использовании_RSA_ключа', () {
      // Arrange
      final rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem();
      final testData = 'test data';
      final signature = 'some signature';

      // Act & Assert
      expect(
        () => sut(
          data: testData,
          signature: signature,
          publicKey: rsaKeyPair.publicKey,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
