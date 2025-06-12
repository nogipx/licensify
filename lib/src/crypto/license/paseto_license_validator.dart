// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Interface for PASETO license validator
abstract interface class IPasetoLicenseValidator {
  /// Validates the complete license (signature and expiration)
  Future<ValidationResult> validate(PasetoLicense license);

  /// Validates only the cryptographic signature of the license
  Future<ValidationResult> validateSignature(PasetoLicense license);

  /// Validates only the expiration date of the license
  ValidationResult validateExpiration(PasetoLicense license);
}

/// PASETO-based license validator
///
/// This class validates license authenticity using PASETO v4.public tokens
/// and checks license expiration dates. It provides better security than
/// traditional signature verification.
class PasetoLicenseValidator implements IPasetoLicenseValidator {
  /// Public key for signature verification
  final LicensifyPasetoPublicKey _publicKey;

  /// Creates a new PASETO validator with Ed25519 public key
  ///
  /// [publicKey] - Ed25519 public key for PASETO v4.public verification
  PasetoLicenseValidator({required LicensifyPasetoPublicKey publicKey})
      : _publicKey = publicKey {
    if (_publicKey.keyType != PasetoKeyType.ed25519Public) {
      throw ArgumentError(
        'PasetoLicenseValidator requires Ed25519 public key for v4.public tokens',
      );
    }
  }

  /// Validates the complete license (signature and expiration)
  ///
  /// This method performs:
  /// 1. PASETO token signature verification
  /// 2. Token structure validation
  /// 3. Expiration date check
  ///
  /// Returns [ValidationResult] with validation status and message
  @override
  Future<ValidationResult> validate(PasetoLicense license) async {
    try {
      // First validate the signature and extract payload
      final signatureResult = await validateSignature(license);
      if (!signatureResult.isValid) {
        return signatureResult;
      }

      // Then validate expiration
      final expirationResult = validateExpiration(license);
      if (!expirationResult.isValid) {
        return expirationResult;
      }

      return const ValidationResult(isValid: true, message: 'License is valid');
    } catch (e) {
      return ValidationResult(
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
  /// 3. Updates the license with validated payload
  ///
  /// Returns [ValidationResult] with validation status
  @override
  Future<ValidationResult> validateSignature(PasetoLicense license) async {
    try {
      // Verify the PASETO token and extract payload
      final result = await PasetoV4.verifyPublic(
        token: license.token,
        publicKeyBytes: _publicKey.keyBytes,
      );

      // If verification succeeded, we have the result
      // (If verification failed, an exception would have been thrown)

      // Validate payload structure
      final payload = result.payload;
      final validationError = _validatePayloadStructure(payload);
      if (validationError != null) {
        return ValidationResult(
          isValid: false,
          message: 'Invalid payload structure: $validationError',
        );
      }

      // Update the license with validated payload
      license.updatePayload(payload);

      return const ValidationResult(isValid: true, message: 'Valid signature');
    } catch (e) {
      return ValidationResult(
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
  /// Returns [ValidationResult] with validation status
  @override
  ValidationResult validateExpiration(PasetoLicense license) {
    try {
      if (license.isExpired) {
        return ValidationResult(
          isValid: false,
          message:
              'License expired on ${license.expirationDate.toIso8601String()}',
        );
      }

      return const ValidationResult(
        isValid: true,
        message: 'License not expired',
      );
    } catch (e) {
      return ValidationResult(
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

/// Implementation wrapper for backward compatibility
class LicensifyPasetoLicenseValidator {
  final PasetoLicenseValidator _validator;

  LicensifyPasetoLicenseValidator(LicensifyPasetoPublicKey publicKey)
      : _validator = PasetoLicenseValidator(publicKey: publicKey);

  /// Validates the complete license
  Future<ValidationResult> validate(PasetoLicense license) =>
      _validator.validate(license);

  /// Validates only the signature
  Future<ValidationResult> validateSignature(PasetoLicense license) =>
      _validator.validateSignature(license);

  /// Validates only the expiration
  ValidationResult validateExpiration(PasetoLicense license) =>
      _validator.validateExpiration(license);
}
