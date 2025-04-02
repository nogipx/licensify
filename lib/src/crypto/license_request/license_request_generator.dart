// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// License request generator
///
/// Class responsible for creating, encrypting and preparing
/// license request for sending to the server.
class LicenseRequestGenerator implements ILicenseRequestGenerator {
  /// Public key for encrypting data
  final LicensifyPublicKey _publicKey;

  /// Encryption key type
  final LicensifyKeyType _keyType;

  /// Magic header for identifying the request file
  final String _magicHeader;

  /// Request format version
  final int _formatVersion;

  /// AES key size in bits
  final int _aesKeySize;

  /// Digest algorithm for HKDF
  final Digest _hkdfDigest;

  /// Salt for HKDF key derivation
  final String _hkdfSalt;

  /// Info string for HKDF key derivation
  final String _hkdfInfo;

  /// Creates a new license request generator
  ///
  /// [publicKey] - Public key in PEM format for encrypting the request
  /// [magicHeader] - Magic header for identifying the request file
  /// [formatVersion] - Request format version
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  LicenseRequestGenerator({
    required LicensifyPublicKey publicKey,
    String magicHeader = LicenseRequest.magicHeader,
    int formatVersion = 1,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) : _publicKey = publicKey,
       _keyType = publicKey.keyType,
       _magicHeader = magicHeader,
       _formatVersion = formatVersion,
       _aesKeySize = aesKeySize,
       _hkdfDigest = hkdfDigest ?? SHA256Digest(),
       _hkdfSalt = hkdfSalt ?? 'LICENSIFY-ECDH-Salt',
       _hkdfInfo = hkdfInfo ?? 'LICENSIFY-ECDH-AES';

  /// Creates and encrypts a license request
  ///
  /// [deviceHash] - Device hash
  /// [appId] - Application ID
  /// [expirationHours] - Expiration time in hours (default 48 hours)
  ///
  /// Returns encrypted license request bytes.
  @override
  Uint8List call({
    required String deviceHash,
    required String appId,
    int expirationHours = 48,
  }) {
    if (_keyType == LicensifyKeyType.rsa) {
      throw UnsupportedError('RSA is deprecated');
    }

    // Creating the request
    final request = LicenseRequest(
      deviceHash: deviceHash,
      appId: appId,
      createdAt: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(Duration(hours: expirationHours)),
    );

    // Encrypting the request
    final encryptedData = _encryptRequest(request);

    // Preparing binary format
    return _formatRequestData(encryptedData);
  }

  /// Encrypts the license request with the public key
  Uint8List _encryptRequest(LicenseRequest request) {
    // Getting JSON string of the request
    final jsonData = request.toJsonString();
    final dataToEncrypt = utf8.encode(jsonData);

    return ECCipher.encryptWithLicensifyKey(
      data: dataToEncrypt,
      publicKey: _publicKey,
      aesKeySize: _aesKeySize,
      hkdfDigest: _hkdfDigest,
      hkdfSalt: _hkdfSalt,
      hkdfInfo: _hkdfInfo,
    );
  }

  /// Formats the encrypted data in binary format
  Uint8List _formatRequestData(Uint8List encryptedData) {
    final result = BytesBuilder();

    // Adding the magic header
    result.add(utf8.encode(_magicHeader));

    // Adding the format version (4 bytes, little-endian)
    final versionBytes = Uint8List(4);
    final versionData = ByteData.view(versionBytes.buffer);
    versionData.setUint32(0, _formatVersion, Endian.little);
    result.add(versionBytes);

    // Adding the key type (1 byte)
    result.add([_keyType == LicensifyKeyType.rsa ? 0 : 1]);

    // Adding the encrypted data
    result.add(encryptedData);

    return result.toBytes();
  }
}
