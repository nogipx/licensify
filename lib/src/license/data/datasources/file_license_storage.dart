// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:io';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// File-based implementation of license storage
class FileLicenseStorage implements ILicenseStorage {
  final ILicenseDirectoryProvider _directoryProvider;
  final String _licenseFileName;

  /// Constructor
  const FileLicenseStorage({
    required ILicenseDirectoryProvider directoryProvider,
    required String licenseFileName,
  }) : _directoryProvider = directoryProvider,
       _licenseFileName = licenseFileName;

  /// Gets the license file path
  Future<String> _getLicenseFilePath() async {
    final licenseDirPath = await _directoryProvider.getLicenseDirectoryPath();
    return '$licenseDirPath/$_licenseFileName';
  }

  @override
  Future<bool> saveLicenseData(Uint8List data) async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);
      await file.writeAsBytes(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uint8List?> loadLicenseData() async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> hasLicense() async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteLicenseData() async {
    try {
      final filePath = await _getLicenseFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
