// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

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

  /// Creates a new validator with the specified public key
  ///
  /// [publicKey] - PEM-encoded public key (RSA or ECDSA)
  /// [digest] - Hash algorithm used for verification (default: SHA-512)
  LicenseValidator({required LicensifyPublicKey publicKey, Digest? digest})
    : _publicKey = publicKey,
      _keyType = publicKey.keyType,
      _digest = digest ?? SHA512Digest();

  @override
  ValidationResult call(License license, {LicenseSchema? schema}) {
    if (_keyType == LicensifyKeyType.rsa) {
      throw UnsupportedError('RSA is deprecated');
    }

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
    // License is valid if expiration date hasn't passed
    final isValid = !license.isExpired;
    return ValidationResult(
      isValid: isValid,
      message: isValid ? '' : 'License expired ${license.expirationDate}',
    );
  }

  @override
  SchemaValidationResult validateSchema(License license, LicenseSchema schema) {
    // Use the schema's validateLicense method to validate the license
    return schema.validateLicense(license);
  }

  @override
  ValidationResult validateSignature(License license) {
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

      // Try to verify ECDSA signature
      bool isValid;
      try {
        isValid = _verifyEcdsaSignature(dataToVerify, license.signature);
      } catch (_) {
        isValid = false;
      }

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

  /// Removes service fields from metadata for signature verification
  Map<String, dynamic> _removeServiceFields(Map<String, dynamic> metadata) {
    final result = Map<String, dynamic>.from(metadata);
    result.remove('keyAlgorithm');
    result.remove('curve');
    return result;
  }

  /// Verifies ECDSA signature
  bool _verifyEcdsaSignature(String dataToVerify, String signature) {
    try {
      // Prepare the ECDSA public key
      final publicKey = CryptoUtils.ecPublicKeyFromPem(_publicKey.content);

      // Decode DER-encoded signature from Base64
      final derSignature = base64Decode(signature);

      // Parse DER signature bytes into ECSignature
      final ecSignature = _decodeEcSignature(derSignature);

      // Choose the appropriate hashing algorithm for the data
      final digest = _digest;
      final dataBytes = Uint8List.fromList(utf8.encode(dataToVerify));
      final hashedData = digest.process(dataBytes);

      // Create ECDSA verifier directly
      final verifier = ECDSASigner(digest);
      final params = PublicKeyParameter<ECPublicKey>(publicKey);
      verifier.init(false, params);

      // Verify signature
      return verifier.verifySignature(hashedData, ecSignature);
    } catch (e) {
      print('ECDSA verification error: $e');
      rethrow;
    }
  }

  /// Decodes DER-format ECDSA signature into ECSignature
  ECSignature _decodeEcSignature(Uint8List derBytes) {
    try {
      // Ensure it starts with SEQUENCE
      if (derBytes.length < 2 || derBytes[0] != 0x30) {
        throw Exception('Expected SEQUENCE tag at start of DER');
      }

      int index = 2; // Skip SEQUENCE tag (0x30) and length

      // First INTEGER (r)
      if (derBytes.length <= index || derBytes[index] != 0x02) {
        throw Exception('Expected INTEGER tag for r');
      }
      index++;

      // Get r length
      final rLength = derBytes[index];
      index++;

      if (derBytes.length < index + rLength) {
        throw Exception('DER data too short for r value');
      }

      // Extract r bytes
      final rBytes = derBytes.sublist(index, index + rLength);
      index += rLength;

      // Second INTEGER (s)
      if (derBytes.length <= index || derBytes[index] != 0x02) {
        throw Exception('Expected INTEGER tag for s');
      }
      index++;

      // Get s length
      final sLength = derBytes[index];
      index++;

      if (derBytes.length < index + sLength) {
        throw Exception('DER data too short for s value');
      }

      // Extract s bytes
      final sBytes = derBytes.sublist(index, index + sLength);

      // Convert bytes to BigInt
      final r = _decodeBigInt(rBytes);
      final s = _decodeBigInt(sBytes);

      return ECSignature(r, s);
    } catch (e) {
      throw Exception('Failed to decode ECDSA signature: $e');
    }
  }

  /// Decodes bytes to BigInt, accounting for DER positive number representation
  BigInt _decodeBigInt(Uint8List bytes) {
    // If first byte is 0, it was added for positive representation in DER
    if (bytes.length > 1 && bytes[0] == 0) {
      bytes = bytes.sublist(1);
    }

    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }
}
