// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Repository interface for license operations
///
/// This interface defines methods for license storage, retrieval, and management.
/// Implementations handle the persistence and loading of license data.
abstract interface class ILicenseRepository {
  /// Retrieves the currently installed license
  ///
  /// Returns the active license or null if no license is installed
  Future<License?> getCurrentLicense();

  /// Saves a license to storage
  ///
  /// [license] - The license object to save
  ///
  /// Returns true if the operation was successful, false otherwise
  Future<bool> saveLicense(License license);

  /// Saves a license from raw binary data
  ///
  /// [licenseData] - The raw license file data as bytes
  ///
  /// Returns true if the operation was successful, false otherwise
  Future<bool> saveLicenseFromBytes(Uint8List licenseData);

  /// Removes the current license from storage
  ///
  /// Returns true if the operation was successful, false otherwise
  Future<bool> removeLicense();
}
