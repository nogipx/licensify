// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:test/test.dart';

import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('CheckLicenseUseCase', () {
    late LicenseValidator validator;
    late CheckLicenseUseCase sut;

    setUp(() {
      validator = LicenseValidator(publicKey: TestConstants.testPublicKey);
      sut = CheckLicenseUseCase(validator: validator);
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
      expect(result.isInvalid, isTrue);
    });

    test('определяет_просроченную_лицензию', () async {
      // Arrange - создаем просроченную лицензию с валидной подписью
      final expiredDate = DateTime.now().subtract(Duration(days: 1));
      final expiredLicense = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: expiredDate,
      );

      // Act
      final result = await sut(expiredLicense);

      // Assert
      expect(result.isExpired, isTrue);
      expect(
        (result as ExpiredLicenseStatus).license.id,
        equals(expiredLicense.id),
      );
    });

    test('определяет_действующую_лицензию', () async {
      // Arrange - создаем действующую лицензию с валидной подписью
      final validLicense = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Act
      final result = await sut(validLicense);

      // Assert
      expect(result.isActive, isTrue);
      expect(
        (result as ActiveLicenseStatus).license.id,
        equals(validLicense.id),
      );
    });
  });
}
