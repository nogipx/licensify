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
  factory LicensifySymmetricKey.xchacha20(Uint8List keyBytes) {
    _PasetoV4.validateXChaCha20KeyBytes(keyBytes);
    return LicensifySymmetricKey._(
      keyBytes: keyBytes,
      keyType: LicensifyKeyType.xchacha20Local,
    );
  }

  /// Creates a symmetric key from a PASERK k4.local string
  factory LicensifySymmetricKey.fromPaserk(String paserk) {
    final paserkKey = K4LocalKey.fromString(paserk);
    return LicensifySymmetricKey.xchacha20(
      Uint8List.fromList(paserkKey.rawBytes),
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

  /// Creates a symmetric key from a PASERK k4.local-pw string using [password]
  static Future<LicensifySymmetricKey> fromPaserkPassword(
    String paserk,
    String password,
  ) async {
    final paserkKey = await K4LocalPw.unwrap(paserk, password);
    return LicensifySymmetricKey.xchacha20(
      Uint8List.fromList(paserkKey.rawBytes),
    );
  }

  /// Wraps the symmetric key into PASERK k4.local-pw representation
  Future<String> toPaserkPassword(
    String password, {
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

  // Геттер crypto убран - используйте Licensify.encryptData() и Licensify.decryptData() вместо него
}
