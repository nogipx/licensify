// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('LicenseRepository', () {
    late InMemoryLicenseStorage storage;
    late LicenseRepository sut;
    late LicenseGenerator licenseGenerator;

    setUp(() {
      storage = InMemoryLicenseStorage();
      sut = LicenseRepository(storage: storage);
      licenseGenerator = TestConstants.testKeyPair.privateKey.licenseGenerator;
    });

    test('returns null when license is missing', () async {
      // Arrange - storage is empty by default

      // Act
      final result = await sut.getCurrentLicense();

      // Assert
      expect(result, isNull);
    });

    test('loads valid license from storage', () async {
      // Arrange
      final license = licenseGenerator(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );
      final licenseData = LicenseEncoder.encodeToBytes(license);

      // Save license to storage
      await storage.saveLicenseData(licenseData);

      // Act
      final result = await sut.getCurrentLicense();

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(license.id));
      expect(result.appId, equals(license.appId));
      expect(result.type, equals(license.type));
    });

    test('returns null for corrupted data', () async {
      // Arrange - first save a valid license
      final license = licenseGenerator(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );
      // Encode to bytes first
      final validBytes = LicenseEncoder.encodeToBytes(license);
      await storage.saveLicenseData(validBytes);

      // Then corrupt the data
      await storage.saveLicenseData(
        Uint8List.fromList('invalid json'.codeUnits),
      );

      // Act
      expect(
        () => sut.getCurrentLicense(),
        throwsA(isA<LicenseFormatException>()),
      );
    });

    test('successfully saves license', () async {
      // Arrange
      final license = licenseGenerator(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Act
      final result = await sut.saveLicense(license);

      // Assert
      expect(result, isTrue);

      // Additionally verify the license was actually saved
      final savedLicense = await sut.getCurrentLicense();
      expect(savedLicense, isNotNull);
      expect(savedLicense!.id, equals(license.id));
    });

    test('successfully removes existing license', () async {
      // Arrange - save a license to be removed
      final license = licenseGenerator(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );
      await sut.saveLicense(license);

      // Act
      final result = await sut.removeLicense();

      // Assert
      expect(result, isTrue);

      // Additionally verify the license was actually removed
      final savedLicense = await sut.getCurrentLicense();
      expect(savedLicense, isNull);
    });
  });
}
