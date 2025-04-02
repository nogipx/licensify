// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Результат валидации лицензии
class ValidationResult {
  /// Является ли лицензия валидной
  final bool isValid;

  /// Сообщение об ошибке (null если лицензия валидна)
  final String message;

  /// Создает новый результат валидации
  ///
  /// [isValid] - Валидна ли лицензия
  /// [message] - Сообщение об ошибке (null если лицензия валидна)
  const ValidationResult({required this.isValid, this.message = ''});

  /// Создает результат успешной валидации
  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true);
  }

  /// Создает результат неуспешной валидации с сообщением
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
