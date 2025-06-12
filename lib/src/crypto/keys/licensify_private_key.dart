part of '../_index.dart';

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

  /// Creates a license generator for the private key
  LicenseGenerator get licenseGenerator {
    if (keyType != LicensifyKeyType.ed25519Public) {
      throw UnsupportedError(
        'Only Ed25519 public keys are supported for license generation.',
      );
    }
    return LicenseGenerator(privateKey: this);
  }
}
