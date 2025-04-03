// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Class for encrypting and decrypting data using EC keys
abstract interface class ECCipher {
  /// Encrypts data using a public key
  ///
  /// Uses a hybrid encryption scheme (ECDH + AES):
  /// 1. Generates an ephemeral key pair
  /// 2. Computes a shared secret with recipient's public key
  /// 3. Derives an AES key from the shared secret
  /// 4. Encrypts the data with AES
  /// 5. Returns the ephemeral public key and encrypted data
  ///
  /// [data] - The data to encrypt
  /// [publicKey] - Recipient's public key (PEM format)
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  ///
  /// Returns a byte array containing the encrypted data in the format:
  /// [2 bytes - ephemeral key length][ephemeral public key][16 bytes - IV][encrypted data]
  static Uint8List encrypt({
    required Uint8List data,
    required String publicKeyPem,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) {
    // Parse the public key from PEM
    final publicKey = CryptoUtils.ecPublicKeyFromPem(publicKeyPem);

    // Generate ephemeral key pair using the same curve as the recipient's key
    final ephemeralKeyPair = ECDHCryptoUtils.generateEphemeralKeyPair(
      publicKey.parameters!,
    );

    // Compute shared secret
    final sharedSecret = ECDHCryptoUtils.computeSharedSecret(
      ephemeralKeyPair.privateKey,
      publicKey,
    );

    // Use default values if not provided
    final salt = hkdfSalt ?? 'ECCipher-ECDH-Salt';
    final info = hkdfInfo ?? 'ECCipher-ECDH-AES';

    // Derive AES key from shared secret
    final aesKey = ECDHCryptoUtils.deriveAesKey(
      sharedSecret: sharedSecret,
      aesKeySize: aesKeySize,
      hkdfDigest: hkdfDigest ?? SHA256Digest(),
      hkdfSalt: salt,
      hkdfInfo: info,
    );

    // Generate random IV
    final iv = ECDHCryptoUtils.generateRandomIv();

    // Encrypt data with AES
    final encryptedData = ECDHCryptoUtils.encryptWithAes(data, aesKey, iv);

    // Serialize ephemeral public key
    final ephemeralPublicKeyBytes = ECDHCryptoUtils.serializeEcPublicKey(
      ephemeralKeyPair.publicKey,
    );

    // Store HKDF parameters as metadata
    final saltBytes = utf8.encode(salt);
    final infoBytes = utf8.encode(info);

    // Calculate total length
    final keyLength = ephemeralPublicKeyBytes.length;
    final saltLength = saltBytes.length;
    final infoLength = infoBytes.length;

    // Combine all parts into single output
    // Format:
    // [2 bytes key length][ephemeral public key]
    // [1 byte salt length][salt bytes]
    // [1 byte info length][info bytes]
    // [16 bytes IV][encrypted data]
    final result = Uint8List(
      2 +
          keyLength +
          1 +
          saltLength +
          1 +
          infoLength +
          16 +
          encryptedData.length,
    );

    var offset = 0;

    // Write key length (2 bytes, big-endian)
    result[offset++] = (keyLength >> 8) & 0xFF;
    result[offset++] = keyLength & 0xFF;

    // Write ephemeral public key
    result.setRange(offset, offset + keyLength, ephemeralPublicKeyBytes);
    offset += keyLength;

    // Write salt length and salt
    result[offset++] = saltLength;
    result.setRange(offset, offset + saltLength, saltBytes);
    offset += saltLength;

    // Write info length and info
    result[offset++] = infoLength;
    result.setRange(offset, offset + infoLength, infoBytes);
    offset += infoLength;

    // Write IV
    result.setRange(offset, offset + 16, iv);
    offset += 16;

    // Write encrypted data
    result.setRange(offset, result.length, encryptedData);

    return result;
  }

  /// Decrypts data using a private key
  ///
  /// [encryptedData] - The encrypted data (output from encrypt method)
  /// [privateKey] - Recipient's private key (PEM format)
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation (overrides stored salt if provided)
  /// [hkdfInfo] - Info string for HKDF key derivation (overrides stored info if provided)
  ///
  /// Returns the original decrypted data
  static Uint8List decrypt({
    required Uint8List encryptedData,
    required String privateKeyPem,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) {
    if (encryptedData.length < 23) {
      // At minimum: 2 + 1 + 1 + 1 + 1 + 1 + 16 (headers + smallest key + smallest salt/info + IV)
      throw FormatException(
        'Encrypted data too short: ${encryptedData.length} bytes',
      );
    }

    var offset = 0;

    // Extract ephemeral key length
    final keyLength = (encryptedData[offset] << 8) | encryptedData[offset + 1];
    offset += 2;

    // Check if data has expected length for key
    if (encryptedData.length < offset + keyLength) {
      throw FormatException('Encrypted data truncated: key data missing');
    }

    // Extract ephemeral public key
    final ephemeralPublicKeyBytes = encryptedData.sublist(
      offset,
      offset + keyLength,
    );
    offset += keyLength;

    // Check remaining length for salt length
    if (offset >= encryptedData.length) {
      throw FormatException('Encrypted data truncated: salt length missing');
    }

    // Extract salt length and salt
    final saltLength = encryptedData[offset++];
    if (offset + saltLength > encryptedData.length) {
      throw FormatException('Encrypted data truncated: salt data missing');
    }
    final storedSalt = utf8.decode(
      encryptedData.sublist(offset, offset + saltLength),
    );
    offset += saltLength;

    // Check remaining length for info length
    if (offset >= encryptedData.length) {
      throw FormatException('Encrypted data truncated: info length missing');
    }

    // Extract info length and info
    final infoLength = encryptedData[offset++];
    if (offset + infoLength > encryptedData.length) {
      throw FormatException('Encrypted data truncated: info data missing');
    }
    final storedInfo = utf8.decode(
      encryptedData.sublist(offset, offset + infoLength),
    );
    offset += infoLength;

    // Check for IV
    if (offset + 16 > encryptedData.length) {
      throw FormatException('Encrypted data truncated: IV missing');
    }

    // Extract IV
    final iv = encryptedData.sublist(offset, offset + 16);
    offset += 16;

    // Extract ciphertext
    if (offset >= encryptedData.length) {
      throw FormatException('Encrypted data truncated: no ciphertext');
    }
    final ciphertext = encryptedData.sublist(offset);

    // Check if provided parameters match stored ones
    if (hkdfSalt != null && hkdfSalt != storedSalt) {
      throw FormatException(
        'HKDF salt mismatch: data was encrypted with salt "$storedSalt", but "$hkdfSalt" was provided',
      );
    }

    if (hkdfInfo != null && hkdfInfo != storedInfo) {
      throw FormatException(
        'HKDF info mismatch: data was encrypted with info "$storedInfo", but "$hkdfInfo" was provided',
      );
    }

    // Use stored parameters if not explicitly overridden
    final saltToUse = hkdfSalt ?? storedSalt;
    final infoToUse = hkdfInfo ?? storedInfo;

    // Parse private key from PEM
    final privateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);

    try {
      // Deserialize ephemeral public key with curve parameters validation
      final ephemeralPublicKey = ECDHCryptoUtils.deserializeEcPublicKey(
        ephemeralPublicKeyBytes,
        privateKey.parameters!,
      );

      // Compute shared secret
      final sharedSecret = ECDHCryptoUtils.computeSharedSecret(
        privateKey,
        ephemeralPublicKey,
      );

      // Derive AES key from shared secret
      final aesKey = ECDHCryptoUtils.deriveAesKey(
        sharedSecret: sharedSecret,
        aesKeySize: aesKeySize,
        hkdfDigest: hkdfDigest ?? SHA256Digest(),
        hkdfSalt: saltToUse,
        hkdfInfo: infoToUse,
      );

      // Decrypt data with AES
      return ECDHCryptoUtils.decryptWithAes(ciphertext, aesKey, iv);
    } catch (e) {
      throw ArgumentError(
        'Failed to decrypt data: ${e.toString()}. Possible causes: wrong key, incompatible curve, or corrupted data.',
      );
    }
  }

  /// Encrypts data using EC public key from LicensifyPublicKey
  ///
  /// This is a convenience method that accepts a LicensifyPublicKey object
  /// instead of a PEM string.
  ///
  /// [data] - The data to encrypt
  /// [publicKey] - Recipient's public key
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  static Uint8List encryptWithLicensifyKey({
    required Uint8List data,
    required LicensifyPublicKey publicKey,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) {
    if (publicKey.keyType != LicensifyKeyType.ecdsa) {
      throw ArgumentError('Public key must be an ECDSA key for EC encryption');
    }

    return encrypt(
      data: data,
      publicKeyPem: publicKey.content,
      aesKeySize: aesKeySize,
      hkdfDigest: hkdfDigest,
      hkdfSalt: hkdfSalt,
      hkdfInfo: hkdfInfo,
    );
  }

  /// Decrypts data using EC private key from LicensifyPrivateKey
  ///
  /// This is a convenience method that accepts a LicensifyPrivateKey object
  /// instead of a PEM string.
  ///
  /// [encryptedData] - The encrypted data (output from encrypt method)
  /// [privateKey] - Recipient's private key
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  static Uint8List decryptWithLicensifyKey({
    required Uint8List encryptedData,
    required LicensifyPrivateKey privateKey,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) {
    if (privateKey.keyType != LicensifyKeyType.ecdsa) {
      throw ArgumentError('Private key must be an ECDSA key for EC decryption');
    }

    return decrypt(
      encryptedData: encryptedData,
      privateKeyPem: privateKey.content,
      aesKeySize: aesKeySize,
      hkdfDigest: hkdfDigest,
      hkdfSalt: hkdfSalt,
      hkdfInfo: hkdfInfo,
    );
  }
}
