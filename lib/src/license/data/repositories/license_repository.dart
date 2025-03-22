// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Реализация репозитория лицензий
class LicenseRepository implements ILicenseRepository {
  final ILicenseStorage _storage;

  /// Конструктор
  const LicenseRepository({required ILicenseStorage storage}) : _storage = storage;

  @override
  Future<License?> getCurrentLicense() async {
    try {
      // Проверяем наличие лицензии
      if (!await _storage.hasLicense()) {
        return null;
      }

      // Загружаем данные лицензии
      final licenseData = await _storage.loadLicenseData();
      if (licenseData == null) {
        return null;
      }

      // Проверяем формат и декодируем данные
      final licenseJson = LicenseFileFormat.decodeFromBytes(licenseData);
      if (licenseJson == null) {
        // Пробуем старый формат (для обратной совместимости)
        try {
          final jsonString = utf8.decode(licenseData);
          final jsonData = jsonDecode(jsonString);
          return _createLicenseFromJson(jsonData);
        } catch (e) {
          // Не удалось распарсить ни новый, ни старый формат
          return null;
        }
      }

      // Создаем лицензию из декодированных данных
      return _createLicenseFromJson(licenseJson);
    } catch (e) {
      return null;
    }
  }

  /// Создает объект лицензии из JSON-данных
  License? _createLicenseFromJson(Map<String, dynamic> json) {
    try {
      final licenseModel = LicenseModel.fromJson(json);
      return licenseModel.toDomain();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveLicense(License license) async {
    try {
      // Преобразуем доменную сущность в модель данных
      final licenseModel = LicenseModel.fromDomain(license);

      // Сериализуем в JSON и кодируем в бинарный формат
      final jsonData = licenseModel.toJson();
      final binaryData = LicenseFileFormat.encodeToBytes(jsonData);

      // Сохраняем данные
      return await _storage.saveLicenseData(binaryData);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> saveLicenseFromBytes(Uint8List licenseData) async {
    try {
      // Проверяем, соответствует ли формат ожидаемому
      if (!LicenseFileFormat.isValidLicenseFile(licenseData)) {
        // Пробуем декодировать как JSON (для обратной совместимости)
        try {
          final jsonString = utf8.decode(licenseData);
          final jsonData = jsonDecode(jsonString);

          // Перекодируем в новый формат
          final encodedData = LicenseFileFormat.encodeToBytes(jsonData);
          return await _storage.saveLicenseData(encodedData);
        } catch (e) {
          // Не удалось распарсить как JSON, сохраняем как есть
          return await _storage.saveLicenseData(licenseData);
        }
      }

      // Формат правильный, сохраняем как есть
      return await _storage.saveLicenseData(licenseData);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> saveLicenseFromFile(String filePath) async {
    try {
      // Читаем файл
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Читаем данные и сохраняем
      final licenseData = await file.readAsBytes();
      return await saveLicenseFromBytes(licenseData);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeLicense() async {
    try {
      return await _storage.deleteLicenseData();
    } catch (e) {
      return false;
    }
  }
}
