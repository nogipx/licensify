// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Interface for license validator
abstract class ILicenseValidator {
  /// Complete license validation including schema validation
  ///
  /// [license] - The license to validate
  /// [schema] - The schema to validate against
  ///
  /// Returns true if the license passes all validations
  /// Returns true if both the signature is valid and the license has not expired
  ValidationResult call(License license, {LicenseSchema? schema});

  /// Validates the license signature
  ///
  /// Returns true if the signature is valid, false otherwise
  ValidationResult validateSignature(License license);

  /// Validates the license expiration
  ///
  /// Returns true if the license has not expired, false otherwise
  ValidationResult validateExpiration(License license);

  /// Validates the license against a schema
  ///
  /// [license] - The license to validate
  /// [schema] - The schema to validate against
  ///
  /// Returns a schema validation result with detailed information
  SchemaValidationResult validateSchema(License license, LicenseSchema schema);
}
