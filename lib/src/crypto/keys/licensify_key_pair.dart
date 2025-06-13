// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of '../_index.dart';

/// Represents a PASETO cryptographic key pair
final class LicensifyKeyPair {
  /// Private key for signing/encrypting
  final LicensifyPrivateKey privateKey;

  /// Public key for verification (only for Ed25519)
  final LicensifyPublicKey publicKey;

  /// Creates a key pair with the given private and optional public key
  const LicensifyKeyPair({required this.privateKey, required this.publicKey});

  /// Creates an Ed25519 key pair for PASETO v4.public
  factory LicensifyKeyPair.ed25519({
    required Uint8List privateKeyBytes,
    required Uint8List publicKeyBytes,
  }) {
    return LicensifyKeyPair(
      privateKey: LicensifyPrivateKey.ed25519(privateKeyBytes),
      publicKey: LicensifyPublicKey.ed25519(publicKeyBytes),
    );
  }

  /// Checks if the keys are of the same type
  bool get isConsistent => privateKey.keyType == publicKey.keyType;

  /// Returns the type of the key pair
  LicensifyKeyType get keyType => privateKey.keyType;

  ({Uint8List publicKeyBytes, Uint8List privateKeyBytes}) get asBytes {
    return (
      publicKeyBytes: publicKey.keyBytes,
      privateKeyBytes: privateKey.keyBytes,
    );
  }
}
