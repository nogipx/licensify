// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of 'package:licensify/licensify.dart';

/// Represents a PASETO private key used for signing or encrypting
final class LicensifyPrivateKey extends LicensifyKey {
  final Uint8List? _pairedPublicKeyBytes;

  /// Creates a private key with specified content and type
  LicensifyPrivateKey._({
    required super.keyBytes,
    required super.keyType,
    Uint8List? pairedPublicKeyBytes,
  }) : _pairedPublicKeyBytes =
            pairedPublicKeyBytes != null
                ? Uint8List.fromList(pairedPublicKeyBytes)
                : null;

  /// Creates an Ed25519 private key for PASETO v4.public.
  ///
  /// Optionally provide [publicKeyBytes] to cache the corresponding
  /// Ed25519 public component, allowing PASERK conversions without passing
  /// an explicit [LicensifyPublicKey] later.
  factory LicensifyPrivateKey.ed25519(
    Uint8List keyBytes, {
    Uint8List? publicKeyBytes,
  }) {
    _PasetoV4.validateEd25519KeyBytes(keyBytes, 'private key');
    if (publicKeyBytes != null) {
      _PasetoV4.validateEd25519KeyBytes(publicKeyBytes, 'public key');
    }
    return LicensifyPrivateKey._(
      keyBytes: keyBytes,
      keyType: LicensifyKeyType.ed25519Public,
      pairedPublicKeyBytes: publicKeyBytes,
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
    final rawBytes = paserkKey.rawBytes;
    final privateKeyBytes = Uint8List.fromList(rawBytes.sublist(0, 32));
    final publicKeyBytes = Uint8List.fromList(rawBytes.sublist(32));
    return LicensifyPrivateKey.ed25519(
      privateKeyBytes,
      publicKeyBytes: publicKeyBytes,
    );
  }

  /// Converts this private key to PASERK k4.secret representation using
  /// the matching [publicKey]. If [publicKey] is omitted, the cached
  /// public component from the paired key (when available) will be used.
  String toPaserkSecret({LicensifyPublicKey? publicKey}) {
    return executeWithKeyBytes((privateBytes) {
      return _withPublicKeyBytes(
        publicKey,
        (publicBytes) {
          final combined =
              Uint8List(privateBytes.length + publicBytes.length);
          combined.setRange(0, privateBytes.length, privateBytes);
          combined.setRange(privateBytes.length, combined.length, publicBytes);
          final paserkKey = K4SecretKey(combined);
          return paserkKey.toString();
        },
      );
    });
  }

  /// Computes PASERK k4.sid identifier for this private key using the
  /// matching [publicKey]. If [publicKey] is omitted, the cached public
  /// component from the paired key (when available) will be used.
  String toPaserkSecretIdentifier({LicensifyPublicKey? publicKey}) {
    return executeWithKeyBytes((privateBytes) {
      return _withPublicKeyBytes(
        publicKey,
        (publicBytes) {
          final combined =
              Uint8List(privateBytes.length + publicBytes.length);
          combined.setRange(0, privateBytes.length, privateBytes);
          combined.setRange(privateBytes.length, combined.length, publicBytes);
          final paserkKey = K4SecretKey(combined);
          final identifier = K4Sid.fromKey(paserkKey);
          return identifier.toString();
        },
      );
    });
  }

  /// Restores an Ed25519 private key from PASERK k4.secret-pw representation.
  static Future<LicensifyPrivateKey> fromPaserkSecretPassword(
    String paserk,
    String password,
  ) async {
    final paserkKey = await K4SecretPw.unwrap(paserk, password);
    final rawBytes = paserkKey.rawBytes;
    final privateKeyBytes = Uint8List.fromList(rawBytes.sublist(0, 32));
    final publicKeyBytes = Uint8List.fromList(rawBytes.sublist(32));
    return LicensifyPrivateKey.ed25519(
      privateKeyBytes,
      publicKeyBytes: publicKeyBytes,
    );
  }

  /// Wraps this private key into PASERK k4.secret-pw representation using
  /// the matching [publicKey]. If [publicKey] is omitted, the cached public
  /// component will be used when available.
  Future<String> toPaserkSecretPassword(
    String password, {
    LicensifyPublicKey? publicKey,
    int memoryCost = K4SecretPw.defaultMemoryCost,
    int timeCost = K4SecretPw.defaultTimeCost,
    int parallelism = K4SecretPw.defaultParallelism,
  }) {
    return executeWithKeyBytesAsync((privateBytes) async {
      return _withPublicKeyBytesAsync(
        publicKey,
        (publicBytes) async {
          final combined =
              Uint8List(privateBytes.length + publicBytes.length);
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
        },
      );
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
      final rawBytes = secretKey.rawBytes;
      final privateKeyBytes = Uint8List.fromList(rawBytes.sublist(0, 32));
      final publicKeyBytes = Uint8List.fromList(rawBytes.sublist(32));
      return LicensifyPrivateKey.ed25519(
        privateKeyBytes,
        publicKeyBytes: publicKeyBytes,
      );
    });
  }

  /// Wraps this private key into PASERK k4.secret-wrap.pie using the matching
  /// [publicKey] and symmetric [wrappingKey]. If [publicKey] is omitted, the
  /// cached public component will be used when available.
  String toPaserkSecretWrap(
    LicensifySymmetricKey wrappingKey, {
    LicensifyPublicKey? publicKey,
  }) {
    return executeWithKeyBytes((privateBytes) {
      return _withPublicKeyBytes(
        publicKey,
        (publicBytes) {
          return wrappingKey.executeWithKeyBytes((wrappingBytes) {
            final combined =
                Uint8List(privateBytes.length + publicBytes.length);
            combined.setRange(0, privateBytes.length, privateBytes);
            combined.setRange(
                privateBytes.length, combined.length, publicBytes);
            final secretKey = K4SecretKey(combined);
            final wrapper = K4LocalKey(Uint8List.fromList(wrappingBytes));
            final wrapped = K4SecretWrap.wrap(secretKey, wrapper);
            return wrapped.toString();
          });
        },
      );
    });
  }

  T _withPublicKeyBytes<T>(
    LicensifyPublicKey? override,
    T Function(Uint8List publicBytes) operation,
  ) {
    if (override != null) {
      return override.executeWithKeyBytes((publicBytes) {
        return operation(publicBytes);
      });
    }

    final cached = _pairedPublicKeyBytes;
    if (cached != null) {
      final temp = Uint8List.fromList(cached);
      try {
        return operation(temp);
      } finally {
        LicensifyKey._zeroBytes(temp);
      }
    }

    throw StateError(
      'Public key bytes are required for PASERK secret conversions. '
      'Provide a publicKey explicitly or create this private key via '
      'LicensifyKeyPair to cache the paired public key.',
    );
  }

  Future<T> _withPublicKeyBytesAsync<T>(
    LicensifyPublicKey? override,
    Future<T> Function(Uint8List publicBytes) operation,
  ) async {
    if (override != null) {
      return await override.executeWithKeyBytesAsync((publicBytes) async {
        return await operation(publicBytes);
      });
    }

    final cached = _pairedPublicKeyBytes;
    if (cached != null) {
      final temp = Uint8List.fromList(cached);
      try {
        return await operation(temp);
      } finally {
        LicensifyKey._zeroBytes(temp);
      }
    }

    throw StateError(
      'Public key bytes are required for PASERK secret conversions. '
      'Provide a publicKey explicitly or create this private key via '
      'LicensifyKeyPair to cache the paired public key.',
    );
  }

  // Геттер licenseGenerator убран - используйте Licensify.createLicense() вместо него
}
