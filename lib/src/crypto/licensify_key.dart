// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';
import 'package:pointycastle/api.dart' show Digest;

/// Cryptographic key type
enum LicensifyKeyType {
  /// RSA algorithm (traditional)
  /// @deprecated RSA support is being phased out, use ECDSA instead
  rsa,

  /// ECDSA algorithm (elliptic curves)
  ecdsa,
}

/// Base class for all cryptographic keys
sealed class LicensifyKey {
  /// PEM-encoded key content
  final String content;

  /// Type of the key (only ECDSA supported for operations)
  final LicensifyKeyType keyType;

  const LicensifyKey({required this.content, required this.keyType});

  @override
  String toString() => content;
}

/// Represents a private key used for signing licenses
final class LicensifyPrivateKey extends LicensifyKey {
  /// Creates a private key with specified content and type
  ///
  /// [content] - PEM-encoded private key
  /// [keyType] - Type of the key (RSA or ECDSA)
  const LicensifyPrivateKey._({required super.content, required super.keyType});

  /// Creates an RSA private key
  ///
  /// @deprecated RSA support is being phased out, can only be used for key generation
  factory LicensifyPrivateKey.rsa(String content) =>
      LicensifyPrivateKey._(content: content, keyType: LicensifyKeyType.rsa);

  /// Creates an ECDSA private key
  factory LicensifyPrivateKey.ecdsa(String content) =>
      LicensifyPrivateKey._(content: content, keyType: LicensifyKeyType.ecdsa);

  /// Creates a license generator for the private key
  LicenseGenerator get licenseGenerator {
    // Ensure only ECDSA keys are used for operations
    if (keyType != LicensifyKeyType.ecdsa) {
      throw UnsupportedError(
        'Only ECDSA keys are supported for license generation. RSA is deprecated.',
      );
    }
    return LicenseGenerator(privateKey: this);
  }

  /// Creates a license request decrypter for the private key
  LicenseRequestDecrypter licenseRequestDecrypter({
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) {
    // Ensure only ECDSA keys are used for operations
    if (keyType != LicensifyKeyType.ecdsa) {
      throw UnsupportedError(
        'Only ECDSA keys are supported for license request decryption. RSA is deprecated.',
      );
    }
    return LicenseRequestDecrypter(
      privateKey: this,
      aesKeySize: aesKeySize,
      hkdfDigest: hkdfDigest,
      hkdfSalt: hkdfSalt,
      hkdfInfo: hkdfInfo,
    );
  }
}

/// Represents a public key used for validating licenses
final class LicensifyPublicKey extends LicensifyKey {
  /// Creates a public key with specified content and type
  ///
  /// [content] - PEM-encoded public key
  /// [keyType] - Type of the key (RSA or ECDSA)
  const LicensifyPublicKey._({required super.content, required super.keyType});

  /// Creates an RSA public key
  ///
  /// @deprecated RSA support is being phased out, can only be used for key generation
  factory LicensifyPublicKey.rsa(String content) =>
      LicensifyPublicKey._(content: content, keyType: LicensifyKeyType.rsa);

  /// Creates an ECDSA public key
  factory LicensifyPublicKey.ecdsa(String content) =>
      LicensifyPublicKey._(content: content, keyType: LicensifyKeyType.ecdsa);

  /// Creates a license validator for the public key
  LicenseValidator get licenseValidator {
    // Ensure only ECDSA keys are used for operations
    if (keyType != LicensifyKeyType.ecdsa) {
      throw UnsupportedError(
        'Only ECDSA keys are supported for license validation. RSA is deprecated.',
      );
    }
    return LicenseValidator(publicKey: this);
  }

  /// Creates a license request generator for the public key with custom parameters
  /// It used for generating license requests and encrypt to transport to the license issuer
  LicenseRequestGenerator licenseRequestGenerator({
    String magicHeader = LicenseRequest.magicHeader,
    int formatVersion = 1,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) {
    // Ensure only ECDSA keys are used for operations
    if (keyType != LicensifyKeyType.ecdsa) {
      throw UnsupportedError(
        'Only ECDSA keys are supported for license request generation. RSA is deprecated.',
      );
    }
    return LicenseRequestGenerator(
      publicKey: this,
      magicHeader: magicHeader,
      formatVersion: formatVersion,
      aesKeySize: aesKeySize,
      hkdfDigest: hkdfDigest,
      hkdfSalt: hkdfSalt,
      hkdfInfo: hkdfInfo,
    );
  }
}

/// Represents a cryptographic key pair (private and public keys)
final class LicensifyKeyPair {
  /// Private key for signing
  final LicensifyPrivateKey privateKey;

  /// Public key for verification
  final LicensifyPublicKey publicKey;

  /// Creates a key pair with the given private and public keys
  ///
  /// [privateKey] - The private key
  /// [publicKey] - The public key
  const LicensifyKeyPair({required this.privateKey, required this.publicKey});

  /// Checks if the keys are of the same type
  bool get isConsistent => privateKey.keyType == publicKey.keyType;

  /// Returns the type of the key pair
  LicensifyKeyType get keyType => privateKey.keyType;
}
