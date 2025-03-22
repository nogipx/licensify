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

      // Декодируем JSON
      final jsonString = utf8.decode(licenseData);
      final Map<String, dynamic> licenseJson = jsonDecode(jsonString);

      // Создаем модель данных и преобразуем в доменную сущность
      final licenseModel = LicenseModel.fromJson(licenseJson);
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

      // Сериализуем в JSON
      final jsonData = licenseModel.toJson();
      final jsonString = jsonEncode(jsonData);

      // Сохраняем данные
      final data = utf8.encode(jsonString);
      return await _storage.saveLicenseData(data);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> saveLicenseFromBytes(Uint8List licenseData) async {
    try {
      // Сохраняем бинарные данные напрямую
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
