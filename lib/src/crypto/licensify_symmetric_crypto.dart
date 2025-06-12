// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of '_index.dart';

/// Combined handler for local symmetric cryptographic operations using PASETO v4.local
class _LicensifySymmetricCrypto {
  final LicensifySymmetricKey symmetricKey;

  const _LicensifySymmetricCrypto({required this.symmetricKey});

  /// Encrypts the given data as a license using PASETO v4.local
  ///
  /// This creates a properly formatted license with the given data and returns
  /// a PASETO v4.local token that can be safely transmitted or stored.
  ///
  /// - [licenseData]: The license data to encrypt (e.g., license claims)
  /// - [footer]: Optional footer data to include in the token
  /// - [implicitAssertion]: Optional implicit assertion data
  ///
  /// Returns: Encrypted PASETO v4.local token string
  Future<String> encrypt(
    Map<String, dynamic> licenseData, {
    String? footer,
    String? implicitAssertion,
  }) async {
    return await symmetricKey.executeWithKeyBytesAsync((keyBytes) async {
      try {
        return await _PasetoV4.encryptLocal(
          payload: licenseData,
          symmetricKeyBytes: keyBytes,
          footer: footer,
          implicitAssertion: implicitAssertion,
        );
      } catch (e) {
        throw Exception('Failed to encrypt license data: $e');
      }
    });
  }

  /// Decrypts a PASETO v4.local license token and returns the license data
  ///
  /// - [tokenString]: The PASETO v4.local token to decrypt
  /// - [implicitAssertion]: Optional implicit assertion data (must match encryption)
  ///
  /// Returns: Map containing decrypted license data and optional footer
  Future<Map<String, dynamic>> decrypt(
    String tokenString, {
    String? implicitAssertion,
  }) async {
    return await symmetricKey.executeWithKeyBytesAsync((keyBytes) async {
      try {
        final result = await _PasetoV4.decryptLocal(
          token: tokenString,
          symmetricKeyBytes: keyBytes,
          implicitAssertion: implicitAssertion,
        );

        // Include footer if present
        final payload = Map<String, dynamic>.from(result.payload);
        if (result.footer != null) {
          payload['_footer'] = result.footer;
        }

        return payload;
      } catch (e) {
        throw Exception('Failed to decrypt license token: $e');
      }
    });
  }

  /// Encrypts raw bytes using PASETO v4.local
  ///
  /// This is a lower-level method for encrypting arbitrary byte data
  /// without JSON serialization.
  ///
  /// - [data]: Raw bytes to encrypt
  /// - [footer]: Optional footer string
  /// - [implicitAssertion]: Optional implicit assertion string
  ///
  /// Returns: Encrypted PASETO v4.local token string
  Future<String> encryptBytes(
    List<int> data, {
    String? footer,
    String? implicitAssertion,
  }) async {
    return await symmetricKey.executeWithKeyBytesAsync((keyBytes) async {
      try {
        // Wrap raw bytes in a payload map
        final payload = {'data': base64.encode(data)};

        return await _PasetoV4.encryptLocal(
          payload: payload,
          symmetricKeyBytes: keyBytes,
          footer: footer,
          implicitAssertion: implicitAssertion,
        );
      } catch (e) {
        throw Exception('Failed to encrypt raw bytes: $e');
      }
    });
  }

  /// Decrypts a PASETO v4.local token and returns raw bytes
  ///
  /// This is a lower-level method for decrypting to arbitrary byte data
  /// without JSON deserialization.
  ///
  /// - [tokenString]: The PASETO v4.local token to decrypt
  /// - [implicitAssertion]: Optional implicit assertion string (must match encryption)
  ///
  /// Returns: List of decrypted bytes
  Future<List<int>> decryptBytes(
    String tokenString, {
    String? implicitAssertion,
  }) async {
    return await symmetricKey.executeWithKeyBytesAsync((keyBytes) async {
      try {
        final result = await _PasetoV4.decryptLocal(
          token: tokenString,
          symmetricKeyBytes: keyBytes,
          implicitAssertion: implicitAssertion,
        );

        // Extract and decode the data
        final encodedData = result.payload['data'] as String?;
        if (encodedData == null) {
          throw Exception('No data field found in decrypted payload');
        }

        return base64.decode(encodedData);
      } catch (e) {
        throw Exception('Failed to decrypt raw bytes: $e');
      }
    });
  }
}
