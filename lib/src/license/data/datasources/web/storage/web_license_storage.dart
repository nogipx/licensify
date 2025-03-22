// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import '../interop/js_interop.dart' as wasm_interop;

/// Web-based implementation of license storage using browser localStorage
///
/// This implementation uses browser's localStorage API to store and retrieve license data.
/// It's designed specifically for web platforms where file system access is limited.
class WebLicenseStorage implements ILicenseStorage {
  /// Key used to store license data in localStorage
  final String _storageKey;

  /// JS interop implementation
  final wasm_interop.JsInterop? _jsInterop;

  /// Constructor
  const WebLicenseStorage({
    required String storageKey,
    wasm_interop.JsInterop? jsInterop,
  }) : _storageKey = storageKey,
       _jsInterop = jsInterop;

  /// Helper method to perform localStorage access with proper error handling
  Future<T> _performStorageOperation<T>(
    FutureOr<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (e) {
      // Re-throw with more context for debugging
      throw Exception('WebLicenseStorage operation failed: ${e.toString()}');
    }
  }

  /// Check if web storage is available
  Future<bool> _isStorageAvailable() async {
    return _performStorageOperation(() async {
      try {
        // Simple feature test for localStorage
        return _localStorage != null;
      } catch (e) {
        return false;
      }
    });
  }

  /// Get localStorage object
  dynamic get _localStorage {
    try {
      // Check if JS interop is provided
      if (_jsInterop == null) {
        return null;
      }

      // Access localStorage through the provided interop
      final window = _jsInterop.window;
      return window?.localStorage;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveLicenseData(Uint8List data) async {
    return _performStorageOperation(() async {
      if (!await _isStorageAvailable()) {
        return false;
      }

      try {
        // Convert binary data to base64 string for storage
        final base64Data = base64Encode(data);

        // Store in localStorage
        final localStorage = _localStorage;
        localStorage.setItem(_storageKey, base64Data);
        return true;
      } catch (e) {
        return false;
      }
    });
  }

  @override
  Future<Uint8List?> loadLicenseData() async {
    return _performStorageOperation(() async {
      if (!await _isStorageAvailable()) {
        return null;
      }

      try {
        // Get from localStorage
        final localStorage = _localStorage;
        final base64Data = localStorage.getItem(_storageKey);

        if (base64Data == null || base64Data.isEmpty) {
          return null;
        }

        // Convert from base64 back to binary
        return Uint8List.fromList(base64Decode(base64Data));
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<bool> hasLicense() async {
    return _performStorageOperation(() async {
      if (!await _isStorageAvailable()) {
        return false;
      }

      try {
        // Check if key exists in localStorage
        final localStorage = _localStorage;
        final data = localStorage.getItem(_storageKey);
        return data != null && data.isNotEmpty;
      } catch (e) {
        return false;
      }
    });
  }

  @override
  Future<bool> deleteLicenseData() async {
    return _performStorageOperation(() async {
      if (!await _isStorageAvailable()) {
        return false;
      }

      try {
        // Remove from localStorage
        final localStorage = _localStorage;
        localStorage.removeItem(_storageKey);
        return true;
      } catch (e) {
        return false;
      }
    });
  }
}
