// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of 'package:licensify/licensify.dart';

/// Represents a PASETO symmetric key used for encryption/decryption
final class LicensifySymmetricKey extends LicensifyKey {
  /// Creates a symmetric key with specified content and type
  LicensifySymmetricKey._({
    required super.keyBytes,
    required super.keyType,
  });

  /// Creates a symmetric key for PASETO v4.local
  factory LicensifySymmetricKey.xchacha20({
    required Uint8List keyBytes,
  }) {
    _PasetoV4.validateXChaCha20KeyBytes(keyBytes);
    return LicensifySymmetricKey._(
      keyBytes: keyBytes,
      keyType: LicensifyKeyType.xchacha20Local,
    );
  }

  /// Creates a symmetric key from a PASERK k4.local string
  factory LicensifySymmetricKey.fromPaserk({
    required String paserk,
  }) {
    final paserkKey = K4LocalKey.fromString(paserk);
    return LicensifySymmetricKey.xchacha20(
      keyBytes: Uint8List.fromList(paserkKey.rawBytes),
    );
  }

  /// Converts the symmetric key to a PASERK k4.local string
  String toPaserk() {
    return executeWithKeyBytes((keyBytes) {
      final paserkKey = K4LocalKey(Uint8List.fromList(keyBytes));
      return paserkKey.toString();
    });
  }

  /// Computes PASERK k4.lid identifier for this symmetric key
  String toPaserkIdentifier() {
    return executeWithKeyBytes((keyBytes) {
      final paserkKey = K4LocalKey(Uint8List.fromList(keyBytes));
      final identifier = K4Lid.fromKey(paserkKey);
      return identifier.toString();
    });
  }

  /// Derives a symmetric key directly from a user [password] and Argon2id salt.
  ///
  /// The derivation mirrors the PASERK `k4.local-pw` parameters so that
  /// developers can store only the password + salt and recompute the
  /// encryption key when needed. Provide the same [salt] whenever you expect
  /// to recover the same key. The salt must be at least
  /// [K4LocalPw.saltLength] bytes and should be stored alongside the password
  /// hash or recovery record.
  ///
  /// Typical restore flow for a password-protected PASETO v4.local backup:
  /// 1. Retrieve the persisted salt that was saved with the encrypted backup.
  /// 2. Ask the user for the password and call
  ///    [Licensify.encryptionKeyFromPassword] (which delegates to this method)
  ///    to deterministically reconstruct the encryption key.
  /// 3. Decrypt the stored token using [Licensify.decryptData] and dispose the
  ///    key once the plaintext is recovered.
  /// 4. Optionally fall back to a sealed PASERK (`k4.seal`) copy if the user
  ///    forgets the password but still controls the private key.
  static Future<LicensifySymmetricKey> fromPassword({
    required String password,
    required List<int> salt,
    int memoryCost = K4LocalPw.defaultMemoryCost,
    int timeCost = K4LocalPw.defaultTimeCost,
    int parallelism = K4LocalPw.defaultParallelism,
  }) async {
    if (salt.length < K4LocalPw.saltLength) {
      throw ArgumentError(
        'salt must be at least ${K4LocalPw.saltLength} bytes',
      );
    }
    if (memoryCost <= 0 || memoryCost % 1024 != 0) {
      throw ArgumentError('memoryCost must be a positive multiple of 1024');
    }
    if (timeCost <= 0) {
      throw ArgumentError('timeCost must be positive');
    }
    if (parallelism <= 0) {
      throw ArgumentError('parallelism must be positive');
    }

    final algorithm = Argon2id(
      memory: memoryCost ~/ 1024,
      iterations: timeCost,
      parallelism: parallelism,
      hashLength: K4LocalKey.keyLength,
    );

    final secretKey = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: Uint8List.fromList(salt),
    );
    final derivedBytes = await secretKey.extractBytes();

    if (derivedBytes.length != K4LocalKey.keyLength) {
      throw StateError('Derived key length is invalid');
    }

    return LicensifySymmetricKey.xchacha20(
      keyBytes: Uint8List.fromList(derivedBytes),
    );
  }

  /// Creates a symmetric key from a PASERK k4.local-pw string using [password]
  static Future<LicensifySymmetricKey> fromPaserkPassword({
    required String paserk,
    required String password,
  }) async {
    final paserkKey = await K4LocalPw.unwrap(paserk, password);
    return LicensifySymmetricKey.xchacha20(
      keyBytes: Uint8List.fromList(paserkKey.rawBytes),
    );
  }

  /// Wraps the symmetric key into PASERK k4.local-pw representation
  Future<String> toPaserkPassword({
    required String password,
    int memoryCost = K4LocalPw.defaultMemoryCost,
    int timeCost = K4LocalPw.defaultTimeCost,
    int parallelism = K4LocalPw.defaultParallelism,
  }) {
    return executeWithKeyBytesAsync((keyBytes) async {
      final paserkKey = K4LocalKey(Uint8List.fromList(keyBytes));
      final wrapped = await K4LocalPw.wrap(
        paserkKey,
        password,
        memoryCost: memoryCost,
        timeCost: timeCost,
        parallelism: parallelism,
      );
      return wrapped.toString();
    });
  }

  /// Creates a symmetric key from a PASERK k4.local-wrap.pie string
  /// using another symmetric [wrappingKey].
  static LicensifySymmetricKey fromPaserkWrap({
    required String paserk,
    required LicensifySymmetricKey wrappingKey,
  }) {
    return wrappingKey.executeWithKeyBytes((wrappingBytes) {
      final wrapping = K4LocalKey(Uint8List.fromList(wrappingBytes));
      final unwrapped = K4LocalWrap.unwrap(paserk, wrapping);
      return LicensifySymmetricKey.xchacha20(
        keyBytes: Uint8List.fromList(unwrapped.rawBytes),
      );
    });
  }

  /// Wraps this symmetric key into PASERK k4.local-wrap.pie string
  /// using another symmetric [wrappingKey].
  String toPaserkWrap({
    required LicensifySymmetricKey wrappingKey,
  }) {
    return executeWithKeyBytes((keyBytes) {
      return wrappingKey.executeWithKeyBytes((wrappingBytes) {
        final key = K4LocalKey(Uint8List.fromList(keyBytes));
        final wrapper = K4LocalKey(Uint8List.fromList(wrappingBytes));
        final wrapped = K4LocalWrap.wrap(key, wrapper);
        return wrapped.toString();
      });
    });
  }

  /// Creates a symmetric key from a PASERK k4.seal string using [keyPair].
  ///
  /// The sealed blob is safe to store alongside backups: without the matching
  /// private key the payload cannot be recovered.
  static Future<LicensifySymmetricKey> fromPaserkSeal({
    required String paserk,
    required LicensifyKeyPair keyPair,
  }) {
    return keyPair.privateKey.executeWithKeyBytesAsync((privateBytes) async {
      return keyPair.publicKey.executeWithKeyBytesAsync((publicBytes) async {
        final combined = Uint8List(privateBytes.length + publicBytes.length);
        combined.setRange(0, privateBytes.length, privateBytes);
        combined.setRange(privateBytes.length, combined.length, publicBytes);
        final secretKey = K4SecretKey(combined);
        final unsealed = await K4Seal.unseal(paserk, secretKey);
        return LicensifySymmetricKey.xchacha20(
          keyBytes: Uint8List.fromList(unsealed.rawBytes),
        );
      });
    });
  }

  /// Seals this symmetric key into PASERK k4.seal string using [publicKey].
  Future<String> toPaserkSeal({
    required LicensifyPublicKey publicKey,
  }) {
    return executeWithKeyBytesAsync((keyBytes) async {
      return publicKey.executeWithKeyBytesAsync((publicBytes) async {
        final key = K4LocalKey(Uint8List.fromList(keyBytes));
        final wrapping = K4PublicKey(Uint8List.fromList(publicBytes));
        final sealed = await K4Seal.seal(key, wrapping);
        return sealed.toString();
      });
    });
  }

  // Геттер crypto убран - используйте Licensify.encryptData() и Licensify.decryptData() вместо него
}
