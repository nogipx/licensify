// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

import '../../helpers/test_constants.dart';

void main() {
  group('LicenseEncoder', () {
    test('encodeToBytes adds header and version', () {
      // Arrange
      final license = LicenseGenerateUseCase(
        privateKey: TestConstants.testKeyPair.privateKey,
      ).generateLicense(
        appId: 'com.test.app',
        type: LicenseType.standard,
        expirationDate: DateTime.now().add(const Duration(days: 365)),
      );

      // Act
      final result = LicenseEncoder.encodeToBytes(license);

      // Assert
      expect(result.length, greaterThan(8)); // Minimum length: header + version
      expect(utf8.decode(result.sublist(0, 4)), equals('LCSF')); // Check header

      // Check version
      final versionData = ByteData.view(
        result.buffer,
        result.offsetInBytes + 4,
        4,
      );
      final version = versionData.getUint32(0, Endian.little);
      expect(version, equals(LicenseEncoder.formatVersion));
    });

    test('decodeFromBytes returns correct data', () {
      // Arrange
      final originalLicense = License(
        id: '12345',
        appId: 'com.test.app',
        expirationDate: DateTime.now(),
        createdAt: DateTime.now(),
        signature: 'test-signature',
        type: LicenseType.pro,
        features: {'maxUsers': 10},
      );

      final encodedData = LicenseEncoder.encodeToBytes(originalLicense);

      // Act
      final decodedLicense = LicenseEncoder.decodeFromBytes(encodedData);

      // Assert
      expect(decodedLicense, isNotNull);
      expect(decodedLicense!.id, equals(originalLicense.id));
      expect(decodedLicense.appId, equals(originalLicense.appId));
      expect(decodedLicense.signature, equals(originalLicense.signature));
      expect(decodedLicense.type.name, equals(originalLicense.type.name));
      expect(
        decodedLicense.features['maxUsers'],
        equals(originalLicense.features['maxUsers']),
      );
    });

    test('decodeFromBytes returns null with invalid header', () {
      // Create a license and encode it
      final license = License(
        id: '12345',
        appId: 'test.app',
        expirationDate: DateTime.now(),
        createdAt: DateTime.now(),
        signature: 'test-signature',
      );
      final validBytes = LicenseEncoder.encodeToBytes(license);

      // Create corrupted data with invalid header
      final invalidData = Uint8List.fromList([
        // Incorrect magic header
        'X'.codeUnitAt(0),
        'X'.codeUnitAt(0),
        'X'.codeUnitAt(0),
        'X'.codeUnitAt(0),
        // Rest of the data from valid encoding (version and json)
        ...validBytes.sublist(4),
      ]);

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(invalidData);

      // Assert
      expect(decodedData, isNull);
    });

    test('decodeFromBytes returns null with invalid version', () {
      // Create a license and encode it
      final license = License(
        id: '12345',
        appId: 'test.app',
        expirationDate: DateTime.now(),
        createdAt: DateTime.now(),
        signature: 'test-signature',
      );
      final validBytes = LicenseEncoder.encodeToBytes(license);

      // Create corrupted data with invalid version
      final invalidData = Uint8List.fromList([
        // Keep correct magic header
        ...validBytes.sublist(0, 4),
        // Wrong version (999 in little endian)
        231, 3, 0, 0,
        // Rest of the data from valid encoding (json)
        ...validBytes.sublist(8),
      ]);

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(invalidData);

      // Assert
      expect(decodedData, isNull);
    });

    test('decodeFromBytes returns null with invalid size', () {
      // Arrange: create data with insufficient length
      final tooShortData = Uint8List(4);

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(tooShortData);

      // Assert
      expect(decodedData, isNull);
    });

    test('decodeFromBytes returns null with invalid JSON', () {
      // Create a license and encode it to get valid header and version
      final license = License(
        id: '12345',
        appId: 'test.app',
        expirationDate: DateTime.now(),
        createdAt: DateTime.now(),
        signature: 'test-signature',
      );
      final validBytes = LicenseEncoder.encodeToBytes(license);

      // Create corrupted data with invalid JSON
      final invalidJson = utf8.encode('{ this is not valid json');
      final invalidData = Uint8List.fromList([
        // Keep correct header and version
        ...validBytes.sublist(0, 8),
        // Invalid JSON data
        ...invalidJson,
      ]);

      // Assert
      expect(
        () => LicenseEncoder.decodeFromBytes(invalidData),
        throwsA(isA<FormatException>()),
      );
    });

    test('isValidLicenseFile returns true for valid data', () {
      // Arrange
      final license = License(
        id: '12345',
        appId: 'test.app',
        expirationDate: DateTime.now(),
        createdAt: DateTime.now(),
        signature: 'test-signature',
      );
      final encodedData = LicenseEncoder.encodeToBytes(license);

      // Act
      final isValid = LicenseEncoder.isValidLicenseBytes(encodedData);

      // Assert
      expect(isValid, isTrue);
    });

    test('isValidLicenseFile returns false for invalid data', () {
      // Arrange: case 1 - too short data
      final tooShortData = Uint8List(4);

      // Arrange: case 2 - invalid header
      final license = License(
        id: '12345',
        appId: 'test.app',
        expirationDate: DateTime.now(),
        createdAt: DateTime.now(),
        signature: 'test-signature',
      );
      final validBytes = LicenseEncoder.encodeToBytes(license);

      // Create data with invalid header
      final invalidHeaderData = Uint8List.fromList([
        // Incorrect magic header
        'X'.codeUnitAt(0),
        'X'.codeUnitAt(0),
        'X'.codeUnitAt(0),
        'X'.codeUnitAt(0),
        // Rest of the data from valid encoding
        ...validBytes.sublist(4),
      ]);

      // Act
      final isValidShort = LicenseEncoder.isValidLicenseBytes(tooShortData);
      final isValidWrongHeader = LicenseEncoder.isValidLicenseBytes(
        invalidHeaderData,
      );

      // Assert
      expect(isValidShort, isFalse);
      expect(isValidWrongHeader, isFalse);
    });
  });
}
