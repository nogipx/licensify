// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Implementation of license validator
///
/// This class validates license authenticity using RSA signatures
/// and checks license expiration dates.
class LicenseValidator implements ILicenseValidator {
  /// Public key for signature verification in PEM format
  final String _publicKey;

  /// Creates a new validator with the specified RSA public key
  const LicenseValidator({required String publicKey}) : _publicKey = publicKey;

  @override
  bool validateSignature(License license) {
    try {
      // Get rounded expiration date
      final roundedExpirationDate = license.expirationDate.roundToMinutes();

      // Serialize features and metadata for signature verification
      final featuresJson = jsonEncode(license.features);
      final metadataJson =
          license.metadata != null ? jsonEncode(license.metadata) : '';

      // Form data string for verification (including all fields)
      final dataToVerify =
          '${license.id}:${license.appId}:${roundedExpirationDate.toIso8601String()}:${license.type.name}:$featuresJson:$metadataJson';

      // Prepare the public key
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(_publicKey);

      // Decode signature from Base64
      final signatureBytes = base64Decode(license.signature);

      // Verify signature using RSA-SHA512
      final verifier = RSASigner(SHA512Digest(), '0609608648016503040203');
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      final signatureParams = Uint8List.fromList(utf8.encode(dataToVerify));
      return verifier.verifySignature(
        signatureParams,
        RSASignature(signatureBytes),
      );
    } catch (e) {
      print('Signature verification error: $e');
      return false;
    }
  }

  @override
  bool validateExpiration(License license) {
    // License is valid if expiration date hasn't passed
    return !license.isExpired;
  }

  @override
  ValidationResult validateSchema(License license, LicenseSchema schema) {
    // Use the schema's validateLicense method to validate the license
    return schema.validateLicense(license);
  }

  @override
  bool validateLicense(License license) {
    // License is valid if both signature is correct and it hasn't expired
    return validateSignature(license) && validateExpiration(license);
  }

  @override
  bool validateLicenseWithSchema(License license, LicenseSchema schema) {
    // First validate signature and expiration
    if (!validateLicense(license)) {
      return false;
    }

    // Then validate against the schema
    final schemaResult = validateSchema(license, schema);
    return schemaResult.isValid;
  }
}
