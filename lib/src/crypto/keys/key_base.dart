// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of '../_index.dart';

/// PASETO key type
enum LicensifyKeyType {
  /// Ed25519 keys for PASETO v4.public (signatures)
  ed25519Public,

  /// XChaCha20 symmetric keys for PASETO v4.local (encryption)
  xchacha20Local,
}

/// Base class for PASETO cryptographic keys with security measures
sealed class LicensifyKey {
  /// Raw key bytes (mutable for security zeroing)
  final Uint8List _keyBytes;

  /// Type of the PASETO key
  final LicensifyKeyType keyType;

  /// Whether this key has been securely disposed
  bool _isDisposed = false;

  LicensifyKey({required Uint8List keyBytes, required this.keyType})
      : _keyBytes = Uint8List.fromList(keyBytes); // Create defensive copy

  /// Gets key bytes (creates a copy to prevent modification of original)
  ///
  /// ⚠️ WARNING: The returned bytes should be used immediately and then zeroed.
  /// Consider using [executeWithKeyBytes] for automatic cleanup.
  Uint8List get keyBytes {
    _ensureNotDisposed();
    return Uint8List.fromList(_keyBytes); // Return defensive copy
  }

  /// Executes a function with key bytes and automatically zeros them afterward
  ///
  /// This is the PREFERRED way to access key bytes safely.
  ///
  /// Example:
  /// ```dart
  /// final result = await key.executeWithKeyBytes((keyBytes) async {
  ///   return await someEncryptionFunction(keyBytes);
  /// });
  /// ```
  R executeWithKeyBytes<R>(R Function(Uint8List keyBytes) operation) {
    _ensureNotDisposed();

    // Create temporary copy
    final tempKeyBytes = Uint8List.fromList(_keyBytes);

    try {
      return operation(tempKeyBytes);
    } finally {
      // Zero the temporary copy
      _zeroBytes(tempKeyBytes);
    }
  }

  /// Executes an async function with key bytes and automatically zeros them
  Future<R> executeWithKeyBytesAsync<R>(
    Future<R> Function(Uint8List keyBytes) operation,
  ) async {
    _ensureNotDisposed();

    // Create temporary copy
    final tempKeyBytes = Uint8List.fromList(_keyBytes);

    try {
      return await operation(tempKeyBytes);
    } finally {
      // Zero the temporary copy
      _zeroBytes(tempKeyBytes);
    }
  }

  /// Securely disposes of the key by zeroing its bytes
  ///
  /// ⚠️ After calling this method, the key becomes unusable.
  /// Any attempt to use it will throw [StateError].
  void dispose() {
    if (!_isDisposed) {
      _zeroBytes(_keyBytes);
      _isDisposed = true;
    }
  }

  /// Whether this key has been disposed
  bool get isDisposed => _isDisposed;

  /// Length of the key in bytes (safe to call even after disposal)
  int get keyLength => _keyBytes.length;

  /// Ensures the key hasn't been disposed
  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot use disposed key. Key bytes have been securely zeroed.',
      );
    }
  }

  /// Securely zeros the given byte array
  static void _zeroBytes(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }

  @override
  String toString() =>
      'LicensifyKey(type: $keyType, length: ${keyLength}bytes, disposed: $_isDisposed)';

  /// Generates a new Ed25519 key pair for PASETO v4.public operations
  static Future<LicensifyKeyPair> generatePublicKeyPair() async {
    try {
      // Delegate to _PasetoV4 for actual key generation
      final keyBytes = await _PasetoV4.generateEd25519KeyPair();

      // Create our wrapper keys
      final privateKey = LicensifyPrivateKey.ed25519(keyBytes['privateKey']!);
      final publicKey = LicensifyPublicKey.ed25519(keyBytes['publicKey']!);

      return LicensifyKeyPair(
        privateKey: privateKey,
        publicKey: publicKey,
      );
    } catch (e) {
      throw Exception('Failed to generate Ed25519 key pair: $e');
    }
  }

  /// Generates a new symmetric key for PASETO v4.local operations
  static LicensifySymmetricKey generateLocalKey() {
    try {
      // Delegate to _PasetoV4 for symmetric key generation
      final keyBytes = _PasetoV4.generateSymmetricKey();
      return LicensifySymmetricKey.xchacha20(keyBytes);
    } catch (e) {
      throw Exception('Failed to generate symmetric key: $e');
    }
  }
}

/// Secure wrapper for key operations with automatic cleanup
///
/// This class provides a safer interface for using cryptographic keys
/// by automatically managing their lifecycle and providing secure operations.
class _SecureLicensifyOperations {
  /// Performs license validation with automatic key cleanup
  ///
  /// The public key will be automatically disposed after validation.
  static Future<LicenseValidationResult> validateLicenseSecurely({
    required License license,
    required LicensifyPublicKey publicKey,
  }) async {
    try {
      final validator = _LicenseValidator(publicKey: publicKey);
      return await validator.validate(license);
    } finally {
      // Always dispose key after use
      publicKey.dispose();
    }
  }
}

/// Mixin for automatic key disposal
mixin AutoDisposable on LicensifyKey {
  /// Automatically dispose when the object is garbage collected
  ///
  /// Note: This is not guaranteed to be called immediately, but provides
  /// a safety net for forgotten manual disposal.
  @pragma('vm:notify-debugger-on-pause')
  // ignore: unused_element
  void _autoDispose() {
    if (!isDisposed) {
      dispose();
      // In debug mode, log potential memory leaks
      assert(() {
        print('⚠️ Key was auto-disposed during garbage collection. '
            'Consider calling dispose() manually for better security.');
        return true;
      }());
    }
  }
}
