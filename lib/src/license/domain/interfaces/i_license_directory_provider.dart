// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Interface for accessing the application's license storage directory
abstract interface class ILicenseDirectoryProvider {
  /// Returns the path to the directory where license files should be stored
  Future<String> getLicenseDirectoryPath();
}
