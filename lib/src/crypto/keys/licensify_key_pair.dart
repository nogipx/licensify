// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of 'package:licensify/licensify.dart';

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

  /// Creates a key pair from a PASERK k4.secret string
  factory LicensifyKeyPair.fromPaserkSecret(String paserk) {
    final paserkKey = K4SecretKey.fromString(paserk);
    final privateKeyBytes = Uint8List.fromList(paserkKey.rawBytes.sublist(0, 32));
    final publicKeyBytes = Uint8List.fromList(paserkKey.rawBytes.sublist(32));
    return LicensifyKeyPair.ed25519(
      privateKeyBytes: privateKeyBytes,
      publicKeyBytes: publicKeyBytes,
    );
  }

  /// Converts the key pair into PASERK k4.secret representation
  String toPaserkSecret() {
    return privateKey.executeWithKeyBytes((privateBytes) {
      return publicKey.executeWithKeyBytes((publicBytes) {
        final combined = Uint8List(privateBytes.length + publicBytes.length);
        combined.setRange(0, privateBytes.length, privateBytes);
        combined.setRange(privateBytes.length, combined.length, publicBytes);
        final paserkKey = K4SecretKey(combined);
        return paserkKey.toString();
      });
    });
  }

  /// Computes PASERK k4.sid identifier for this secret key
  String toPaserkSecretIdentifier() {
    return privateKey.executeWithKeyBytes((privateBytes) {
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

  /// Restores a key pair from PASERK k4.secret-pw representation using [password]
  static Future<LicensifyKeyPair> fromPaserkSecretPassword(
    String paserk,
    String password,
  ) async {
    final paserkKey = await K4SecretPw.unwrap(paserk, password);
    final privateKeyBytes =
        Uint8List.fromList(paserkKey.rawBytes.sublist(0, 32));
    final publicKeyBytes =
        Uint8List.fromList(paserkKey.rawBytes.sublist(32));
    return LicensifyKeyPair.ed25519(
      privateKeyBytes: privateKeyBytes,
      publicKeyBytes: publicKeyBytes,
    );
  }

  /// Wraps the key pair into PASERK k4.secret-pw representation
  Future<String> toPaserkSecretPassword(
    String password, {
    int memoryCost = K4SecretPw.defaultMemoryCost,
    int timeCost = K4SecretPw.defaultTimeCost,
    int parallelism = K4SecretPw.defaultParallelism,
  }) {
    return privateKey.executeWithKeyBytesAsync((privateBytes) async {
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
}
