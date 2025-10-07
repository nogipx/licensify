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

  /// Creates an Ed25519 private key from PASERK k4.secret representation.
  ///
  /// Обратите внимание, что формат `k4.secret` содержит как приватную,
  /// так и публичную часть ключа. Этот конструктор извлекает только приватный
  /// компонент. Если вам также нужен публичный ключ, используйте
  /// [LicensifyKeyPair.fromPaserkSecret].
  factory LicensifyPrivateKey.fromPaserkSecret(String paserk) {
    final paserkKey = K4SecretKey.fromString(paserk);
    final privateKeyBytes =
        Uint8List.fromList(paserkKey.rawBytes.sublist(0, 32));
    return LicensifyPrivateKey.ed25519(privateKeyBytes);
  }

  /// Converts this private key to PASERK k4.secret representation using
  /// the matching [publicKey].
  String toPaserkSecret(LicensifyPublicKey publicKey) {
    return executeWithKeyBytes((privateBytes) {
      return publicKey.executeWithKeyBytes((publicBytes) {
        final combined = Uint8List(privateBytes.length + publicBytes.length);
        combined.setRange(0, privateBytes.length, privateBytes);
        combined.setRange(privateBytes.length, combined.length, publicBytes);
        final paserkKey = K4SecretKey(combined);
        return paserkKey.toString();
      });
    });
  }

  /// Computes PASERK k4.sid identifier for this private key using the
  /// matching [publicKey].
  String toPaserkSecretIdentifier(LicensifyPublicKey publicKey) {
    return executeWithKeyBytes((privateBytes) {
      return publicKey.executeWithKeyBytes((publicBytes) {
        final combined = Uint8List(privateBytes.length + publicBytes.length);
        combined.setRange(0, privateBytes.length, privateBytes);
        combined.setRange(privateBytes.length, combined.length, publicBytes);
        final paserkKey = K4SecretKey(combined);
        final identifier = K4Sid.fromKey(paserkKey);
        return identifier.toString();
      });
    });
  }

  /// Restores an Ed25519 private key from PASERK k4.secret-pw representation.
  static Future<LicensifyPrivateKey> fromPaserkSecretPassword(
    String paserk,
    String password,
  ) async {
    final paserkKey = await K4SecretPw.unwrap(paserk, password);
    final privateKeyBytes =
        Uint8List.fromList(paserkKey.rawBytes.sublist(0, 32));
    return LicensifyPrivateKey.ed25519(privateKeyBytes);
  }

  /// Wraps this private key into PASERK k4.secret-pw representation using
  /// the matching [publicKey].
  Future<String> toPaserkSecretPassword(
    LicensifyPublicKey publicKey,
    String password, {
    int memoryCost = K4SecretPw.defaultMemoryCost,
    int timeCost = K4SecretPw.defaultTimeCost,
    int parallelism = K4SecretPw.defaultParallelism,
  }) {
    return executeWithKeyBytesAsync((privateBytes) async {
      return publicKey.executeWithKeyBytesAsync((publicBytes) async {
        final combined = Uint8List(privateBytes.length + publicBytes.length);
        combined.setRange(0, privateBytes.length, privateBytes);
        combined.setRange(privateBytes.length, combined.length, publicBytes);
        final paserkKey = K4SecretKey(combined);
        final wrapped = await K4SecretPw.wrap(
          paserkKey,
          password,
          memoryCost: memoryCost,
          timeCost: timeCost,
          parallelism: parallelism,
        );
        return wrapped.toString();
      });
    });
  }

  /// Restores an Ed25519 private key from PASERK k4.secret-wrap.pie using
  /// the provided symmetric [wrappingKey].
  static LicensifyPrivateKey fromPaserkSecretWrap(
    String paserk,
    LicensifySymmetricKey wrappingKey,
  ) {
    return wrappingKey.executeWithKeyBytes((wrappingBytes) {
      final wrapper = K4LocalKey(Uint8List.fromList(wrappingBytes));
      final secretKey = K4SecretWrap.unwrap(paserk, wrapper);
      final privateKeyBytes =
          Uint8List.fromList(secretKey.rawBytes.sublist(0, 32));
      return LicensifyPrivateKey.ed25519(privateKeyBytes);
    });
  }

  /// Wraps this private key into PASERK k4.secret-wrap.pie using the matching
  /// [publicKey] and symmetric [wrappingKey].
  String toPaserkSecretWrap(
    LicensifyPublicKey publicKey,
    LicensifySymmetricKey wrappingKey,
  ) {
    return executeWithKeyBytes((privateBytes) {
      return publicKey.executeWithKeyBytes((publicBytes) {
        return wrappingKey.executeWithKeyBytes((wrappingBytes) {
          final combined = Uint8List(privateBytes.length + publicBytes.length);
          combined.setRange(0, privateBytes.length, privateBytes);
          combined.setRange(privateBytes.length, combined.length, publicBytes);
          final secretKey = K4SecretKey(combined);
          final wrapper = K4LocalKey(Uint8List.fromList(wrappingBytes));
          final wrapped = K4SecretWrap.wrap(secretKey, wrapper);
          return wrapped.toString();
        });
      });
    });
  }

  // Геттер licenseGenerator убран - используйте Licensify.createLicense() вместо него
}
