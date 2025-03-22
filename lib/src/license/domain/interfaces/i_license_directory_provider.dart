// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Интерфейс для доступа к директории приложения
abstract class ILicenseDirectoryProvider {
  /// Возвращает путь к директории приложения
  Future<String> getLicenseDirectoryPath();
}
