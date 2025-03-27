// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Реализация репозитория лицензий
class LicenseRepository implements ILicenseRepository {
  final ILicenseStorage _storage;

  /// Конструктор
  const LicenseRepository({required ILicenseStorage storage})
    : _storage = storage;

  @override
  Future<License?> getCurrentLicense() async {
    // Проверяем наличие лицензии
    if (!await _storage.hasLicense()) {
      return null;
    }

    // Загружаем данные лицензии
    final licenseData = await _storage.loadLicenseData();
    if (licenseData == null) {
      return null;
    }

    return getLicenseFromBytes(licenseData);
  }

  @override
  Future<bool> saveLicense(License license) async {
    // Сериализуем в JSON и кодируем в бинарный формат
    final binaryData = LicenseEncoder.encodeToBytes(license);
    // Сохраняем данные
    return await _storage.saveLicenseData(binaryData);
  }

  @override
  Future<License?> getLicenseFromBytes(Uint8List licenseData) async {
    final license = LicenseEncoder.decodeFromBytes(licenseData);
    if (license == null) {
      return null;
    }
    return license;
  }

  @override
  Future<bool> removeLicense() async {
    return await _storage.deleteLicenseData();
  }
}
