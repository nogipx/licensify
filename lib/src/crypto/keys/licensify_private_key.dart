// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of 'package:licensify/licensify.dart';

/// Represents a PASETO private key used for signing or encrypting
final class LicensifyPrivateKey extends LicensifyKey {
  /// Creates a private key with specified content and type
  LicensifyPrivateKey._({
    required super.keyBytes,
    required super.keyType,
  });

  /// Creates an Ed25519 private key for PASETO v4.public
  factory LicensifyPrivateKey.ed25519(Uint8List keyBytes) {
    _PasetoV4.validateEd25519KeyBytes(keyBytes, 'private key');
    return LicensifyPrivateKey._(
      keyBytes: keyBytes,
      keyType: LicensifyKeyType.ed25519Public,
    );
  }

  // Геттер licenseGenerator убран - используйте Licensify.createLicense() вместо него
}
