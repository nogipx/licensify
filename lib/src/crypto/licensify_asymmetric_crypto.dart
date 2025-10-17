// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

part of 'package:licensify/licensify.dart';

/// Encapsulates the result of encrypting data for a recipient's public key.
///
/// The encrypted payload combines a sealed symmetric key (`k4.seal`) with the
/// actual PASETO `v4.local` token produced using that symmetric key. Consumers
/// can persist the entire object as JSON and later restore it via
/// [LicensifyAsymmetricEncryptedPayload.fromJson] before calling
/// [Licensify.decryptDataForKeyPair].
final class LicensifyAsymmetricEncryptedPayload {
  /// The encrypted PASETO `v4.local` token that contains the ciphertext.
  final String encryptedToken;

  /// PASERK `k4.seal` string carrying the symmetric key encrypted for the
  /// recipient's public key.
  final String sealedKey;

  /// Optional footer that was supplied during encryption. It remains stored in
  /// plaintext inside the PASETO token but is surfaced here for convenience
  /// when serialising the payload alongside metadata.
  final String? footer;

  const LicensifyAsymmetricEncryptedPayload({
    required this.encryptedToken,
    required this.sealedKey,
    this.footer,
  });

  /// Serialises the payload into a JSON-friendly structure.
  Map<String, dynamic> toJson() {
    return {
      'encryptedToken': encryptedToken,
      'sealedKey': sealedKey,
      if (footer != null) 'footer': footer,
    };
  }

  /// Restores a payload from a JSON map.
  factory LicensifyAsymmetricEncryptedPayload.fromJson(
    Map<String, dynamic> json,
  ) {
    final encryptedToken = json['encryptedToken'];
    final sealedKey = json['sealedKey'];
    final footer = json['footer'];

    if (encryptedToken is! String || encryptedToken.isEmpty) {
      throw ArgumentError(
        'encryptedToken must be a non-empty string in the JSON payload',
      );
    }
    if (sealedKey is! String || sealedKey.isEmpty) {
      throw ArgumentError(
        'sealedKey must be a non-empty string in the JSON payload',
      );
    }
    if (footer != null && footer is! String) {
      throw ArgumentError('footer must be a string when provided');
    }

    return LicensifyAsymmetricEncryptedPayload(
      encryptedToken: encryptedToken,
      sealedKey: sealedKey,
      footer: footer as String?,
    );
  }

  @override
  String toString() {
    final previewToken =
        encryptedToken.length > 16 ? '${encryptedToken.substring(0, 16)}…' : encryptedToken;
    final previewSeal =
        sealedKey.length > 16 ? '${sealedKey.substring(0, 16)}…' : sealedKey;
    return 'LicensifyAsymmetricEncryptedPayload(token: $previewToken, sealedKey: $previewSeal)';
  }
}

/// Handles asymmetric encryption flows built on top of PASERK `k4.seal`.
abstract final class _LicensifyAsymmetricCrypto {
  /// Encrypts [data] for the holder of [publicKey].
  static Future<LicensifyAsymmetricEncryptedPayload> encrypt({
    required Map<String, dynamic> data,
    required LicensifyPublicKey publicKey,
    String? footer,
    String? implicitAssertion,
  }) async {
    final symmetricKey = LicensifyKey.generateLocalKey();
    try {
      final crypto = _LicensifySymmetricCrypto(symmetricKey: symmetricKey);
      final token = await crypto.encrypt(
        data,
        footer: footer,
        implicitAssertion: implicitAssertion,
      );

      final sealedKey = await symmetricKey.toPaserkSeal(publicKey: publicKey);
      return LicensifyAsymmetricEncryptedPayload(
        encryptedToken: token,
        sealedKey: sealedKey,
        footer: footer,
      );
    } catch (e) {
      throw Exception('Failed to encrypt data for the provided public key: $e');
    } finally {
      symmetricKey.dispose();
    }
  }

  /// Decrypts a [payload] using the supplied [keyPair].
  static Future<Map<String, dynamic>> decrypt({
    required LicensifyAsymmetricEncryptedPayload payload,
    required LicensifyKeyPair keyPair,
    String? implicitAssertion,
  }) async {
    LicensifySymmetricKey? symmetricKey;
    try {
      symmetricKey = await LicensifySymmetricKey.fromPaserkSeal(
        paserk: payload.sealedKey,
        keyPair: keyPair,
      );

      final crypto = _LicensifySymmetricCrypto(symmetricKey: symmetricKey);
      return await crypto.decrypt(
        payload.encryptedToken,
        implicitAssertion: implicitAssertion,
      );
    } catch (e) {
      throw Exception('Failed to decrypt data with the supplied key pair: $e');
    } finally {
      symmetricKey?.dispose();
    }
  }
}
