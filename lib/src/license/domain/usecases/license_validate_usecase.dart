// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

class LicenseValidateUseCaseResult {
  final LicenseStatus status;

  const LicenseValidateUseCaseResult({required this.status});

  /// Returns true if the license is active and valid
  bool get isActive => status.isActive;

  /// Returns true if the license has expired
  bool get isExpired => status.isExpired;

  /// Returns true if no license is installed
  bool get isNoLicense => status.isNoLicense;

  /// Returns true if the license signature is invalid
  bool get isInvalidSignature => status.isInvalidSignature;

  /// Returns true if the license schema is invalid
  bool get isInvalidSchema => status.isInvalidSchema;

  /// Returns true if an error occurred during license validation
  bool get isError => status.isError;

  /// Returns the license object if available (for Active or Expired status)
  /// Returns null for other status types
  License? get license => status.license;

  /// Returns the schema validation result if available (for InvalidSchema status)
  /// Returns null for other status types
  SchemaValidationResult? get schemaValidationResult => switch (status) {
    InvalidLicenseSchemaStatus(:final schemaValidationResult) =>
      schemaValidationResult,
    _ => null,
  };

  @override
  String toString() =>
      'LicenseValidateUseCaseResult(status: $status, schemaValidationResult: $schemaValidationResult)';
}

/// Use case for checking license validity
///
/// This class handles verification of license status including signature
/// validation and expiration checks
class LicenseValidateUseCase {
  /// Validator for cryptographic signature and expiration
  final ILicenseValidator _validator;

  final LicenseSchema? _schema;

  /// Creates a new instance with the specified dependencies
  ///
  /// [repository] - Repository for license storage and retrieval
  /// [validator] - Validator for license integrity and expiration
  const LicenseValidateUseCase({
    required ILicenseValidator validator,
    LicenseSchema? schema,
  }) : _validator = validator,
       _schema = schema;

  /// Checks a license from binary data
  ///
  /// Saves the license from binary data and then verifies its validity.
  ///
  /// [licenseData] - The raw bytes of the license file
  ///
  /// Returns a LicenseStatus indicating the license state
  Future<LicenseValidateUseCaseResult> call(License? license) async {
    try {
      if (license == null) {
        return const LicenseValidateUseCaseResult(status: NoLicenseStatus());
      }

      final validationResult = _validator.validateLicense(license);
      if (!validationResult.isValid) {
        // Проверяем, истёк ли срок действия лицензии
        if (license.isExpired) {
          return LicenseValidateUseCaseResult(
            status: ExpiredLicenseStatus(license),
          );
        } else {
          // Если лицензия не истекла, значит проблема с подписью
          return LicenseValidateUseCaseResult(
            status: InvalidLicenseSignatureStatus(),
          );
        }
      }

      if (_schema != null) {
        final schemaValidationResult = _validator.validateSchema(
          license,
          _schema,
        );
        if (!schemaValidationResult.isValid) {
          return LicenseValidateUseCaseResult(
            status: InvalidLicenseSchemaStatus(schemaValidationResult),
          );
        }
      }

      return LicenseValidateUseCaseResult(status: ActiveLicenseStatus(license));
    } catch (e) {
      return LicenseValidateUseCaseResult(
        status: ErrorLicenseStatus(
          message: 'Error checking license from binary data',
          exception: e,
        ),
      );
    }
  }
}
