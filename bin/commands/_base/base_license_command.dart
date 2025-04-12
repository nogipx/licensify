// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:licensify/licensify.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import 'base_command.dart';

/// Base class for license operations
abstract class BaseLicenseCommand extends BaseCommand {
  /// Parses key=value format list into a Map
  Map<String, dynamic> parseKeyValues(List<String> items) {
    final result = <String, dynamic>{};
    for (final item in items) {
      final parts = item.split('=');
      if (parts.length != 2) {
        print(
          'Предупреждение: Некорректный формат для "$item". Ожидается key=value',
        );
        continue;
      }
      result[parts[0]] = parts[1];
    }
    return result;
  }

  /// Converts a string to a LicenseType
  LicenseType getLicenseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'pro':
        return LicenseType.pro;
      case 'standard':
        return LicenseType.standard;
      default:
        // Create a custom license type
        return LicenseType(typeStr.toLowerCase());
    }
  }

  /// Generates device hash from device ID or creates a random one
  String generateDeviceHash(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) {
      // Generate a random device hash if none provided
      final random = const Uuid().v4();
      final bytes = utf8.encode(random);
      final hash = sha256.convert(bytes);
      return hash.toString();
    } else {
      // Hash the provided device ID
      final bytes = utf8.encode(deviceId);
      final hash = sha256.convert(bytes);
      return hash.toString();
    }
  }

  /// Tries to encrypt the license bytes (placeholder for future implementation)
  Uint8List encryptLicense(Uint8List licenseBytes, String? encryptKey) {
    if (encryptKey != null) {
      print('Предупреждение: Шифрование не реализовано в текущей версии');
    }
    return licenseBytes;
  }

  /// Tries to decrypt the license bytes (placeholder for future implementation)
  Uint8List decryptLicense(Uint8List licenseBytes, String? decryptKey) {
    if (decryptKey != null) {
      print('Предупреждение: Дешифрование не реализовано в текущей версии');
    }
    return licenseBytes;
  }

  /// Gets configured file extension for license files
  String getLicenseFileExtension({String? customExtension}) {
    return customExtension ?? 'licensify';
  }

  /// Gets configured file extension for license request files
  String getRequestFileExtension({String? customExtension}) {
    return customExtension ?? 'bin';
  }
}
