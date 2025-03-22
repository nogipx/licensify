// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

/// Use case for generating a new license
///
/// This class is responsible for creating cryptographically signed licenses.
/// It should only be used on the license issuer side, not in the client application.
class GenerateLicenseUseCase {
  /// Private key for signing licenses
  final String _privateKey;

  /// Creates a new license generator with the specified RSA private key
  ///
  /// The private key must be in PEM format
  const GenerateLicenseUseCase({required String privateKey})
    : _privateKey = privateKey;

  /// Generates a new license with RSA signature
  ///
  /// [appId] - Unique identifier of the application this license is for
  /// [expirationDate] - Date when the license expires
  /// [type] - License type (trial, standard, pro)
  /// [features] - Custom features map that can contain any application-specific parameters
  /// [metadata] - Optional metadata for the license (e.g., customer info)
  ///
  /// Returns a cryptographically signed License object
  License generateLicense({
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.trial,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
  }) {
    final id = const Uuid().v4();

    // Round creation time to minutes for consistency
    final createdAt = DateTime.now().toUtc().roundToMinutes();

    // Convert expiration date to UTC and round to minutes
    final utcExpirationDate = expirationDate.roundToMinutes();

    // Serialize features and metadata for signing
    final featuresJson = jsonEncode(features);
    final metadataJson = metadata != null ? jsonEncode(metadata) : '';

    // Form data string for signing (including all fields)
    final dataToSign =
        '$id:$appId:${utcExpirationDate.toIso8601String()}:${type.name}:$featuresJson:$metadataJson';

    // Create RSA signature with the private key
    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(_privateKey);
    final signer = RSASigner(SHA512Digest(), '0609608648016503040203');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signatureBytes = signer.generateSignature(
      Uint8List.fromList(utf8.encode(dataToSign)),
    );
    final signature = base64Encode(signatureBytes.bytes);

    // Create the license
    return License(
      id: id,
      appId: appId,
      expirationDate: utcExpirationDate,
      createdAt: createdAt,
      signature: signature,
      type: type,
      features: features,
      metadata: metadata,
    );
  }
}
