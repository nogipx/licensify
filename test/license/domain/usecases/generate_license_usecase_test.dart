// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('GenerateLicenseUseCase', () {
    test('создает_валидную_лицензию_с_заданными_параметрами', () {
      // Arrange
      final sut = GenerateLicenseUseCase(privateKey: TestConstants.privateKey);
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();
      final features = {'maxUsers': 10, 'canExport': true};

      // Act
      final license = sut.generateLicense(
        appId: TestConstants.appId,
        expirationDate: expirationDate,
        type: LicenseType.pro,
        features: features,
      );

      // Assert
      expect(license.id, isNotEmpty);
      expect(license.appId, equals(TestConstants.appId));
      expect(license.expirationDate, equals(expirationDate));
      expect(license.type, equals(LicenseType.pro));
      expect(license.features, equals(features));
      expect(license.signature, isNotEmpty);
      expect(license.createdAt.isUtc, isTrue);
    });

    test('создает_действительную_подпись_RSA', () {
      // Arrange
      final sut = GenerateLicenseUseCase(privateKey: TestConstants.privateKey);
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();

      // Act
      final license = sut.generateLicense(
        appId: TestConstants.appId,
        expirationDate: expirationDate,
      );

      // Verify the signature using the validator
      final validator = LicenseValidator(publicKey: TestConstants.publicKey);
      final isValid = validator.validateSignature(license);

      // Assert
      expect(isValid, isTrue);
    });

    test('подпись_валидна_только_для_правильной_пары_ключей', () {
      // Arrange
      final sut = GenerateLicenseUseCase(privateKey: TestConstants.privateKey);
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();

      // Генерируем новую пару ключей
      final differentKeys = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

      // Act
      final license = sut.generateLicense(
        appId: TestConstants.appId,
        expirationDate: expirationDate,
      );

      // Verify with wrong public key
      final wrongValidator = LicenseValidator(publicKey: differentKeys.publicKey);
      final isValidWithWrongKey = wrongValidator.validateSignature(license);

      // Verify with correct public key
      final correctValidator = LicenseValidator(publicKey: TestConstants.publicKey);
      final isValidWithCorrectKey = correctValidator.validateSignature(license);

      // Assert
      expect(
        isValidWithWrongKey,
        isFalse,
        reason: 'Подпись не должна быть валидна с неправильным публичным ключом',
      );
      expect(
        isValidWithCorrectKey,
        isTrue,
        reason: 'Подпись должна быть валидна с правильным публичным ключом',
      );
    });

    test('по_умолчанию_создает_пробную_лицензию', () {
      // Arrange
      final sut = GenerateLicenseUseCase(privateKey: TestConstants.privateKey);

      // Act
      final license = sut.generateLicense(
        appId: TestConstants.appId,
        expirationDate: DateTime.now().add(Duration(days: TestConstants.defaultLicenseDuration)),
      );

      // Assert
      expect(license.type, equals(LicenseType.trial));
    });

    test('сериализует_лицензию_в_JSON_байты', () {
      // Arrange
      final sut = GenerateLicenseUseCase(privateKey: TestConstants.privateKey);
      final license = sut.generateLicense(
        appId: TestConstants.appId,
        expirationDate: DateTime.now().add(Duration(days: TestConstants.defaultLicenseDuration)),
        type: LicenseType.standard,
        features: {'maxUsers': 5},
      );

      // Act
      final bytes = sut.licenseToBytes(license);

      // Assert
      final jsonString = utf8.decode(bytes);
      final jsonData = jsonDecode(jsonString);

      expect(jsonData['id'], equals(license.id));
      expect(jsonData['appId'], equals(license.appId));
      expect(jsonData['signature'], equals(license.signature));
      expect(jsonData['type'], equals(license.type.name));
      expect(jsonData['features']['maxUsers'], equals(5));
    });
  });
}
