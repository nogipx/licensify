// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of 'package:licensify/licensify.dart';

/// Represents a PASETO public key used for verification
final class LicensifyPublicKey extends LicensifyKey {
  /// Creates a public key with specified content and type
  LicensifyPublicKey._({
    required super.keyBytes,
    required super.keyType,
  });

  /// Creates an Ed25519 public key for PASETO v4.public
  factory LicensifyPublicKey.ed25519(Uint8List keyBytes) {
    _PasetoV4.validateEd25519KeyBytes(keyBytes, 'public key');
    return LicensifyPublicKey._(
      keyBytes: keyBytes,
      keyType: LicensifyKeyType.ed25519Public,
    );
  }

  // Геттер licenseValidator убран - используйте Licensify.validateLicense() вместо него
}
