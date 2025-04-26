// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Implementation of license validator
///
/// This class validates license authenticity using cryptographic signatures
/// and checks license expiration dates.
class LicenseValidator implements ILicenseValidator {
  /// Public key for signature verification in PEM format
  final LicensifyPublicKey _publicKey;

  /// Type of key being used
  final LicensifyKeyType _keyType;

  /// Hash algorithm used for signature verification
  final Digest _digest;

  /// Use case for verifying signatures
  final IVerifySignatureUseCase _verifySignatureUseCase;

  /// Creates a new validator with the specified public key
  ///
  /// [publicKey] - PEM-encoded public key (RSA or ECDSA)
  /// [digest] - Hash algorithm used for verification (default: SHA-512)
  /// [verifySignatureUseCase] - Optional use case for signature verification (default: VerifySignatureUseCase())
  LicenseValidator({
    required LicensifyPublicKey publicKey,
    Digest? digest,
    IVerifySignatureUseCase? verifySignatureUseCase,
  }) : _publicKey = publicKey,
       _keyType = publicKey.keyType,
       _digest = digest ?? SHA512Digest(),
       _verifySignatureUseCase =
           verifySignatureUseCase ?? VerifySignatureUseCase();

  @override
  ValidationResult call(License license, {LicenseSchema? schema}) {
    _checkKeyType();

    // First validate signature and expiration
    // Validate signature
    final signatureResult = validateSignature(license);
    if (!signatureResult.isValid) {
      return signatureResult;
    }

    // If signature is valid, validate expiration
    final expirationResult = validateExpiration(license);
    if (!expirationResult.isValid) {
      return expirationResult;
    }

    if (schema != null) {
      // Then validate against the schema
      final schemaResult = validateSchema(license, schema);
      return ValidationResult(
        isValid: schemaResult.isValid,
        message: schemaResult.errorMessage ?? '',
      );
    }

    return ValidationResult(isValid: true);
  }

  @override
  ValidationResult validateExpiration(License license) {
    _checkKeyType();
    // License is valid if expiration date hasn't passed
    final isValid = !license.isExpired;
    return ValidationResult(
      isValid: isValid,
      message: isValid ? '' : 'License expired ${license.expirationDate}',
    );
  }

  @override
  SchemaValidationResult validateSchema(License license, LicenseSchema schema) {
    _checkKeyType();
    // Use the schema's validateLicense method to validate the license
    return schema.validateLicense(license);
  }

  @override
  ValidationResult validateSignature(License license) {
    _checkKeyType();
    try {
      // Get rounded expiration date - this should trim to minutes only
      final roundedExpirationDate = license.expirationDate.roundToMinutes();

      // Serialize features and metadata for signature verification
      final basicMetadata = _removeServiceFields(license.metadata ?? {});
      final featuresJson = jsonEncode(license.features);
      final metadataJson =
          basicMetadata.isNotEmpty ? jsonEncode(basicMetadata) : '';

      // Form data string for verification (including all fields)
      // Using the rounded date for consistent signature verification
      final dataToVerify =
          '${license.id}:${license.appId}:${roundedExpirationDate.toIso8601String()}:${license.type.name}:$featuresJson:$metadataJson';

      // Verify signature using the VerifySignatureUseCase
      final isValid = _verifySignatureUseCase(
        data: dataToVerify,
        signature: license.signature,
        publicKey: _publicKey,
        digest: _digest,
      );

      return ValidationResult(
        isValid: isValid,
        message: isValid ? '' : 'Invalid signature',
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        message: 'Signature verification error: $e',
      );
    }
  }

  void _checkKeyType() {
    if (_keyType == LicensifyKeyType.rsa) {
      throw UnsupportedError('RSA is deprecated');
    }
  }

  /// Removes service fields from metadata for signature verification
  Map<String, dynamic> _removeServiceFields(Map<String, dynamic> metadata) {
    final result = Map<String, dynamic>.from(metadata);
    result.remove('keyAlgorithm');
    result.remove('curve');
    return result;
  }
}
