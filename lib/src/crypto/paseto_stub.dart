// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'paseto_implementation.dart';

/// Real PASETO v4 implementation - no longer a stub!
///
/// This now provides actual cryptographic security using paseto_dart library.
/// Supports both v4.public (signatures) and v4.local (encryption).
abstract interface class PasetoV4 {
  /// Signs a PASETO v4.public token with Ed25519
  static Future<String> signPublic({
    required Map<String, dynamic> payload,
    required Uint8List privateKeyBytes,
    String? footer,
    String? implicitAssertion,
  }) async {
    return await PasetoV4Implementation.signPublic(
      payload: payload,
      privateKeyBytes: privateKeyBytes,
      footer: footer,
      implicitAssertion: implicitAssertion,
    );
  }

  /// Verifies a PASETO v4.public token
  static Future<PasetoImplementationResult> verifyPublic({
    required String token,
    required Uint8List publicKeyBytes,
    String? footer,
    String? implicitAssertion,
  }) async {
    return await PasetoV4Implementation.verifyPublic(
      token: token,
      publicKeyBytes: publicKeyBytes,
      footer: footer,
      implicitAssertion: implicitAssertion,
    );
  }

  /// Encrypts a PASETO v4.local token with XChaCha20
  static Future<String> encryptLocal({
    required Map<String, dynamic> payload,
    required Uint8List symmetricKeyBytes,
    String? footer,
    String? implicitAssertion,
  }) async {
    return await PasetoV4Implementation.encryptLocal(
      payload: payload,
      symmetricKeyBytes: symmetricKeyBytes,
      footer: footer,
      implicitAssertion: implicitAssertion,
    );
  }

  /// Decrypts a PASETO v4.local token
  static Future<PasetoImplementationResult> decryptLocal({
    required String token,
    required Uint8List symmetricKeyBytes,
    String? footer,
    String? implicitAssertion,
  }) async {
    return await PasetoV4Implementation.decryptLocal(
      token: token,
      symmetricKeyBytes: symmetricKeyBytes,
      footer: footer,
      implicitAssertion: implicitAssertion,
    );
  }

  /// Generates a new Ed25519 key pair for v4.public
  static Future<Map<String, Uint8List>> generateEd25519KeyPair() async {
    return await PasetoV4Implementation.generateEd25519KeyPair();
  }

  /// Generates a random symmetric key for v4.local (32 bytes)
  static Uint8List generateSymmetricKey() {
    return PasetoV4Implementation.generateSymmetricKey();
  }
}

/// Result of PASETO token verification (legacy format for backward compatibility)
class PasetoVerificationResult {
  final bool isValid;
  final Map<String, dynamic> payload;

  const PasetoVerificationResult({
    required this.isValid,
    required this.payload,
  });
}
