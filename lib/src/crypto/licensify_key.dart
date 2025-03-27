// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Базовый класс для всех криптографических ключей
sealed class LicensifyKey {
  /// PEM-encoded key content
  final String content;

  /// Type of the key (RSA or ECDSA)
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
  factory LicensifyPrivateKey.rsa(String content) =>
      LicensifyPrivateKey._(content: content, keyType: LicensifyKeyType.rsa);

  /// Creates an ECDSA private key
  factory LicensifyPrivateKey.ecdsa(String content) =>
      LicensifyPrivateKey._(content: content, keyType: LicensifyKeyType.ecdsa);

  /// Creates a license generator for the private key
  LicenseGenerator get licenseGenerator => LicenseGenerator(privateKey: this);
}

/// Represents a public key used for validating licenses
final class LicensifyPublicKey extends LicensifyKey {
  /// Creates a public key with specified content and type
  ///
  /// [content] - PEM-encoded public key
  /// [keyType] - Type of the key (RSA or ECDSA)
  const LicensifyPublicKey._({required super.content, required super.keyType});

  /// Creates an RSA public key
  factory LicensifyPublicKey.rsa(String content) =>
      LicensifyPublicKey._(content: content, keyType: LicensifyKeyType.rsa);

  /// Creates an ECDSA public key
  factory LicensifyPublicKey.ecdsa(String content) =>
      LicensifyPublicKey._(content: content, keyType: LicensifyKeyType.ecdsa);

  /// Creates a license validator for the public key
  LicenseValidator get licenseValidator => LicenseValidator(publicKey: this);
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
