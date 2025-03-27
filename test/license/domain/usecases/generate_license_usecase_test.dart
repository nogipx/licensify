// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('GenerateLicenseUseCase', () {
    test('creates valid license with specified parameters', () {
      // Arrange
      final sut = TestConstants.testKeyPair.privateKey.licenseGenerator;
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();
      final features = {'maxUsers': 10, 'canExport': true};

      // Act
      final license = sut(
        appId: TestConstants.testAppId,
        expirationDate: expirationDate,
        type: LicenseType.pro,
        features: features,
      );

      // Assert
      expect(license.id, isNotEmpty);
      expect(license.appId, equals(TestConstants.testAppId));
      expect(license.expirationDate, equals(expirationDate));
      expect(license.type, equals(LicenseType.pro));
      expect(license.features, equals(features));
      expect(license.signature, isNotEmpty);
      expect(license.createdAt.isUtc, isTrue);
    });

    test('creates valid RSA signature', () {
      // Arrange
      final sut = TestConstants.testKeyPair.privateKey.licenseGenerator;
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();

      // Act
      final license = sut(
        appId: TestConstants.testAppId,
        expirationDate: expirationDate,
      );

      // Verify the signature using the validator
      final validator = LicenseValidator(
        publicKey: TestConstants.testKeyPair.publicKey,
      );
      final isValid = validator.validateSignature(license);

      // Assert
      expect(isValid.isValid, isTrue);
    });

    test('signature is valid only with correct key pair', () {
      // Arrange
      final sut = TestConstants.testKeyPair.privateKey.licenseGenerator;
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();

      // Generate a new key pair
      final differentKeys = TestConstants.generateTestKeyPair();

      // Act
      final license = sut(
        appId: TestConstants.testAppId,
        expirationDate: expirationDate,
      );

      // Verify with wrong public key
      final wrongValidator = LicenseValidator(
        publicKey: differentKeys.publicKey,
      );
      final isValidWithWrongKey = wrongValidator.validateSignature(license);

      // Verify with correct public key
      final correctValidator = LicenseValidator(
        publicKey: TestConstants.testKeyPair.publicKey,
      );
      final isValidWithCorrectKey = correctValidator.validateSignature(license);

      // Assert
      expect(
        isValidWithWrongKey.isValid,
        isFalse,
        reason: 'Signature should not be valid with incorrect public key',
      );
      expect(
        isValidWithCorrectKey.isValid,
        isTrue,
        reason: 'Signature should be valid with correct public key',
      );
    });

    test('creates trial license by default', () {
      // Arrange
      final sut = TestConstants.testKeyPair.privateKey.licenseGenerator;

      // Act
      final license = sut(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(
          Duration(days: TestConstants.defaultLicenseDuration),
        ),
      );

      // Assert
      expect(license.type, equals(LicenseType.trial));
    });

    test('serializes license to binary format with header', () {
      // Arrange
      final sut = TestConstants.testKeyPair.privateKey.licenseGenerator;
      final license = sut(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(
          Duration(days: TestConstants.defaultLicenseDuration),
        ),
        type: LicenseType.standard,
        features: {'maxUsers': 5},
      );

      // Act
      final bytes = LicenseEncoder.encodeToBytes(license);

      // Assert
      // Check magic header
      expect(
        utf8.decode(bytes.sublist(0, 4)),
        equals(LicenseEncoder.magicHeader),
      );

      // Check format version
      final versionData = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes + 4,
        4,
      );
      final version = versionData.getUint32(0, Endian.little);
      expect(version, equals(LicenseEncoder.formatVersion));

      // Decode license data
      final decodedLicense = LicenseEncoder.decodeFromBytes(bytes);
      expect(decodedLicense, isNotNull);
      expect(decodedLicense.id, equals(license.id));
      expect(decodedLicense.appId, equals(license.appId));
      expect(decodedLicense.signature, equals(license.signature));
      expect(decodedLicense.type.name, equals(license.type.name));
      expect(decodedLicense.features['maxUsers'], equals(5));
    });
  });
}
