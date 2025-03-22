// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:test/test.dart';

import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('LicenseValidator', () {
    test('подтверждает_корректную_подпись_лицензии', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Сначала создаем валидную лицензию с GenerateLicenseUseCase для проверки
      final license = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
        type: LicenseType.trial,
      );

      // Act
      final result = sut.validateSignature(license);

      // Assert
      expect(result, isTrue);
    });

    test('отклоняет_лицензию_с_неверной_подписью', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Создаем лицензию с заведомо неверной подписью в формате base64
      final license = License(
        id: 'test-id',
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
        createdAt: DateTime.now(),
        signature: base64Encode(utf8.encode('invalid_signature')), // Корректный base64 формат
        type: LicenseType.trial,
      );

      // Act
      final result = sut.validateSignature(license);

      // Assert
      expect(result, isFalse);
    });

    test('отклоняет_лицензию_с_неправильным_ключом', () {
      // Arrange
      final differentKeys = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

      // Создаем лицензию с одним ключом
      final license = GenerateLicenseUseCase(privateKey: differentKeys.privateKey).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Пытаемся проверить другим ключом
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Act
      final result = sut.validateSignature(license);

      // Assert
      expect(result, isFalse);
    });

    test('подтверждает_действие_непросроченной_лицензии', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);
      final license = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Act
      final result = sut.validateExpiration(license);

      // Assert
      expect(result, isTrue);
    });

    test('отклоняет_просроченную_лицензию', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Создаем просроченную лицензию
      final expiredDate = DateTime.now().subtract(Duration(days: 1));
      final license = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(appId: TestConstants.testAppId, expirationDate: expiredDate);

      // Act
      final result = sut.validateExpiration(license);

      // Assert
      expect(result, isFalse);
    });

    test('подтверждает_полностью_валидную_лицензию', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);
      final license = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Act
      final result = sut.validateLicense(license);

      // Assert
      expect(result, isTrue);
    });

    test('отклоняет_лицензию_с_валидной_подписью_но_просроченную', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Создаем просроченную лицензию с валидной подписью
      final expiredDate = DateTime.now().subtract(Duration(days: 1));
      final license = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(appId: TestConstants.testAppId, expirationDate: expiredDate);

      // Act
      final result = sut.validateLicense(license);

      // Assert
      expect(result, isFalse);
    });

    test('отклоняет_лицензию_с_неверной_подписью_но_действующим_сроком', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Создаем лицензию с заведомо неверной подписью в формате base64
      final license = License(
        id: 'test-id',
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
        createdAt: DateTime.now(),
        signature: base64Encode(utf8.encode('invalid_signature')), // Корректный base64 формат
        type: LicenseType.trial,
      );

      // Act
      final result = sut.validateLicense(license);

      // Assert
      expect(result, isFalse);
    });

    test('микросекунды_и_секунды_не_влияют_на_валидацию_подписи', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Создаем лицензию
      final license = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Модифицируем лицензию так, чтобы добавить секунды и миллисекунды,
      // но сохранить UTC и тот же час и минуту
      final utcExpirationDate = license.expirationDate;
      final licenseWithSeconds = License(
        id: license.id,
        appId: license.appId,
        expirationDate: DateTime.utc(
          utcExpirationDate.year,
          utcExpirationDate.month,
          utcExpirationDate.day,
          utcExpirationDate.hour,
          utcExpirationDate.minute,
          30, // Добавляем 30 секунд
          500, // Добавляем 500 миллисекунд
        ),
        createdAt: license.createdAt,
        signature: license.signature,
        type: license.type,
        features: license.features,
      );

      // Act
      final result = sut.validateSignature(licenseWithSeconds);

      // Assert
      expect(result, isTrue);
    });

    test('отклоняет_лицензию_при_любом_изменении_полей', () {
      // Arrange
      final sut = LicenseValidator(publicKey: TestConstants.testPublicKey);

      // Создаем валидную лицензию с тестовыми данными
      final validLicense = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
        type: LicenseType.pro,
        features: {'maxUsers': 10, 'premium': true},
        metadata: {'owner': 'Test Corp', 'email': 'test@example.com'},
      );

      // Проверяем, что исходная лицензия валидна
      expect(sut.validateSignature(validLicense), isTrue);

      // Тестируем изменение id
      final tamperedId = License(
        id: 'tampered-id',
        appId: validLicense.appId,
        expirationDate: validLicense.expirationDate,
        createdAt: validLicense.createdAt,
        signature: validLicense.signature,
        type: validLicense.type,
        features: validLicense.features,
        metadata: validLicense.metadata,
      );
      expect(
        sut.validateSignature(tamperedId),
        isFalse,
        reason: 'Изменение ID должно делать подпись невалидной',
      );

      // Тестируем изменение appId
      final tamperedAppId = License(
        id: validLicense.id,
        appId: 'com.hacked.app',
        expirationDate: validLicense.expirationDate,
        createdAt: validLicense.createdAt,
        signature: validLicense.signature,
        type: validLicense.type,
        features: validLicense.features,
        metadata: validLicense.metadata,
      );
      expect(
        sut.validateSignature(tamperedAppId),
        isFalse,
        reason: 'Изменение appId должно делать подпись невалидной',
      );

      // Тестируем изменение типа лицензии
      final tamperedType = License(
        id: validLicense.id,
        appId: validLicense.appId,
        expirationDate: validLicense.expirationDate,
        createdAt: validLicense.createdAt,
        signature: validLicense.signature,
        type: LicenseType.trial, // Изменен тип с pro на trial
        features: validLicense.features,
        metadata: validLicense.metadata,
      );
      expect(
        sut.validateSignature(tamperedType),
        isFalse,
        reason: 'Изменение типа лицензии должно делать подпись невалидной',
      );

      // Тестируем изменение срока действия
      final tamperedExpiration = License(
        id: validLicense.id,
        appId: validLicense.appId,
        expirationDate: validLicense.expirationDate.add(Duration(days: 365)), // Добавили год
        createdAt: validLicense.createdAt,
        signature: validLicense.signature,
        type: validLicense.type,
        features: validLicense.features,
        metadata: validLicense.metadata,
      );
      expect(
        sut.validateSignature(tamperedExpiration),
        isFalse,
        reason: 'Изменение срока действия должно делать подпись невалидной',
      );

      // Тестируем изменение features
      final tamperedFeatures = License(
        id: validLicense.id,
        appId: validLicense.appId,
        expirationDate: validLicense.expirationDate,
        createdAt: validLicense.createdAt,
        signature: validLicense.signature,
        type: validLicense.type,
        features: {
          'maxUsers': 1000,
          'premium': true,
          'extraFeature': 'unlocked',
        }, // Изменили features
        metadata: validLicense.metadata,
      );
      expect(
        sut.validateSignature(tamperedFeatures),
        isFalse,
        reason: 'Изменение features должно делать подпись невалидной',
      );

      // Тестируем изменение metadata
      final tamperedMetadata = License(
        id: validLicense.id,
        appId: validLicense.appId,
        expirationDate: validLicense.expirationDate,
        createdAt: validLicense.createdAt,
        signature: validLicense.signature,
        type: validLicense.type,
        features: validLicense.features,
        metadata: {'owner': 'Hacker Inc', 'email': 'hacker@example.com'}, // Изменили metadata
      );
      expect(
        sut.validateSignature(tamperedMetadata),
        isFalse,
        reason: 'Изменение metadata должно делать подпись невалидной',
      );
    });
  });
}
