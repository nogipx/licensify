// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

// This file is a stub implementation for non-web platforms
// It should not be imported directly, but through conditional imports

import 'dart:typed_data';
import 'package:licensify/licensify.dart';

/// Stub implementation of web storage for non-web platforms
///
/// This class provides a compatibility layer to maintain the same API
/// between web and native platforms. On native platforms, this
/// implementation throws UnsupportedError for all operations.
class WebLicenseStorage implements ILicenseStorage {
  /// Creates a stub instance of WebLicenseStorage
  ///
  /// Parameters:
  /// - [storageKey]: Not used in the stub implementation
  /// - [jsInterop]: Not used in the stub implementation
  const WebLicenseStorage({required String storageKey, dynamic jsInterop});

  /// Platform-specific error message
  String get _errorMessage => 'Web storage is not supported on this platform';

  @override
  Future<bool> deleteLicenseData() async {
    throw UnsupportedError(_errorMessage);
  }

  @override
  Future<bool> hasLicense() async {
    throw UnsupportedError(_errorMessage);
  }

  @override
  Future<Uint8List?> loadLicenseData() async {
    throw UnsupportedError(_errorMessage);
  }

  @override
  Future<bool> saveLicenseData(Uint8List data) async {
    throw UnsupportedError(_errorMessage);
  }
}

/// Stub factory for web storage on non-web platforms
///
/// This class maintains API compatibility with the web implementation
/// but throws errors when used on non-web platforms.
class WebStorageFactory {
  /// Creates a stub instance of web storage
  ///
  /// Parameters:
  /// - [storageKey]: Not used in the stub implementation
  ///
  /// Throws UnsupportedError when called on non-web platforms
  static WebLicenseStorage createStorage({required String storageKey}) {
    return WebLicenseStorage(storageKey: storageKey);
  }
}
