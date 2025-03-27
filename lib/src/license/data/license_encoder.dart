// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Utilities for working with the binary license file format
class LicenseEncoder {
  /// Magic sequence for identifying license files
  static const String magicHeader = 'LCSF';

  static const int formatVersion = 1;

  /// Converts license data to binary file format
  ///
  /// File structure:
  /// - [0-3] Magic sequence 'LCSF'
  /// - [4-7] Format version (uint32)
  /// - [8+]  Serialized JSON with license data
  static Uint8List encodeToBytes(License licenseData) {
    try {
      final licenseDto = LicenseMapper.toDto(licenseData);

      // Serialize license data to JSON
      final jsonData = utf8.encode(jsonEncode(licenseDto.toJson()));

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
    } on Object catch (e, trace) {
      throw LicenseFormatException('Failed to encode license: $e', trace);
    }
  }

  /// Decodes binary license file data and verifies the format
  /// Throws [LicenseFormatException] if the file format is invalid
  static License decodeFromBytes(Uint8List bytes) {
    try {
      // Check minimum file length (8 bytes for header)
      if (bytes.length < 8) {
        throw LicenseFormatException('Invalid license file format');
      }

      // Check magic sequence
      final headerBytes = bytes.sublist(0, 4);
      final header = utf8.decode(headerBytes);
      if (header != magicHeader) {
        throw LicenseFormatException('Invalid license file format');
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
        throw LicenseFormatException('Unsupported license file format version');
      }

      // Extract JSON data
      final jsonBytes = bytes.sublist(8);
      final jsonString = utf8.decode(jsonBytes);

      // Parse JSON
      final licenseDto = LicenseDto.fromJson(jsonDecode(jsonString));
      return licenseDto.toDomain();
    } on Object catch (e, trace) {
      throw LicenseFormatException('Failed to decode license: $e', trace);
    }
  }

  /// Checks if the file has a valid license format
  static bool isValidLicenseBytes(Uint8List bytes) {
    if (bytes.length < 8) {
      return false;
    }

    // Check magic sequence
    final headerBytes = bytes.sublist(0, 4);
    final header = utf8.decode(headerBytes);
    return header == magicHeader;
  }
}
