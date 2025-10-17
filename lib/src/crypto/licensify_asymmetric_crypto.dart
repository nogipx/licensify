// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

part of 'package:licensify/licensify.dart';

/// Handles asymmetric encryption flows built on top of PASERK `k4.seal`.
abstract final class _LicensifyAsymmetricCrypto {
  static const _footerSealedKeyField = 'sealedKey';
  static const _footerUserFooterField = 'footer';

  /// Encrypts [data] for the holder of [publicKey].
  static Future<String> encrypt({
    required Map<String, dynamic> data,
    required LicensifyPublicKey publicKey,
    String? footer,
    String? implicitAssertion,
  }) async {
    final symmetricKey = LicensifyKey.generateLocalKey();
    try {
      final crypto = _LicensifySymmetricCrypto(symmetricKey: symmetricKey);
      final sealedKey = await symmetricKey.toPaserkSeal(publicKey: publicKey);
      final token = await crypto.encrypt(
        data,
        footer: _encodeFooter(
          sealedKey: sealedKey,
          userFooter: footer,
        ),
        implicitAssertion: implicitAssertion,
      );
      return token;
    } catch (e) {
      throw Exception('Failed to encrypt data for the provided public key: $e');
    } finally {
      symmetricKey.dispose();
    }
  }

  /// Decrypts an [encryptedToken] using the supplied [keyPair].
  static Future<Map<String, dynamic>> decrypt({
    required String encryptedToken,
    required LicensifyKeyPair keyPair,
    String? implicitAssertion,
  }) async {
    LicensifySymmetricKey? symmetricKey;
    try {
      final footerInfo = await _extractFooter(encryptedToken);
      symmetricKey = await LicensifySymmetricKey.fromPaserkSeal(
        paserk: footerInfo.$1,
        keyPair: keyPair,
      );

      final crypto = _LicensifySymmetricCrypto(symmetricKey: symmetricKey);
      final decrypted = await crypto.decrypt(
        encryptedToken,
        implicitAssertion: implicitAssertion,
      );
      if (footerInfo.$2 != null) {
        decrypted['_footer'] = footerInfo.$2;
      } else {
        decrypted.remove('_footer');
      }
      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt data with the supplied key pair: $e');
    } finally {
      symmetricKey?.dispose();
    }
  }

  static String _encodeFooter({
    required String sealedKey,
    String? userFooter,
  }) {
    final footer = <String, dynamic>{
      _footerSealedKeyField: sealedKey,
      if (userFooter != null) _footerUserFooterField: userFooter,
    };
    return jsonEncode(footer);
  }

  static Future<(String, String?)> _extractFooter(String encryptedToken) async {
    try {
      final token = await Token.fromString(encryptedToken);
      if (token.header != LocalV4.header) {
        throw Exception('Token is not v4.local format');
      }

      final footerBytes = token.footer;
      if (footerBytes == null) {
        throw Exception('Encrypted token footer is missing the sealed key');
      }

      final footerString = utf8.decode(footerBytes);
      final decoded = jsonDecode(footerString);
      if (decoded is! Map) {
        throw Exception('Encrypted token footer must decode to a JSON object');
      }

      final sealedKey = decoded[_footerSealedKeyField];
      if (sealedKey is! String || sealedKey.isEmpty) {
        throw Exception('Encrypted token footer is missing the sealedKey');
      }

      final userFooter = decoded[_footerUserFooterField];
      if (userFooter != null && userFooter is! String) {
        throw Exception('Encrypted token footer value must be a string when set');
      }

      return (sealedKey, userFooter as String?);
    } catch (e) {
      throw Exception('Failed to parse encrypted token footer: $e');
    }
  }
}
