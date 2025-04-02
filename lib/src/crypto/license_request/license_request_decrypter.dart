// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
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

  /// Creates a new license request decrypter
  ///
  /// [privateKey] - Private key in PEM format for decryption
  LicenseRequestDecrypter({required LicensifyPrivateKey privateKey})
    : _privateKey = privateKey,
      _keyType = privateKey.keyType;

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
    // Check minimum length
    if (requestBytes.length < 9) {
      throw FormatException('License request is too short');
    }

    // Check magic header
    final header = utf8.decode(requestBytes.sublist(0, 4));
    if (header != 'MLRQ') {
      throw FormatException('Invalid request format: incorrect header');
    }

    // Check version
    final versionData = ByteData.view(requestBytes.sublist(4, 8).buffer);
    final version = versionData.getUint32(0, Endian.little);
    if (version != 1) {
      throw FormatException('Unsupported format version: $version');
    }

    // Check key type
    final keyType =
        requestBytes[8] == 0 ? LicensifyKeyType.rsa : LicensifyKeyType.ecdsa;

    // Check key type
    if (keyType != _keyType) {
      throw FormatException(
        'Key type in request (${keyType.name}) does not match the key type of the decrypter (${_keyType.name})',
      );
    }
  }

  /// Decrypts request data
  String _decryptRequestData(Uint8List encryptedData) {
    // Select decryption method based on key type
    if (_keyType == LicensifyKeyType.rsa) {
      return _decryptWithRsa(encryptedData);
    } else {
      return _decryptWithEcdh(encryptedData);
    }
  }

  /// Decrypts data using RSA
  String _decryptWithRsa(Uint8List encryptedData) {
    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(_privateKey.content);

    // Check if this is direct encryption or hybrid scheme
    final isHybrid =
        encryptedData.length > 2 &&
        (encryptedData[0] > 0 || encryptedData[1] > 0);

    if (!isHybrid) {
      // Direct RSA encryption
      final decrypter = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final decryptedBytes = decrypter.process(encryptedData);
      return utf8.decode(decryptedBytes);
    } else {
      // Hybrid scheme RSA + AES
      final keyLength = (encryptedData[0] << 8) + encryptedData[1];
      final encryptedKey = encryptedData.sublist(2, 2 + keyLength);
      final encryptedContent = encryptedData.sublist(2 + keyLength);

      // Decrypt AES key
      final decrypter = OAEPEncoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      final keyData = decrypter.process(encryptedKey);

      // Extract key and IV
      final aesKey = keyData.sublist(0, 32);
      final aesIv = keyData.sublist(32, 48);

      // Decrypt content
      final decryptedContent = _decryptWithAes(encryptedContent, aesKey, aesIv);
      return utf8.decode(decryptedContent);
    }
  }

  /// Decrypts data using ECDH
  String _decryptWithEcdh(Uint8List encryptedData) {
    // Extract key length
    final keyLength = (encryptedData[0] << 8) + encryptedData[1];

    // Extract ephemeral public key
    final ephemeralPublicKeyBytes = encryptedData.sublist(2, 2 + keyLength);

    // Extract IV (16 bytes)
    final ivStart = 2 + keyLength;
    final iv = encryptedData.sublist(ivStart, ivStart + 16);

    // Extract encrypted data
    final ciphertextStart = ivStart + 16;
    final ciphertext = encryptedData.sublist(ciphertextStart);

    // Load private key
    final privateKey = CryptoUtils.ecPrivateKeyFromPem(_privateKey.content);

    // Deserialize ephemeral public key
    final ephemeralPublicKey = _deserializeEcPublicKey(ephemeralPublicKeyBytes);

    // Compute shared secret
    final sharedSecret = _computeSharedSecret(privateKey, ephemeralPublicKey);

    // Derive AES key from secret
    final aesKey = _deriveAesKey(sharedSecret);

    // Decrypt data
    final decryptedData = _decryptWithAes(ciphertext, aesKey, iv);

    // Convert bytes to JSON string
    return utf8.decode(decryptedData);
  }

  /// Deserializes public key from X9.63 format
  ECPublicKey _deserializeEcPublicKey(Uint8List bytes) {
    if (bytes[0] != 0x04) {
      throw FormatException('Unsupported key format: ${bytes[0]}');
    }

    final halfLength = (bytes.length - 1) ~/ 2;
    final xBytes = bytes.sublist(1, 1 + halfLength);
    final yBytes = bytes.sublist(1 + halfLength);

    final x = _bytesToBigInt(xBytes);
    final y = _bytesToBigInt(yBytes);

    final domain = ECDomainParameters('secp256r1');
    return ECPublicKey(domain.curve.createPoint(x, y), domain);
  }

  /// Computes the shared secret using the ECDH algorithm
  Uint8List _computeSharedSecret(
    ECPrivateKey privateKey,
    ECPublicKey publicKey,
  ) {
    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey);
    final sharedSecret = agreement.calculateAgreement(publicKey);
    return _bigIntToBytes(sharedSecret);
  }

  /// Derives AES key from the shared secret using HKDF
  Uint8List _deriveAesKey(Uint8List sharedSecret) {
    // Step 1: Extraction
    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(
      KeyParameter(Uint8List.fromList(utf8.encode('LICENSIFY-ECDH-Salt'))),
    );
    final prk = hmac.process(sharedSecret);

    // Step 2: Expansion
    hmac.init(KeyParameter(prk));
    final info = Uint8List.fromList(utf8.encode('LICENSIFY-ECDH-AES'));
    final t = hmac.process(Uint8List.fromList([...info, 1]));

    // Return first 32 bytes (256 bits for AES-256)
    return t.sublist(0, 32);
  }

  /// Decrypts data using AES in CBC mode
  Uint8List _decryptWithAes(Uint8List data, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final params = ParametersWithIV(aesKey, iv);
    final aesCipher = CBCBlockCipher(AESEngine())..init(false, params);

    final result = Uint8List(data.length);

    // Decrypt blocks
    for (var offset = 0; offset < data.length; offset += aesCipher.blockSize) {
      aesCipher.processBlock(data, offset, result, offset);
    }

    // Remove PKCS7 padding
    final padLength = result[result.length - 1];
    if (padLength > 0 && padLength <= aesCipher.blockSize) {
      final unpaddedLength = result.length - padLength;
      return result.sublist(0, unpaddedLength);
    }

    return result;
  }

  /// Converts bytes to BigInt
  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Converts BigInt to bytes
  Uint8List _bigIntToBytes(BigInt number) {
    final hexString = number.toRadixString(16).padLeft(64, '0');
    final bytes = <int>[];

    for (var i = 0; i < hexString.length; i += 2) {
      final byte = int.parse(hexString.substring(i, i + 2), radix: 16);
      bytes.add(byte);
    }

    return Uint8List.fromList(bytes);
  }
}
