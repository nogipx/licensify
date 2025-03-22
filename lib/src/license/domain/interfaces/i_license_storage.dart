// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

/// Storage interface for license data persistence
///
/// This interface abstracts the physical storage of license data,
/// allowing for different storage mechanisms (file, memory, etc.)
abstract interface class ILicenseStorage {
  /// Saves license data to storage
  ///
  /// [data] - Binary license data to be stored
  ///
  /// Returns true if data was successfully saved, false otherwise
  Future<bool> saveLicenseData(Uint8List data);

  /// Loads license data from storage
  ///
  /// Returns the binary license data or null if no license exists
  Future<Uint8List?> loadLicenseData();

  /// Checks if a license exists in storage
  ///
  /// Returns true if a license is present, false otherwise
  Future<bool> hasLicense();

  /// Deletes license data from storage
  ///
  /// Returns true if data was successfully deleted, false otherwise
  Future<bool> deleteLicenseData();
}
