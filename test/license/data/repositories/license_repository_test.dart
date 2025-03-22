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
    late GenerateLicenseUseCase licenseGenerator;

    setUp(() {
      storage = InMemoryLicenseStorage();
      sut = LicenseRepository(storage: storage);
      licenseGenerator = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      );
    });

    test('возвращает_null_если_лицензия_отсутствует', () async {
      // Arrange - хранилище пустое по умолчанию

      // Act
      final result = await sut.getCurrentLicense();

      // Assert
      expect(result, isNull);
    });

    test('загружает_валидную_лицензию_из_хранилища', () async {
      // Arrange
      final license = licenseGenerator.generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );
      final licenseData = license.bytes;

      // Сохраняем лицензию в хранилище
      await storage.saveLicenseData(licenseData);

      // Act
      final result = await sut.getCurrentLicense();

      // Assert
      expect(result, isNotNull);
      expect(result!.id, equals(license.id));
      expect(result.appId, equals(license.appId));
      expect(result.type, equals(license.type));
    });

    test('возвращает_null_при_повреждении_данных', () async {
      // Arrange - сохраняем невалидные данные
      await storage.saveLicenseData(
        licenseGenerator
            .generateLicense(
              appId: TestConstants.testAppId,
              expirationDate: DateTime.now().add(Duration(days: 30)),
            )
            .bytes,
      );
      // Портим данные
      await storage.saveLicenseData(
        Uint8List.fromList('invalid json'.codeUnits),
      );

      // Act
      final result = await sut.getCurrentLicense();

      // Assert
      expect(result, isNull);
    });

    test('успешно_сохраняет_лицензию', () async {
      // Arrange
      final license = licenseGenerator.generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );

      // Act
      final result = await sut.saveLicense(license);

      // Assert
      expect(result, isTrue);

      // Дополнительно проверяем, что лицензия действительно сохранена
      final savedLicense = await sut.getCurrentLicense();
      expect(savedLicense, isNotNull);
      expect(savedLicense!.id, equals(license.id));
    });

    test('сохраняет_лицензию_из_массива_байтов', () async {
      // Arrange
      final license = licenseGenerator.generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );
      final licenseData = license.bytes;

      // Act
      final result = await sut.saveLicenseFromBytes(licenseData);

      // Assert
      expect(result, isTrue);

      // Дополнительно проверяем, что лицензия действительно сохранена
      final savedLicense = await sut.getCurrentLicense();
      expect(savedLicense, isNotNull);
      expect(savedLicense!.id, equals(license.id));
    });

    test('успешно_удаляет_существующую_лицензию', () async {
      // Arrange - сохраняем лицензию, чтобы было что удалять
      final license = licenseGenerator.generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );
      await sut.saveLicense(license);

      // Act
      final result = await sut.removeLicense();

      // Assert
      expect(result, isTrue);

      // Дополнительно проверяем, что лицензия действительно удалена
      final savedLicense = await sut.getCurrentLicense();
      expect(savedLicense, isNull);
    });
  });
}
