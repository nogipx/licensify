// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Decrypter for license requests
///
/// Class that decrypts license requests using a private key.
/// Used on the server side (or license issuer).
class LicenseRequestDecrypter implements ILicenseRequestDecrypter {
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

  /// Creates a new license request decrypter
  ///
  /// [privateKey] - Private key in PEM format for decryption
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  LicenseRequestDecrypter({
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

  /// Decrypts a license request and returns an object
  ///
  /// [requestBytes] - Encrypted bytes of the license request
  ///
  /// Returns an object [LicenseRequest] with decrypted data.
  /// Throws an exception if the request is in the wrong format or cannot be decrypted.
  @override
  LicenseRequest call(Uint8List requestBytes) {
    if (_keyType == LicensifyKeyType.rsa) {
      throw UnsupportedError('RSA is deprecated');
    }

    _validateRequestFormat(requestBytes);

    // Get encrypted data
    final encryptedData = requestBytes.sublist(9);

    // Decrypt data
    final jsonString = _decryptWithEcdh(encryptedData);

    // Convert JSON to license request object
    return LicenseRequest.fromJsonString(jsonString);
  }

  /// Checks the request format and extracts metadata
  void _validateRequestFormat(Uint8List requestBytes) {
    if (requestBytes.length < 9) {
      throw FormatException(
        'License request too short: ${requestBytes.length} bytes',
      );
    }

    // Check the magic header
    final header = utf8.decode(requestBytes.sublist(0, 4));
    if (header != LicenseRequest.magicHeader) {
      throw FormatException('Invalid request format: wrong header');
    }

    // Check the format version
    final versionData = ByteData.view(requestBytes.sublist(4, 8).buffer);
    final version = versionData.getUint32(0, Endian.little);
    if (version != 1) {
      throw FormatException('Unsupported format version: $version');
    }

    // Check the key type
    final keyType =
        requestBytes[8] == 0 ? LicensifyKeyType.rsa : LicensifyKeyType.ecdsa;
    if (keyType != _keyType) {
      throw FormatException(
        'Key type mismatch: request is for ${keyType.name}, but decrypter uses ${_keyType.name}',
      );
    }
  }

  /// Decrypts using ECDH
  String _decryptWithEcdh(Uint8List encryptedData) {
    final decryptedData = ECCipher.decryptWithLicensifyKey(
      encryptedData: encryptedData,
      privateKey: _privateKey,
      aesKeySize: _aesKeySize,
      hkdfDigest: _hkdfDigest,
      hkdfSalt: _hkdfSalt,
      hkdfInfo: _hkdfInfo,
    );

    return utf8.decode(decryptedData);
  }
}
