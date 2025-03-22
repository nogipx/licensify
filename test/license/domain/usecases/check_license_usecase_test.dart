// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';

import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('CheckLicenseUseCase', () {
    late InMemoryLicenseStorage storage;
    late LicenseRepository repository;
    late LicenseValidator validator;
    late CheckLicenseUseCase sut;

    setUp(() {
      storage = InMemoryLicenseStorage();
      repository = LicenseRepository(storage: storage);
      validator = LicenseValidator(publicKey: TestConstants.testPublicKey);
      sut = CheckLicenseUseCase(repository: repository, validator: validator);
    });

    test('сообщает_что_лицензия_отсутствует', () async {
      // Arrange - хранилище пустое

      // Act
      final result = await sut.checkCurrentLicense();

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
      await repository.saveLicense(license);

      // Act
      final result = await sut.checkCurrentLicense();

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
      await repository.saveLicense(expiredLicense);

      // Act
      final result = await sut.checkCurrentLicense();

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
      await repository.saveLicense(validLicense);

      // Act
      final result = await sut.checkCurrentLicense();

      // Assert
      expect(result.isActive, isTrue);
      expect(
        (result as ActiveLicenseStatus).license.id,
        equals(validLicense.id),
      );
    });

    test('обрабатывает_ошибки_репозитория', () async {
      // Arrange - используем специальный репозиторий, который генерирует исключение
      final failingRepo = _FailingLicenseRepository();
      sut = CheckLicenseUseCase(repository: failingRepo, validator: validator);

      // Act
      final result = await sut.checkCurrentLicense();

      // Assert
      expect(result.isError, isTrue);
    });

    test('удаляет_лицензию_успешно', () async {
      // Arrange
      final validLicense = GenerateLicenseUseCase(
        privateKey: TestConstants.testPrivateKey,
      ).generateLicense(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
      );
      await repository.saveLicense(validLicense);

      // Act
      final result = await sut.removeLicense();

      // Assert
      expect(result, isTrue);

      // Проверяем что лицензия действительно удалена
      final status = await sut.checkCurrentLicense();
      expect(status.isNoLicense, isTrue);
    });
  });
}

/// Репозиторий, генерирующий исключение при проверке наличия лицензии
class _FailingLicenseRepository implements ILicenseRepository {
  @override
  Future<License?> getCurrentLicense() async {
    throw Exception('Repository error');
  }

  @override
  Future<bool> removeLicense() async {
    return true;
  }

  @override
  Future<bool> saveLicense(License license) async {
    return true;
  }

  @override
  Future<bool> saveLicenseFromBytes(Uint8List licenseData) async {
    return true;
  }
}
