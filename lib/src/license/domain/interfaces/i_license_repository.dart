// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Интерфейс репозитория для работы с лицензиями
abstract class ILicenseRepository {
  /// Получает текущую лицензию
  Future<License?> getCurrentLicense();

  /// Сохраняет лицензию
  Future<bool> saveLicense(License license);

  /// Сохраняет лицензию из бинарных данных
  Future<bool> saveLicenseFromBytes(Uint8List licenseData);

  /// Сохраняет лицензию из файла
  Future<bool> saveLicenseFromFile(String filePath);

  /// Удаляет текущую лицензию
  Future<bool> removeLicense();
}
