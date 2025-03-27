// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Implementation of the license repository
class LicenseRepository implements ILicenseRepository {
  final ILicenseStorage _storage;

  const LicenseRepository({required ILicenseStorage storage})
    : _storage = storage;

  @override
  Future<License?> getCurrentLicense() async {
    try {
      if (!await _storage.hasLicense()) {
        return null;
      }

      final licenseData = await _storage.loadLicenseData();
      if (licenseData == null) {
        return null;
      }

      return getLicenseFromBytes(licenseData);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveLicense(License license) async {
    final binaryData = LicenseEncoder.encodeToBytes(license);
    return await _storage.saveLicenseData(binaryData);
  }

  @override
  Future<License> getLicenseFromBytes(Uint8List licenseData) async {
    final license = LicenseEncoder.decodeFromBytes(licenseData);
    return license;
  }

  @override
  Future<bool> removeLicense() async {
    return await _storage.deleteLicenseData();
  }
}
