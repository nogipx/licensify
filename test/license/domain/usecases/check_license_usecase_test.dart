// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:test/test.dart';

import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('CheckLicenseUseCase с RSA ключами', () {
    late LicenseValidator validator;
    late LicenseValidateUseCase sut;

    setUp(() {
      validator = LicenseValidator(
        publicKey: TestConstants.testKeyPair.publicKey,
      );
      sut = LicenseValidateUseCase(validator: validator);
    });

    test('сообщает_что_лицензия_отсутствует', () async {
      // Arrange - хранилище пустое

      // Act
      final result = await sut(null);

      // Assert
      expect(result.isNoLicense, isTrue);
    });

    test('определяет_недействительную_лицензию', () async {
      // Arrange - создаем лицензию с неверной подписью
      final license = License(
        id: 'test-id',
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
        createdAt: DateTime.now(),
        signature: base64Encode(utf8.encode('invalid_signature')),
        type: LicenseType.trial,
      );

      // Act
      final result = await sut(license);

      // Assert
      expect(result.isInvalidSignature, isTrue);
    });

    test('определяет_просроченную_лицензию_с_RSA_подписью', () async {
      // Arrange - создаем просроченную лицензию с валидной подписью RSA
      final expiredDate = DateTime.now().subtract(
        Duration(days: 7),
      ); // Гарантированно просроченная лицензия - неделю назад
      final expiredLicense = LicenseGenerateUseCase(
        privateKey: TestConstants.testKeyPair.privateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: expiredDate,
      );

      print('Проверка истечения срока лицензии RSA:');
      print('Текущая дата: ${DateTime.now().toIso8601String()}');
      print(
        'Дата истечения: ${expiredLicense.expirationDate.toIso8601String()}',
      );
      print('isExpired по прямой проверке: ${expiredLicense.isExpired}');

      // Проверяем, что validateExpiration правильно работает
      final expirationResult = validator.validateExpiration(expiredLicense);
      print(
        'Результат validator.validateExpiration: ${expirationResult.isValid}',
      );

      // Act
      final result = await sut(expiredLicense);
      print('Тип результата: ${result.status.runtimeType}');

      // Assert - проверяем, что лицензия отмечена как просроченная
      expect(
        result.isExpired,
        isTrue,
        reason:
            'Просроченная лицензия с RSA подписью должна иметь isExpired = true',
      );
      // isActive должен быть false, так как лицензия просрочена
      expect(
        result.isActive,
        isFalse,
        reason: 'Просроченная лицензия с RSA подписью не должна быть активной',
      );
      expect(result.license?.id, equals(expiredLicense.id));
    });

    test('определяет_действующую_лицензию', () async {
      // Arrange - создаем действующую лицензию с валидной подписью
      final validLicense = LicenseGenerateUseCase(
        privateKey: TestConstants.testKeyPair.privateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Act
      final result = await sut(validLicense);

      // Assert
      expect(result.isActive, isTrue);
      expect(result.license?.id, equals(validLicense.id));
    });
  });

  // Добавляем тесты с ECDSA ключами
  group('CheckLicenseUseCase с ECDSA ключами', () {
    // Ищем константы для ECDSA
    late LicenseValidator validator;
    late LicenseValidateUseCase sut;

    setUp(() async {
      validator = LicenseValidator(
        publicKey: TestConstants.testKeyPair.publicKey,
      );
      sut = LicenseValidateUseCase(validator: validator);
    });

    test('определяет_просроченную_лицензию_с_ECDSA_подписью', () async {
      // Arrange - создаем просроченную лицензию с валидной ECDSA подписью
      final expiredDate = DateTime.now().subtract(
        Duration(days: 7),
      ); // Гарантированно просроченная лицензия - неделю назад
      final expiredLicense = LicenseGenerateUseCase(
        privateKey: TestConstants.testKeyPair.privateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: expiredDate,
      );

      print('Проверка истечения срока лицензии ECDSA:');
      print('Текущая дата: ${DateTime.now().toIso8601String()}');
      print(
        'Дата истечения: ${expiredLicense.expirationDate.toIso8601String()}',
      );
      print('isExpired по прямой проверке: ${expiredLicense.isExpired}');

      // Проверяем, что validateExpiration правильно работает
      final expirationResult = validator.validateExpiration(expiredLicense);
      print(
        'Результат validator.validateExpiration: ${expirationResult.isValid}',
      );

      // Act
      final result = await sut(expiredLicense);
      print('Тип результата: ${result.status.runtimeType}');

      // Assert - проверяем, что лицензия отмечена как просроченная
      expect(
        result.isExpired,
        isTrue,
        reason:
            'Просроченная лицензия с ECDSA подписью должна иметь isExpired = true',
      );
      // isActive должен быть false, так как лицензия просрочена
      expect(
        result.isActive,
        isFalse,
        reason:
            'Просроченная лицензия с ECDSA подписью не должна быть активной',
      );
      expect(result.license?.id, equals(expiredLicense.id));
    });

    test('определяет_действующую_лицензию_с_ECDSA_подписью', () async {
      // Arrange - создаем действующую лицензию с валидной ECDSA подписью
      final validLicense = LicenseGenerateUseCase(
        privateKey: TestConstants.testKeyPair.privateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Act
      final result = await sut(validLicense);

      // Assert
      expect(result.isActive, isTrue);
      expect(result.license?.id, equals(validLicense.id));
    });
  });
}
