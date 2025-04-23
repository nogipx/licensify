// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

/// Use case for generating a new license
///
/// This class is responsible for creating cryptographically signed licenses.
/// It should only be used on the license issuer side, not in the client application.
class LicenseGenerator implements ILicenseGenerator {
  /// Private key for signing licenses
  final LicensifyPrivateKey _privateKey;

  /// Type of key being used
  final LicensifyKeyType _keyType;

  /// Hash algorithm used for signing
  final Digest _digest;

  /// Use case for signing data
  final ISignDataUseCase _signDataUseCase;

  /// Creates a new license generator with the specified private key
  ///
  /// [privateKey] - PEM-encoded private key (RSA or ECDSA)
  /// [digest] - Hash algorithm used for signature (default: SHA-512)
  /// [signDataUseCase] - Optional use case for signing data (default: SignDataUseCase())
  LicenseGenerator({
    required LicensifyPrivateKey privateKey,
    Digest? digest,
    ISignDataUseCase? signDataUseCase,
  }) : _privateKey = privateKey,
       _keyType = privateKey.keyType,
       _digest = digest ?? SHA512Digest(),
       _signDataUseCase = signDataUseCase ?? SignDataUseCase();

  /// Generates a new license with cryptographic signature
  ///
  /// [appId] - Unique identifier of the application this license is for
  /// [expirationDate] - Date when the license expires
  /// [type] - License type (standard, pro or custom)
  /// [features] - Custom features map that can contain any application-specific parameters
  /// [metadata] - Optional metadata for the license (e.g., customer info)
  /// [isTrial] - Whether this is a trial license
  /// [includeSecurityInfo] - Whether to include security algorithm info in metadata (not recommended in production)
  ///
  /// Returns a cryptographically signed License object
  @override
  License call({
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.standard,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
    bool isTrial = false,
    bool includeSecurityInfo = false,
  }) {
    if (_keyType == LicensifyKeyType.rsa) {
      throw UnsupportedError('RSA is deprecated');
    }

    final id = const Uuid().v4();

    // Round creation time to minutes for consistency
    final createdAt = DateTime.now().toUtc().roundToMinutes();

    // Convert expiration date to UTC and round to minutes
    final utcExpirationDate = expirationDate.toUtc().roundToMinutes();

    // Serialize features and metadata for signing
    final featuresJson = jsonEncode(features);
    final metadataJson = metadata != null ? jsonEncode(metadata) : '';

    // Form data string for signing (including all fields)
    final dataToSign =
        '$id:$appId:${utcExpirationDate.toIso8601String()}:${type.name}:$featuresJson:$metadataJson';

    // Generate the signature using the SignDataUseCase
    final signature = _signDataUseCase(
      data: dataToSign,
      privateKey: _privateKey,
      digest: _digest,
    );

    // Create a copy of metadata without modifying the original
    final extendedMetadata =
        metadata != null
            ? Map<String, dynamic>.from(metadata)
            : <String, dynamic>{};

    // Create the license
    return License(
      id: id,
      appId: appId,
      expirationDate: utcExpirationDate,
      createdAt: createdAt,
      signature: signature,
      type: type,
      features: features,
      metadata: extendedMetadata,
      isTrial: isTrial,
    );
  }
}
