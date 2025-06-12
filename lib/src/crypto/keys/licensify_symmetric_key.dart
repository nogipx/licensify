part of '../_index.dart';

/// Represents a PASETO symmetric key used for encryption/decryption
final class LicensifySymmetricKey extends LicensifyKey {
  /// Creates a symmetric key with specified content and type
  LicensifySymmetricKey._({
    required super.keyBytes,
    required super.keyType,
  });

  /// Creates a symmetric key for PASETO v4.local
  factory LicensifySymmetricKey.xchacha20(Uint8List keyBytes) {
    _PasetoV4.validateXChaCha20KeyBytes(keyBytes);
    return LicensifySymmetricKey._(
      keyBytes: keyBytes,
      keyType: LicensifyKeyType.xchacha20Local,
    );
  }

  // Геттер crypto убран - используйте Licensify.encryptData() и Licensify.decryptData() вместо него
}
