// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Base class for license status
///
/// Provides a common interface for all possible license states.
/// Applications should check the status type to determine how to proceed.
abstract class LicenseStatus {
  const LicenseStatus();

  /// Returns true if the license is active and valid
  bool get isActive => this is ActiveLicenseStatus;

  /// Returns true if the license has expired
  bool get isExpired => this is ExpiredLicenseStatus;

  /// Returns true if no license is installed
  bool get isNoLicense => this is NoLicenseStatus;

  /// Returns true if the license signature is invalid
  bool get isInvalidSignature => this is InvalidLicenseSignatureStatus;

  /// Returns true if the license schema is invalid
  bool get isInvalidSchema => this is InvalidLicenseSchemaStatus;

  /// Returns true if an error occurred during license validation
  bool get isError => this is ErrorLicenseStatus;

  /// Returns the license object if available (for Active or Expired status)
  /// Returns null for other status types
  License? get license => switch (this) {
    ActiveLicenseStatus(:final license) => license,
    ExpiredLicenseStatus(:final license) => license,
    _ => null,
  };
}

/// Status indicating no license is installed
class NoLicenseStatus extends LicenseStatus {
  const NoLicenseStatus();
}

/// Status indicating the license is valid and active
class ActiveLicenseStatus extends LicenseStatus {
  /// The active license object
  @override
  final License license;

  /// Creates an active license status with the specified license
  const ActiveLicenseStatus(this.license);
}

/// Status indicating the license has expired
class ExpiredLicenseStatus extends LicenseStatus {
  /// The expired license object
  @override
  final License license;

  /// Creates an expired license status with the specified license
  const ExpiredLicenseStatus(this.license);
}

/// Status indicating the license signature is invalid
class InvalidLicenseSignatureStatus extends LicenseStatus {
  /// Creates an invalid license signature status
  const InvalidLicenseSignatureStatus();
}

/// Status indicating the license schema is invalid
class InvalidLicenseSchemaStatus extends LicenseStatus {
  /// The schema validation result
  final SchemaValidationResult schemaValidationResult;

  /// Creates an invalid license schema status with the specified schema validation result
  const InvalidLicenseSchemaStatus(this.schemaValidationResult);
}

/// Status indicating an error occurred during license checking
class ErrorLicenseStatus extends LicenseStatus {
  /// Error message describing what went wrong
  final String message;

  /// The exception that caused the error, if available
  final Object? exception;

  /// Creates an error license status with the specified error details
  const ErrorLicenseStatus({required this.message, this.exception});
}
