// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of 'package:licensify/licensify.dart';

/// Interface for PASETO license validator
abstract interface class ILicenseValidator {
  /// Validates a license token and returns a validated license
  Future<License> validateToken(String token);

  /// Validates the complete license (signature and expiration)
  Future<LicenseValidationResult> validate(License license);

  /// Validates only the cryptographic signature of the license
  Future<LicenseValidationResult> validateSignature(License license);

  /// Validates only the expiration date of the license
  Future<LicenseValidationResult> validateExpiration(License license);
}

/// PASETO-based license validator
///
/// This class validates license authenticity using PASETO v4.public tokens
/// and checks license expiration dates. It provides better security than
/// traditional signature verification.
class _LicenseValidator implements ILicenseValidator {
  /// Public key for signature verification
  final LicensifyPublicKey _publicKey;

  /// Creates a new PASETO validator with Ed25519 public key
  ///
  /// [publicKey] - Ed25519 public key for PASETO v4.public verification
  _LicenseValidator({required LicensifyPublicKey publicKey})
      : _publicKey = publicKey {
    if (_publicKey.keyType != LicensifyKeyType.ed25519Public) {
      throw ArgumentError(
        'Paseto_LicenseValidator requires Ed25519 public key for v4.public tokens',
      );
    }
  }

  /// Validates a license token and returns a validated license
  ///
  /// This method:
  /// 1. Verifies the PASETO v4.public token signature
  /// 2. Validates payload structure and expiration
  /// 3. Returns a new License object with validated data
  ///
  /// Throws an exception if validation fails
  @override
  Future<License> validateToken(String token) async {
    // Verify the PASETO token and extract payload
    final result = await _PasetoV4.verifyPublic(
      token: token,
      publicKeyBytes: _publicKey.keyBytes,
    );

    // Validate payload structure
    final payload = result.payload;
    final validationError = _validatePayloadStructure(payload);
    if (validationError != null) {
      throw Exception('Invalid payload structure: $validationError');
    }

    // Create validated license
    final license = License._from(token, payload);

    // Check expiration
    if (await license.isExpired) {
      final expDate = await license.expirationDate;
      throw Exception('License expired on ${expDate.toIso8601String()}');
    }

    return license;
  }

  /// Validates the complete license (signature and expiration)
  ///
  /// This method performs:
  /// 1. PASETO token signature verification
  /// 2. Token structure validation
  /// 3. Expiration date check
  ///
  /// Returns [LicenseValidationResult] with validation status and message
  @override
  Future<LicenseValidationResult> validate(License license) async {
    try {
      // First validate the signature and extract payload
      final signatureResult = await validateSignature(license);
      if (!signatureResult.isValid) {
        return signatureResult;
      }

      // Then validate expiration
      final expirationResult = await validateExpiration(license);
      if (!expirationResult.isValid) {
        return expirationResult;
      }

      return const LicenseValidationResult(
          isValid: true, message: 'License is valid');
    } catch (e) {
      return LicenseValidationResult(
        isValid: false,
        message: 'License validation error: $e',
      );
    }
  }

  /// Validates only the cryptographic signature of the license
  ///
  /// This method:
  /// 1. Verifies the PASETO v4.public token signature
  /// 2. Extracts and validates the payload structure
  ///
  /// Returns [LicenseValidationResult] with validation status
  /// Note: This method assumes the license already has validated payload
  @override
  Future<LicenseValidationResult> validateSignature(License license) async {
    try {
      // Verify the PASETO token and extract payload
      final result = await _PasetoV4.verifyPublic(
        token: license.token,
        publicKeyBytes: _publicKey.keyBytes,
      );

      // If verification succeeded, we have the result
      // (If verification failed, an exception would have been thrown)

      // Validate payload structure
      final payload = result.payload;
      final validationError = _validatePayloadStructure(payload);
      if (validationError != null) {
        return LicenseValidationResult(
          isValid: false,
          message: 'Invalid payload structure: $validationError',
        );
      }

      return const LicenseValidationResult(
          isValid: true, message: 'Valid signature');
    } catch (e) {
      return LicenseValidationResult(
        isValid: false,
        message: 'Signature verification error: $e',
      );
    }
  }

  /// Validates only the expiration date of the license
  ///
  /// This method checks if the license has expired based on the 'exp' claim
  /// in the PASETO payload.
  ///
  /// Returns [LicenseValidationResult] with validation status
  @override
  Future<LicenseValidationResult> validateExpiration(License license) async {
    try {
      if (await license.isExpired) {
        final expDate = await license.expirationDate;
        return LicenseValidationResult(
          isValid: false,
          message: 'License expired on ${expDate.toIso8601String()}',
        );
      }

      return const LicenseValidationResult(
        isValid: true,
        message: 'License not expired',
      );
    } catch (e) {
      return LicenseValidationResult(
        isValid: false,
        message: 'Expiration validation error: $e',
      );
    }
  }

  /// Validates the structure of the PASETO payload
  ///
  /// Ensures all required fields are present and have correct types
  String? _validatePayloadStructure(Map<String, dynamic> payload) {
    // Check required fields
    if (payload['sub'] == null || payload['sub'] is! String) {
      return 'Missing or invalid "sub" (license ID) field';
    }

    if (payload['app_id'] == null || payload['app_id'] is! String) {
      return 'Missing or invalid "app_id" field';
    }

    if (payload['exp'] == null || payload['exp'] is! String) {
      return 'Missing or invalid "exp" (expiration) field';
    }

    if (payload['iat'] == null || payload['iat'] is! String) {
      return 'Missing or invalid "iat" (issued at) field';
    }

    if (payload['type'] == null || payload['type'] is! String) {
      return 'Missing or invalid "type" field';
    }

    // Validate datetime fields
    try {
      DateTime.parse(payload['exp'] as String);
    } catch (e) {
      return 'Invalid expiration date format: ${payload['exp']}';
    }

    try {
      DateTime.parse(payload['iat'] as String);
    } catch (e) {
      return 'Invalid issued at date format: ${payload['iat']}';
    }

    // Validate optional fields if present
    if (payload['features'] != null && payload['features'] is! Map) {
      return 'Invalid "features" field - must be a map';
    }

    if (payload['metadata'] != null && payload['metadata'] is! Map) {
      return 'Invalid "metadata" field - must be a map';
    }

    if (payload['trial'] != null && payload['trial'] is! bool) {
      return 'Invalid "trial" field - must be boolean';
    }

    return null; // No validation errors
  }
}
