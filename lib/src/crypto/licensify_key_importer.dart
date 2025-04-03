// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'dart:convert';

import 'package:licensify/licensify.dart';

/// Utility for importing cryptographic keys from PEM format
///
/// Provides convenient methods for creating [LicensifyPrivateKey],
/// [LicensifyPublicKey] and [LicensifyKeyPair] objects from PEM strings or bytes.
abstract final class LicensifyKeyImporter {
  /// Creates a private key from a PEM string
  ///
  /// Automatically determines the key type (RSA or ECDSA) based on the header.
  ///
  /// [pemContent] - PEM content of the key
  ///
  /// Returns [LicensifyPrivateKey] with the corresponding type
  static LicensifyPrivateKey importPrivateKeyFromString(String pemContent) {
    // Check key content
    _validatePemContent(pemContent);

    // Determine key type
    if (_isRsaPrivateKey(pemContent)) {
      return LicensifyPrivateKey.rsa(pemContent);
    } else if (_isEcdsaPrivateKey(pemContent)) {
      return LicensifyPrivateKey.ecdsa(pemContent);
    }

    throw FormatException(
      'Unsupported private key format. Only RSA and ECDSA keys are supported',
    );
  }

  /// Creates a public key from a PEM string
  ///
  /// Automatically determines the key type (RSA or ECDSA) based on the header.
  ///
  /// [pemContent] - PEM content of the key
  ///
  /// Returns [LicensifyPublicKey] with the corresponding type
  static LicensifyPublicKey importPublicKeyFromString(String pemContent) {
    // Check key content
    _validatePemContent(pemContent);

    // Determine key type
    if (_isRsaPublicKey(pemContent)) {
      return LicensifyPublicKey.rsa(pemContent);
    } else if (_isEcdsaPublicKey(pemContent)) {
      return LicensifyPublicKey.ecdsa(pemContent);
    }

    throw FormatException(
      'Unsupported public key format. Only RSA and ECDSA keys are supported',
    );
  }

  /// Creates a private key from bytes in PEM format
  ///
  /// Automatically determines the key type (RSA or ECDSA)
  ///
  /// [bytes] - PEM content of the key (UTF-8)
  ///
  /// Returns [LicensifyPrivateKey] with the corresponding type
  static LicensifyPrivateKey importPrivateKeyFromBytes(Uint8List bytes) {
    final pemContent = utf8.decode(bytes);
    return importPrivateKeyFromString(pemContent);
  }

  /// Creates a public key from bytes in PEM format
  ///
  /// Automatically determines the key type (RSA or ECDSA)
  ///
  /// [bytes] - PEM content of the key (UTF-8)
  ///
  /// Returns [LicensifyPublicKey] with the corresponding type
  static LicensifyPublicKey importPublicKeyFromBytes(Uint8List bytes) {
    final pemContent = utf8.decode(bytes);
    return importPublicKeyFromString(pemContent);
  }

  /// Imports a key pair from PEM strings
  ///
  /// [privateKeyPem] - PEM content of the private key
  /// [publicKeyPem] - PEM content of the public key
  ///
  /// Returns [LicensifyKeyPair] with the corresponding type
  static LicensifyKeyPair importKeyPairFromStrings({
    required String privateKeyPem,
    required String publicKeyPem,
  }) {
    final privateKey = importPrivateKeyFromString(privateKeyPem);
    final publicKey = importPublicKeyFromString(publicKeyPem);

    final keyPair = LicensifyKeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );

    // Check key consistency
    if (!keyPair.isConsistent) {
      throw FormatException(
        'Inconsistent key types. Private key: ${privateKey.keyType}, '
        'public key: ${publicKey.keyType}',
      );
    }

    return keyPair;
  }

  /// Imports a key pair from bytes in PEM format
  ///
  /// [privateKeyBytes] - PEM content of the private key (UTF-8)
  /// [publicKeyBytes] - PEM content of the public key (UTF-8)
  ///
  /// Returns [LicensifyKeyPair] with the corresponding type
  static LicensifyKeyPair importKeyPairFromBytes({
    required Uint8List privateKeyBytes,
    required Uint8List publicKeyBytes,
  }) {
    final privateKey = importPrivateKeyFromBytes(privateKeyBytes);
    final publicKey = importPublicKeyFromBytes(publicKeyBytes);

    final keyPair = LicensifyKeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );

    // Check key consistency
    if (!keyPair.isConsistent) {
      throw FormatException(
        'Inconsistent key types. Private key: ${privateKey.keyType}, '
        'public key: ${publicKey.keyType}',
      );
    }

    return keyPair;
  }

  /// Checks the correctness of PEM content
  static void _validatePemContent(String pemContent) {
    if (pemContent.trim().isEmpty) {
      throw FormatException('Empty PEM content');
    }

    if (!pemContent.contains('-----BEGIN') ||
        !pemContent.contains('-----END')) {
      throw FormatException('Invalid PEM format. Missing header or footer');
    }
  }

  /// Checks if the key is a private RSA key
  static bool _isRsaPrivateKey(String pemContent) {
    // First check by header
    if (pemContent.contains('-----BEGIN RSA PRIVATE KEY-----')) {
      return true;
    }

    // Check regular PKCS#8 private key
    if (pemContent.contains('-----BEGIN PRIVATE KEY-----')) {
      try {
        // Try to decrypt as RSA key - if successful, this is RSA
        CryptoUtils.rsaPrivateKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // If error, try ECDSA
        try {
          CryptoUtils.ecPrivateKeyFromPem(pemContent);
          return false; // This is ECDSA key
        } catch (_) {
          // Couldn't determine type, assume RSA
          // (since this is more common format)
          return true;
        }
      }
    }

    return false;
  }

  /// Checks if the key is a private ECDSA key
  static bool _isEcdsaPrivateKey(String pemContent) {
    // First check by header
    if (pemContent.contains('-----BEGIN EC PRIVATE KEY-----')) {
      return true;
    }

    // Check regular PKCS#8 private key
    if (pemContent.contains('-----BEGIN PRIVATE KEY-----')) {
      try {
        // Try to decrypt as ECDSA key - if successful, this is ECDSA
        CryptoUtils.ecPrivateKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // If error, this is not ECDSA key
        return false;
      }
    }

    return false;
  }

  /// Checks if the key is a public RSA key
  static bool _isRsaPublicKey(String pemContent) {
    // First check by header
    if (pemContent.contains('-----BEGIN RSA PUBLIC KEY-----')) {
      return true;
    }

    // Check regular PKCS#8 public key
    if (pemContent.contains('-----BEGIN PUBLIC KEY-----')) {
      try {
        // Try to decrypt as RSA key - if successful, this is RSA
        CryptoUtils.rsaPublicKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // If error, try ECDSA
        try {
          CryptoUtils.ecPublicKeyFromPem(pemContent);
          return false; // This is ECDSA key
        } catch (_) {
          // Couldn't determine type, assume RSA
          return true;
        }
      }
    }

    return false;
  }

  /// Checks if the key is a public ECDSA key
  static bool _isEcdsaPublicKey(String pemContent) {
    // First check by header
    if (pemContent.contains('-----BEGIN EC PUBLIC KEY-----')) {
      return true;
    }

    // Check regular PKCS#8 public key
    if (pemContent.contains('-----BEGIN PUBLIC KEY-----')) {
      try {
        // Try to decrypt as ECDSA key - if successful, this is ECDSA
        CryptoUtils.ecPublicKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // If error, this is not ECDSA key
        return false;
      }
    }

    return false;
  }
}
