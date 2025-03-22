// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Сценарий использования для проверки лицензии
class CheckLicenseUseCase {
  final ILicenseRepository _repository;
  final ILicenseValidator _validator;

  /// Конструктор
  const CheckLicenseUseCase({
    required ILicenseRepository repository,
    required ILicenseValidator validator,
  }) : _repository = repository,
       _validator = validator;

  /// Проверяет текущую лицензию
  Future<LicenseStatus> checkCurrentLicense() async {
    try {
      final license = await _repository.getCurrentLicense();

      if (license == null) {
        return const NoLicenseStatus();
      }

      if (!_validator.validateSignature(license)) {
        return const InvalidLicenseStatus(message: 'Недействительная подпись лицензии');
      }

      if (!_validator.validateExpiration(license)) {
        return ExpiredLicenseStatus(license);
      }

      return ActiveLicenseStatus(license);
    } catch (e) {
      return ErrorLicenseStatus(message: 'Ошибка при проверке лицензии', exception: e);
    }
  }

  /// Проверяет лицензию из бинарных данных
  Future<LicenseStatus> checkLicenseFromBytes(Uint8List licenseData) async {
    try {
      final result = await _repository.saveLicenseFromBytes(licenseData);

      if (!result) {
        return const ErrorLicenseStatus(message: 'Не удалось сохранить лицензию');
      }

      return checkCurrentLicense();
    } catch (e) {
      return ErrorLicenseStatus(
        message: 'Ошибка при проверке лицензии из бинарных данных',
        exception: e,
      );
    }
  }

  /// Проверяет лицензию из файла
  Future<LicenseStatus> checkLicenseFromFile(String filePath) async {
    try {
      final result = await _repository.saveLicenseFromFile(filePath);

      if (!result) {
        return const ErrorLicenseStatus(message: 'Не удалось сохранить лицензию из файла');
      }

      return checkCurrentLicense();
    } catch (e) {
      return ErrorLicenseStatus(message: 'Ошибка при проверке лицензии из файла', exception: e);
    }
  }

  /// Удаляет текущую лицензию
  Future<bool> removeLicense() => _repository.removeLicense();
}
