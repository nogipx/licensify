// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

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
  Future<LicenseStatus> call(License? license) async {
    try {
      if (license == null) {
        return const NoLicenseStatus();
      }

      if (!_validator.validateSignature(license)) {
        return const InvalidLicenseStatus(message: 'Invalid license signature');
      }

      if (!_validator.validateExpiration(license)) {
        return ExpiredLicenseStatus(license);
      }

      if (_schema != null) {
        final result = _schema.validateLicense(license);
        if (!result.isValid) {
          return InvalidLicenseSchemaStatus(
            message: 'Invalid license schema',
            errors: result.errors,
          );
        }
      }

      return ActiveLicenseStatus(license);
    } catch (e) {
      return ErrorLicenseStatus(
        message: 'Error checking license from binary data',
        exception: e,
      );
    }
  }
}
