// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';
import 'package:uuid/uuid.dart';

/// Extension for DateTime to round to minutes
extension DateTimeUtils on DateTime {
  /// Rounds the DateTime to the nearest minute (zeroes seconds and milliseconds)
  DateTime roundToMinutes() {
    return DateTime.fromMillisecondsSinceEpoch(
      (millisecondsSinceEpoch ~/ 60000) * 60000,
      isUtc: isUtc,
    );
  }
}

/// Interface for PASETO license generator
abstract interface class IPasetoLicenseGenerator {
  /// Generates a new PASETO license
  Future<PasetoLicense> call({
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.standard,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
    bool isTrial = false,
  });
}

/// PASETO-based license generator
///
/// This class is responsible for creating cryptographically signed licenses
/// using PASETO v4.public tokens. This provides better security than traditional
/// signature schemes and follows modern cryptographic best practices.
class PasetoLicenseGenerator implements IPasetoLicenseGenerator {
  /// Private key for signing PASETO tokens
  final LicensifyPasetoPrivateKey _privateKey;

  /// Creates a new PASETO license generator with Ed25519 private key
  ///
  /// [privateKey] - Ed25519 private key for PASETO v4.public signing
  PasetoLicenseGenerator({required LicensifyPasetoPrivateKey privateKey})
      : _privateKey = privateKey {
    if (_privateKey.keyType != PasetoKeyType.ed25519Public) {
      throw ArgumentError(
        'PasetoLicenseGenerator requires Ed25519 private key for v4.public tokens',
      );
    }
  }

  /// Generates a new license with PASETO v4.public signature
  ///
  /// [appId] - Unique identifier of the application this license is for
  /// [expirationDate] - Date when the license expires
  /// [type] - License type (standard, pro or custom)
  /// [features] - Custom features map that can contain any application-specific parameters
  /// [metadata] - Optional metadata for the license (e.g., customer info)
  /// [isTrial] - Whether this is a trial license
  /// [footer] - Optional footer data for the PASETO token
  ///
  /// Returns a cryptographically signed PasetoLicense object
  @override
  Future<PasetoLicense> call({
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.standard,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
    bool isTrial = false,
    String? footer,
  }) async {
    final id = const Uuid().v4();

    // Round creation time to minutes for consistency
    final createdAt = DateTime.now().toUtc().roundToMinutes();

    // Convert expiration date to UTC and round to minutes
    final utcExpirationDate = expirationDate.toUtc().roundToMinutes();

    // Create PASETO payload following JWT-like structure
    final payload = {
      // Standard PASETO/JWT claims
      'sub': id, // Subject (license ID)
      'iat': createdAt.toIso8601String(), // Issued At
      'exp': utcExpirationDate.toIso8601String(), // Expiration
      'iss': 'licensify', // Issuer
      // Custom claims for license data
      'app_id': appId,
      'type': type.name,
      'features': features,
      'trial': isTrial,
    };

    // Add metadata if provided
    if (metadata != null && metadata.isNotEmpty) {
      payload['metadata'] = metadata;
    }

    try {
      // Sign the payload with PASETO v4.public
      final token = await PasetoV4.signPublic(
        payload: payload,
        privateKeyBytes: _privateKey.keyBytes,
        footer: footer,
      );

      // Create and return the PASETO license
      return PasetoLicense.fromValidatedPayload(token: token, payload: payload);
    } catch (e) {
      throw Exception('Failed to generate PASETO license: $e');
    }
  }

  /// Generates a license from existing payload data
  ///
  /// This is useful when you need to re-sign existing license data
  /// or when creating a license from validated payload.
  Future<PasetoLicense> fromPayload({
    required Map<String, dynamic> payload,
    String? footer,
  }) async {
    try {
      final token = await PasetoV4.signPublic(
        payload: payload,
        privateKeyBytes: _privateKey.keyBytes,
        footer: footer,
      );

      return PasetoLicense.fromValidatedPayload(token: token, payload: payload);
    } catch (e) {
      throw Exception('Failed to generate PASETO license from payload: $e');
    }
  }
}

/// Implementation of the license generator interface for backward compatibility
class LicensifyPasetoLicenseGenerator {
  final PasetoLicenseGenerator _generator;

  LicensifyPasetoLicenseGenerator._(this._generator);

  /// Creates an Ed25519-based PASETO license generator
  static LicensifyPasetoLicenseGenerator ed25519(
    LicensifyPasetoPrivateKey key,
  ) {
    return LicensifyPasetoLicenseGenerator._(
      PasetoLicenseGenerator(privateKey: key),
    );
  }

  /// Creates a symmetric key-based generator (currently not implemented)
  static LicensifyPasetoLicenseGenerator xchacha20(
    LicensifyPasetoPrivateKey key,
  ) {
    throw UnimplementedError(
      'XChaCha20 symmetric keys are not yet implemented for license generation. '
      'Use Ed25519 keys with v4.public instead.',
    );
  }

  /// Generates a new PASETO license
  Future<PasetoLicense> call({
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.standard,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
    bool isTrial = false,
    String? footer,
  }) =>
      _generator.call(
        appId: appId,
        expirationDate: expirationDate,
        type: type,
        features: features,
        metadata: metadata,
        isTrial: isTrial,
        footer: footer,
      );

  /// Generates a license from payload
  Future<PasetoLicense> fromPayload({
    required Map<String, dynamic> payload,
    String? footer,
  }) =>
      _generator.fromPayload(payload: payload, footer: footer);
}
