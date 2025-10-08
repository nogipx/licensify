// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

part of 'package:licensify/licensify.dart';

/// Validation result
class LicenseValidationResult {
  /// Is license valid
  final bool isValid;

  /// Error message (null if license is valid)
  final String message;

  /// Creates a new validation result
  ///
  /// [isValid] - Is license valid
  /// [message] - Error message (null if license is valid)
  const LicenseValidationResult({required this.isValid, this.message = ''});

  /// Creates a valid validation result
  factory LicenseValidationResult.valid() {
    return const LicenseValidationResult(isValid: true);
  }

  /// Creates an invalid validation result with a message
  factory LicenseValidationResult.invalid(String message) {
    return LicenseValidationResult(isValid: false, message: message);
  }

  @override
  String toString() {
    return isValid
        ? 'ValidationResult(valid)'
        : 'ValidationResult(invalid: $message)';
  }
}
