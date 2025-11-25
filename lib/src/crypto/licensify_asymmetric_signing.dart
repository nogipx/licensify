// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

part of 'package:licensify/licensify.dart';

/// Handles PASETO v4.public signing and verification for arbitrary payloads.
abstract final class _LicensifyAsymmetricSigning {
  /// Signs a JSON payload into a PASETO v4.public token.
  static Future<String> sign({
    required Map<String, dynamic> payload,
    required LicensifyPrivateKey privateKey,
    String? footer,
    String? implicitAssertion,
  }) async {
    if (privateKey.keyType != LicensifyKeyType.ed25519Public) {
      throw ArgumentError(
        'Licensify.signPublicToken requires an Ed25519 private key',
      );
    }

    return await privateKey.executeWithKeyBytesAsync((keyBytes) async {
      _PasetoV4.validateEd25519KeyBytes(keyBytes, 'private key');
      return await _PasetoV4.signPublic(
        payload: payload,
        privateKeyBytes: keyBytes,
        footer: footer,
        implicitAssertion: implicitAssertion,
      );
    });
  }

  /// Verifies a PASETO v4.public token and returns the decoded payload/footer.
  static Future<Map<String, dynamic>> verify({
    required String token,
    required LicensifyPublicKey publicKey,
    String? implicitAssertion,
  }) async {
    if (publicKey.keyType != LicensifyKeyType.ed25519Public) {
      throw ArgumentError(
        'Licensify.verifyPublicToken requires an Ed25519 public key',
      );
    }

    final result = await publicKey.executeWithKeyBytesAsync((keyBytes) async {
      _PasetoV4.validateEd25519KeyBytes(keyBytes, 'public key');
      return await _PasetoV4.verifyPublic(
        token: token,
        publicKeyBytes: keyBytes,
        implicitAssertion: implicitAssertion,
      );
    });

    final payload = Map<String, dynamic>.from(result.payload);
    if (result.footer != null) {
      payload['_footer'] = result.footer;
    }
    return payload;
  }
}
