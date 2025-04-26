// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Interface for encrypt data use case
abstract class IEncryptDataUseCase {
  /// Encrypt data with optional magic header
  Uint8List call({
    required Uint8List data,
    String? magicHeader,
    int formatVersion = 1,
  });

  /// Encrypt string data with optional magic header
  Uint8List encryptString({
    required String data,
    String? magicHeader,
    int formatVersion = 1,
  });
}

/// Encrypt data use case
///
/// A use case that encrypts arbitrary data with an optional magic header
/// to identify the type of data (like a MIME type).
class EncryptDataUseCase implements IEncryptDataUseCase {
  /// Public key for encrypting data
  final LicensifyPublicKey _publicKey;

  /// Encryption key type
  final LicensifyKeyType _keyType;

  /// AES key size in bits
  final int _aesKeySize;

  /// Digest algorithm for HKDF
  final Digest _hkdfDigest;

  /// Salt for HKDF key derivation
  final String _hkdfSalt;

  /// Info string for HKDF key derivation
  final String _hkdfInfo;

  /// Creates a new encrypt data use case
  ///
  /// [publicKey] - Public key in PEM format for encrypting data
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  EncryptDataUseCase({
    required LicensifyPublicKey publicKey,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) : _publicKey = publicKey,
       _keyType = publicKey.keyType,
       _aesKeySize = aesKeySize,
       _hkdfDigest = hkdfDigest ?? SHA256Digest(),
       _hkdfSalt = hkdfSalt ?? 'LICENSIFY-ECDH-Salt',
       _hkdfInfo = hkdfInfo ?? 'LICENSIFY-ECDH-AES';

  /// Encrypt data with optional magic header
  ///
  /// [data] - Raw data to encrypt
  /// [magicHeader] - Optional magic header (4 bytes) to identify data type
  /// [formatVersion] - Format version (default: 1)
  ///
  /// Returns encrypted data with optional header as bytes
  @override
  Uint8List call({
    required Uint8List data,
    String? magicHeader,
    int formatVersion = 1,
  }) {
    if (_keyType == LicensifyKeyType.rsa) {
      throw UnsupportedError('RSA is deprecated');
    }

    // Encrypt the data
    final encryptedData = ECCipher.encryptWithLicensifyKey(
      data: data,
      publicKey: _publicKey,
      aesKeySize: _aesKeySize,
      hkdfDigest: _hkdfDigest,
      hkdfSalt: _hkdfSalt,
      hkdfInfo: _hkdfInfo,
    );

    // If no magic header, return just the encrypted data
    if (magicHeader == null) {
      return encryptedData;
    }

    // Format with magic header
    return _formatWithHeader(
      encryptedData: encryptedData,
      magicHeader: magicHeader,
      formatVersion: formatVersion,
    );
  }

  /// Encrypt string data with optional magic header
  ///
  /// [data] - String data to encrypt
  /// [magicHeader] - Optional magic header to identify data type
  /// [formatVersion] - Format version (default: 1)
  ///
  /// Returns encrypted data with optional header as bytes
  @override
  Uint8List encryptString({
    required String data,
    String? magicHeader,
    int formatVersion = 1,
  }) {
    return call(
      data: utf8.encode(data),
      magicHeader: magicHeader,
      formatVersion: formatVersion,
    );
  }

  /// Formats encrypted data with magic header
  ///
  /// [encryptedData] - Encrypted data bytes
  /// [magicHeader] - Magic header (4 bytes) to identify data type
  /// [formatVersion] - Format version (little-endian, 4 bytes)
  ///
  /// Returns formatted data with header
  Uint8List _formatWithHeader({
    required Uint8List encryptedData,
    required String magicHeader,
    required int formatVersion,
  }) {
    final result = BytesBuilder();

    // Validate and add magic header (must be 4 bytes)
    final headerBytes = utf8.encode(magicHeader);
    if (headerBytes.length != 4) {
      throw ArgumentError('Magic header must be exactly 4 bytes long');
    }
    result.add(headerBytes);

    // Adding the format version (4 bytes, little-endian)
    final versionBytes = Uint8List(4);
    final versionData = ByteData.view(versionBytes.buffer);
    versionData.setUint32(0, formatVersion, Endian.little);
    result.add(versionBytes);

    // Adding the key type (1 byte)
    result.add([_keyType == LicensifyKeyType.rsa ? 0 : 1]);

    // Adding the encrypted data
    result.add(encryptedData);

    return result.toBytes();
  }
}
