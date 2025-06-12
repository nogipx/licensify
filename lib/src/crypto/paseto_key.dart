// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'license/paseto_license_generator.dart';
import 'license/paseto_license_validator.dart';
import 'dart:math';
import 'keys_generators/ed25519_key_generator.dart';

/// PASETO key type
enum PasetoKeyType {
  /// Ed25519 keys for PASETO v4.public (signatures)
  ed25519Public,

  /// XChaCha20 symmetric keys for PASETO v4.local (encryption)
  xchacha20Local,
}

/// Base class for PASETO cryptographic keys
sealed class LicensifyPasetoKey {
  /// Raw key bytes
  final Uint8List keyBytes;

  /// Type of the PASETO key
  final PasetoKeyType keyType;

  const LicensifyPasetoKey({required this.keyBytes, required this.keyType});

  @override
  String toString() =>
      'LicensifyPasetoKey(type: $keyType, length: ${keyBytes.length})';
}

/// Represents a PASETO private key used for signing or encrypting
final class LicensifyPasetoPrivateKey extends LicensifyPasetoKey {
  /// Creates a private key with specified content and type
  const LicensifyPasetoPrivateKey._({
    required super.keyBytes,
    required super.keyType,
  });

  /// Creates an Ed25519 private key for PASETO v4.public
  factory LicensifyPasetoPrivateKey.ed25519(Uint8List keyBytes) {
    if (keyBytes.length != 32) {
      throw ArgumentError('Ed25519 private key must be exactly 32 bytes');
    }
    return LicensifyPasetoPrivateKey._(
      keyBytes: keyBytes,
      keyType: PasetoKeyType.ed25519Public,
    );
  }

  /// Creates a symmetric key for PASETO v4.local
  factory LicensifyPasetoPrivateKey.xchacha20(Uint8List keyBytes) {
    if (keyBytes.length != 32) {
      throw ArgumentError('XChaCha20 key must be exactly 32 bytes');
    }
    return LicensifyPasetoPrivateKey._(
      keyBytes: keyBytes,
      keyType: PasetoKeyType.xchacha20Local,
    );
  }

  /// Creates a license generator for the private key
  LicensifyPasetoLicenseGenerator get licenseGenerator {
    switch (keyType) {
      case PasetoKeyType.ed25519Public:
        return LicensifyPasetoLicenseGenerator.ed25519(this);
      case PasetoKeyType.xchacha20Local:
        return LicensifyPasetoLicenseGenerator.xchacha20(this);
    }
  }
}

/// Represents a PASETO public key used for verification
final class LicensifyPasetoPublicKey extends LicensifyPasetoKey {
  /// Creates a public key with specified content and type
  const LicensifyPasetoPublicKey._({
    required super.keyBytes,
    required super.keyType,
  });

  /// Creates an Ed25519 public key for PASETO v4.public
  factory LicensifyPasetoPublicKey.ed25519(Uint8List keyBytes) {
    if (keyBytes.length != 32) {
      throw ArgumentError('Ed25519 public key must be exactly 32 bytes');
    }
    return LicensifyPasetoPublicKey._(
      keyBytes: keyBytes,
      keyType: PasetoKeyType.ed25519Public,
    );
  }

  /// Creates a license validator for the public key
  LicensifyPasetoLicenseValidator get licenseValidator {
    if (keyType != PasetoKeyType.ed25519Public) {
      throw UnsupportedError(
        'Only Ed25519 public keys are supported for license validation.',
      );
    }
    return LicensifyPasetoLicenseValidator(this);
  }
}

/// Represents a PASETO cryptographic key pair
final class LicensifyPasetoKeyPair {
  /// Private key for signing/encrypting
  final LicensifyPasetoPrivateKey privateKey;

  /// Public key for verification (only for Ed25519)
  final LicensifyPasetoPublicKey? publicKey;

  /// Creates a key pair with the given private and optional public key
  const LicensifyPasetoKeyPair({required this.privateKey, this.publicKey});

  /// Creates an Ed25519 key pair for PASETO v4.public
  factory LicensifyPasetoKeyPair.ed25519({
    required Uint8List privateKeyBytes,
    required Uint8List publicKeyBytes,
  }) {
    return LicensifyPasetoKeyPair(
      privateKey: LicensifyPasetoPrivateKey.ed25519(privateKeyBytes),
      publicKey: LicensifyPasetoPublicKey.ed25519(publicKeyBytes),
    );
  }

  /// Creates a symmetric key pair for PASETO v4.local
  factory LicensifyPasetoKeyPair.xchacha20({required Uint8List keyBytes}) {
    return LicensifyPasetoKeyPair(
      privateKey: LicensifyPasetoPrivateKey.xchacha20(keyBytes),
      publicKey: null, // Symmetric keys don't have public keys
    );
  }

  /// Generates a new Ed25519 key pair for PASETO v4.public
  ///
  /// Ed25519 is the modern elliptic curve signature algorithm used by PASETO v4.
  /// This method now uses real cryptographic key generation.
  static Future<LicensifyPasetoKeyPair> generateEd25519() async {
    return await Ed25519KeyGenerator.generateKeyPair();
  }

  /// Generates a new symmetric key for PASETO v4.local
  factory LicensifyPasetoKeyPair.generateXChaCha20() {
    // Temporary implementation - generate random 32-byte key
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    return LicensifyPasetoKeyPair.xchacha20(keyBytes: keyBytes);
  }

  /// Checks if the keys are of the same type
  bool get isConsistent =>
      publicKey == null || privateKey.keyType == publicKey!.keyType;

  /// Returns the type of the key pair
  PasetoKeyType get keyType => privateKey.keyType;

  /// Whether this is an asymmetric key pair (has public key)
  bool get isAsymmetric => publicKey != null;

  /// Whether this is a symmetric key (no public key)
  bool get isSymmetric => publicKey == null;
}
