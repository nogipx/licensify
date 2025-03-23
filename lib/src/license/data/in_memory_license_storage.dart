// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:licensify/licensify.dart';

/// In-memory implementation of license storage (for testing or specific scenarios)
class InMemoryLicenseStorage implements ILicenseStorage {
  /// License data stored in memory
  Uint8List? _licenseData;

  /// Creates an empty in-memory storage
  InMemoryLicenseStorage();

  /// Creates storage with pre-loaded data
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

  /// Clears storage data
  void clear() {
    _licenseData = null;
  }

  /// Returns the current size of license data in bytes or 0 if license is absent
  int get dataSize => _licenseData?.length ?? 0;
}
