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
    test('создает_валидную_лицензию_с_заданными_параметрами', () {
      // Arrange
      final sut = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      );
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();
      final features = {'maxUsers': 10, 'canExport': true};

      // Act
      final license = sut.generateLicense(
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

    test('создает_действительную_подпись_RSA', () {
      // Arrange
      final sut = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      );
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();

      // Act
      final license = sut.generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: expirationDate,
      );

      // Verify the signature using the validator
      final validator = LicenseValidator(
        publicKey: TestConstants.testPublicKey,
      );
      final isValid = validator.validateSignature(license);

      // Assert
      expect(isValid, isTrue);
    });

    test('подпись_валидна_только_для_правильной_пары_ключей', () {
      // Arrange
      final sut = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      );
      final expirationDate =
          DateTime.now()
              .add(Duration(days: TestConstants.defaultLicenseDuration))
              .toUtc()
              .roundToMinutes();

      // Генерируем новую пару ключей
      final differentKeys = RsaKeyGenerator.generateKeyPairAsPem(
        bitLength: 2048,
      );

      // Act
      final license = sut.generateLicense(
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
        publicKey: TestConstants.testPublicKey,
      );
      final isValidWithCorrectKey = correctValidator.validateSignature(license);

      // Assert
      expect(
        isValidWithWrongKey,
        isFalse,
        reason:
            'Подпись не должна быть валидна с неправильным публичным ключом',
      );
      expect(
        isValidWithCorrectKey,
        isTrue,
        reason: 'Подпись должна быть валидна с правильным публичным ключом',
      );
    });

    test('по_умолчанию_создает_пробную_лицензию', () {
      // Arrange
      final sut = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      );

      // Act
      final license = sut.generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(
          Duration(days: TestConstants.defaultLicenseDuration),
        ),
      );

      // Assert
      expect(license.type, equals(LicenseType.trial));
    });

    test('сериализует_лицензию_в_бинарный_формат_с_заголовком', () {
      // Arrange
      final sut = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      );
      final license = sut.generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(
          Duration(days: TestConstants.defaultLicenseDuration),
        ),
        type: LicenseType.standard,
        features: {'maxUsers': 5},
      );

      // Act
      final bytes = license.bytes;

      // Assert
      // Проверяем магический заголовок
      expect(
        utf8.decode(bytes.sublist(0, 4)),
        equals(LicenseEncoder.magicHeader),
      );

      // Проверяем версию формата
      final versionData = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes + 4,
        4,
      );
      final version = versionData.getUint32(0, Endian.little);
      expect(version, equals(LicenseEncoder.formatVersion));

      // Декодируем данные лицензии
      final jsonData = LicenseEncoder.decodeFromBytes(bytes);
      expect(jsonData, isNotNull);
      expect(jsonData!['id'], equals(license.id));
      expect(jsonData['appId'], equals(license.appId));
      expect(jsonData['signature'], equals(license.signature));
      expect(jsonData['type'], equals(license.type.name));
      expect(jsonData['features']['maxUsers'], equals(5));
    });
  });
}
