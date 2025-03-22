// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

/// Utilities for working with the binary license file format
class LicenseFileFormat {
  /// Magic sequence for identifying license files
  static const String magicHeader = 'LCSF';

  /// Current file format version
  static const int formatVersion = 1;

  /// Converts license data to binary file format
  ///
  /// File structure:
  /// - [0-3] Magic sequence 'LCSF'
  /// - [4-7] Format version (uint32)
  /// - [8+]  Serialized JSON with license data
  static Uint8List encodeToBytes(Map<String, dynamic> licenseData) {
    // Serialize license data to JSON
    final jsonData = utf8.encode(jsonEncode(licenseData));

    // Create buffer for binary data
    final result = BytesBuilder();

    // Add magic sequence
    result.add(utf8.encode(magicHeader));

    // Add format version (4 bytes, little-endian)
    final versionBytes = Uint8List(4);
    final versionData = ByteData.view(versionBytes.buffer);
    versionData.setUint32(0, formatVersion, Endian.little);
    result.add(versionBytes);

    // Add license data
    result.add(jsonData);

    return result.toBytes();
  }

  /// Decodes binary license file data and verifies the format
  ///
  /// Returns null if the file format is invalid
  static Map<String, dynamic>? decodeFromBytes(Uint8List bytes) {
    try {
      // Check minimum file length (8 bytes for header)
      if (bytes.length < 8) {
        return null;
      }

      // Check magic sequence
      final headerBytes = bytes.sublist(0, 4);
      final header = utf8.decode(headerBytes);
      if (header != magicHeader) {
        return null;
      }

      // Get format version
      final versionData = ByteData.view(
        bytes.buffer,
        bytes.offsetInBytes + 4,
        4,
      );
      final version = versionData.getUint32(0, Endian.little);

      // Check version (currently we only support version 1)
      if (version != formatVersion) {
        return null;
      }

      // Extract JSON data
      final jsonBytes = bytes.sublist(8);
      final jsonString = utf8.decode(jsonBytes);

      // Parse JSON
      return jsonDecode(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Checks if the file has a valid license format
  static bool isValidLicenseFile(Uint8List bytes) {
    if (bytes.length < 8) {
      return false;
    }

    // Check magic sequence
    final headerBytes = bytes.sublist(0, 4);
    final header = utf8.decode(headerBytes);
    return header == magicHeader;
  }
}
