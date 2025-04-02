// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:licensify/src/crypto/utils/ec_cipher.dart';
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
    // Check and extract header
    _validateRequestFormat(requestBytes);

    // Get encrypted data
    final encryptedData = requestBytes.sublist(9);

    // Decrypt data
    final jsonString = _decryptRequestData(encryptedData);

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
    if (header != 'MLRQ') {
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

  /// Decrypts the request data
  String _decryptRequestData(Uint8List encryptedData) {
    if (_keyType == LicensifyKeyType.rsa) {
      return _decryptWithRsa(encryptedData);
    } else {
      return _decryptWithEcdh(encryptedData);
    }
  }

  /// Decrypts using RSA
  String _decryptWithRsa(Uint8List encryptedData) {
    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(_privateKey.content);

    // Check if it's direct RSA encryption or hybrid scheme with AES
    final isHybrid =
        encryptedData.length > 2 &&
        (encryptedData[0] > 0 || encryptedData[1] > 0);

    if (!isHybrid) {
      // Direct RSA decryption
      final decrypter = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final decryptedBytes = decrypter.process(encryptedData);
      return utf8.decode(decryptedBytes);
    } else {
      // Hybrid RSA + AES decryption
      final keyLength = (encryptedData[0] << 8) + encryptedData[1];
      final encryptedKey = encryptedData.sublist(2, 2 + keyLength);
      final encryptedContent = encryptedData.sublist(2 + keyLength);

      // Decrypt AES key
      final decrypter = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final keyData = decrypter.process(encryptedKey);

      // Extract AES key and IV
      final aesKey = keyData.sublist(0, 32);
      final aesIv = keyData.sublist(32, 48);

      // Decrypt content with AES
      final aesKeyParam = KeyParameter(aesKey);
      final params = ParametersWithIV(aesKeyParam, aesIv);
      final aesCipher = CBCBlockCipher(AESEngine())..init(false, params);

      // Decryption
      final decryptedContent = Uint8List(encryptedContent.length);
      for (
        var offset = 0;
        offset < encryptedContent.length;
        offset += aesCipher.blockSize
      ) {
        aesCipher.processBlock(
          encryptedContent,
          offset,
          decryptedContent,
          offset,
        );
      }

      // Remove PKCS7 padding
      final padLength = decryptedContent[decryptedContent.length - 1];
      if (padLength > 0 && padLength <= aesCipher.blockSize) {
        final unpaddedLength = decryptedContent.length - padLength;
        return utf8.decode(decryptedContent.sublist(0, unpaddedLength));
      }

      return utf8.decode(decryptedContent);
    }
  }

  /// Decrypts using ECDH
  String _decryptWithEcdh(Uint8List encryptedData) {
    // Используем класс ECCipher для дешифрования данных
    final decryptedData = ECCipher.decryptWithLicensifyKey(
      encryptedData: encryptedData,
      privateKey: _privateKey,
      aesKeySize: _aesKeySize,
      hkdfDigest: _hkdfDigest,
      hkdfSalt: _hkdfSalt,
      hkdfInfo: _hkdfInfo,
    );

    // Конвертируем байты в JSON-строку
    return utf8.decode(decryptedData);
  }
}
