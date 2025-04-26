// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Interface for decrypt data use case
abstract class IDecryptDataUseCase {
  /// Decrypt data that may have a magic header
  Uint8List call({
    required Uint8List encryptedData,
    String? expectedMagicHeader,
  });

  /// Decrypt to string data that may have a magic header
  String decryptToString({
    required Uint8List encryptedData,
    String? expectedMagicHeader,
  });
}

/// Decrypt data use case
///
/// A use case that decrypts arbitrary data that may have a magic header
/// to identify the type of data (like a MIME type).
class DecryptDataUseCase implements IDecryptDataUseCase {
  /// Private key for decryption
  final LicensifyPrivateKey _privateKey;

  /// Type of encryption key
  final LicensifyKeyType _keyType;

  /// AES key size in bits
  final int _aesKeySize;

  /// Digest algorithm for HKDF
  final Digest _hkdfDigest;

  /// Salt for HKDF key derivation
  final String _hkdfSalt;

  /// Info string for HKDF key derivation
  final String _hkdfInfo;

  /// Creates a new decrypt data use case
  ///
  /// [privateKey] - Private key in PEM format for decryption
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  DecryptDataUseCase({
    required LicensifyPrivateKey privateKey,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) : _privateKey = privateKey,
       _keyType = privateKey.keyType,
       _aesKeySize = aesKeySize,
       _hkdfDigest = hkdfDigest ?? SHA256Digest(),
       _hkdfSalt = hkdfSalt ?? 'LICENSIFY-ECDH-Salt',
       _hkdfInfo = hkdfInfo ?? 'LICENSIFY-ECDH-AES';

  /// Decrypt data that may have a magic header
  ///
  /// [encryptedData] - Encrypted data bytes
  /// [expectedMagicHeader] - Optional expected magic header for validation
  ///
  /// Returns decrypted data as bytes
  @override
  Uint8List call({
    required Uint8List encryptedData,
    String? expectedMagicHeader,
  }) {
    if (_keyType == LicensifyKeyType.rsa) {
      throw UnsupportedError('RSA is deprecated');
    }

    // Try to parse the format info (header)
    final formatInfo = _tryParseFormatInfo(encryptedData);

    // Validate magic header if expected
    if (expectedMagicHeader != null &&
        formatInfo.hasHeader &&
        formatInfo.magicHeader != expectedMagicHeader) {
      throw FormatException(
        'Invalid data format: expected header "$expectedMagicHeader" '
        'but found "${formatInfo.magicHeader}"',
      );
    }

    // Validate key type
    if (formatInfo.hasHeader && formatInfo.keyType != _keyType) {
      throw FormatException(
        'Key type mismatch: data is for ${formatInfo.keyType.name}, '
        'but decrypter uses ${_keyType.name}',
      );
    }

    // Decrypt the payload
    return ECCipher.decryptWithLicensifyKey(
      encryptedData: formatInfo.encryptedPayload,
      privateKey: _privateKey,
      aesKeySize: _aesKeySize,
      hkdfDigest: _hkdfDigest,
      hkdfSalt: _hkdfSalt,
      hkdfInfo: _hkdfInfo,
    );
  }

  /// Decrypt to string data that may have a magic header
  ///
  /// [encryptedData] - Encrypted data bytes
  /// [expectedMagicHeader] - Optional expected magic header for validation
  ///
  /// Returns decrypted data as string
  @override
  String decryptToString({
    required Uint8List encryptedData,
    String? expectedMagicHeader,
  }) {
    final decryptedBytes = call(
      encryptedData: encryptedData,
      expectedMagicHeader: expectedMagicHeader,
    );
    return utf8.decode(decryptedBytes);
  }

  /// Tries to parse format information from encrypted data
  ///
  /// If the data has a valid header format, extracts the magic header,
  /// format version, and key type.
  /// If not, assumes the data is raw encrypted payload.
  ///
  /// [data] - The data to parse
  ///
  /// Returns format information and the actual encrypted payload
  _DataFormatInfo _tryParseFormatInfo(Uint8List data) {
    // Check if the data is long enough to potentially contain a header
    if (data.length < 9) {
      // Too short for header, assume it's just encrypted data
      return _DataFormatInfo(
        formatVersion: 1,
        keyType: _keyType,
        hasHeader: false,
        encryptedPayload: data,
      );
    }

    try {
      // Try to extract magic header
      final header = utf8.decode(data.sublist(0, 4));

      // Extract format version
      final versionData = ByteData.view(data.sublist(4, 8).buffer);
      final version = versionData.getUint32(0, Endian.little);

      // Extract key type
      final keyType =
          data[8] == 0 ? LicensifyKeyType.rsa : LicensifyKeyType.ecdsa;

      // The rest is the encrypted payload
      final encryptedPayload = data.sublist(9);

      return _DataFormatInfo(
        magicHeader: header,
        formatVersion: version,
        keyType: keyType,
        hasHeader: true,
        encryptedPayload: encryptedPayload,
      );
    } catch (_) {
      // If anything fails (e.g., can't decode UTF-8), assume it's raw data
      return _DataFormatInfo(
        formatVersion: 1,
        keyType: _keyType,
        hasHeader: false,
        encryptedPayload: data,
      );
    }
  }
}

/// Data format information extracted from encrypted data
class _DataFormatInfo {
  /// Magic header from the data (if present)
  final String? magicHeader;

  /// Format version from the data
  final int formatVersion;

  /// Key type used for encryption
  final LicensifyKeyType keyType;

  /// Whether the data contains a header
  final bool hasHeader;

  /// The actual encrypted payload (without headers)
  final Uint8List encryptedPayload;

  /// Constructor for data format information
  _DataFormatInfo({
    this.magicHeader,
    required this.formatVersion,
    required this.keyType,
    required this.hasHeader,
    required this.encryptedPayload,
  });
}
