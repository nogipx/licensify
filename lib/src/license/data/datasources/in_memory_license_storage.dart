// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:licensify/licensify.dart';

/// Реализация хранилища лицензий в памяти (для тестирования или специфических сценариев)
class InMemoryLicenseStorage implements ILicenseStorage {
  /// Данные лицензии, хранимые в памяти
  Uint8List? _licenseData;

  /// Создаёт пустое хранилище в памяти
  InMemoryLicenseStorage();

  /// Создаёт хранилище с предварительно загруженными данными
  InMemoryLicenseStorage.withData(this._licenseData);

  @override
  Future<bool> saveLicenseData(Uint8List data) async {
    try {
      _licenseData = data;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uint8List?> loadLicenseData() async {
    return _licenseData;
  }

  @override
  Future<bool> hasLicense() async {
    return _licenseData != null;
  }

  @override
  Future<bool> deleteLicenseData() async {
    try {
      _licenseData = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Очищает данные хранилища
  void clear() {
    _licenseData = null;
  }

  /// Возвращает текущий размер данных лицензии в байтах или 0, если лицензия отсутствует
  int get dataSize => _licenseData?.length ?? 0;
}
