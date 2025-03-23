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
    // Преобразуем доменную сущность в модель данных
    final licenseModel = LicenseModel.fromDomain(license);

    // Сериализуем в JSON и кодируем в бинарный формат
    final jsonData = licenseModel.toJson();
    final binaryData = LicenseEncoder.encodeToBytes(jsonData);

    // Сохраняем данные
    return await _storage.saveLicenseData(binaryData);
  }

  @override
  Future<License?> getLicenseFromBytes(Uint8List licenseData) async {
    final licenseJson = LicenseEncoder.decodeFromBytes(licenseData);
    if (licenseJson == null) {
      return null;
    }

    return _createLicenseFromJson(licenseJson);
  }

  @override
  Future<bool> removeLicense() async {
    return await _storage.deleteLicenseData();
  }

  /// Создает объект лицензии из JSON-данных
  License _createLicenseFromJson(Map<String, dynamic> json) {
    final licenseModel = LicenseModel.fromJson(json);
    return licenseModel.toDomain();
  }
}
