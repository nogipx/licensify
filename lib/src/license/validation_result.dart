// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Validation result
class ValidationResult {
  /// Is license valid
  final bool isValid;

  /// Error message (null if license is valid)
  final String message;

  /// Creates a new validation result
  ///
  /// [isValid] - Is license valid
  /// [message] - Error message (null if license is valid)
  const ValidationResult({required this.isValid, this.message = ''});

  /// Creates a valid validation result
  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  /// Creates an invalid validation result with a message
  factory ValidationResult.invalid(String message) {
    return ValidationResult(isValid: false, message: message);
  }

  @override
  String toString() {
    return isValid
        ? 'ValidationResult(valid)'
        : 'ValidationResult(invalid: $message)';
  }
}
