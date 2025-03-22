// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

/// Интерфейс для хранилища лицензий
abstract class ILicenseStorage {
  /// Сохраняет данные лицензии
  Future<bool> saveLicenseData(Uint8List data);

  /// Загружает данные лицензии
  Future<Uint8List?> loadLicenseData();

  /// Проверяет наличие лицензии
  Future<bool> hasLicense();

  /// Удаляет данные лицензии
  Future<bool> deleteLicenseData();
}
