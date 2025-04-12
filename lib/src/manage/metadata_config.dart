// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/src/license/domain/entities/license_schema.dart';

/// Базовый класс для типобезопасной конфигурации метаданных в лицензии
///
/// Metadata configuration base class for type-safe license metadata
abstract class MetadataConfig<T> {
  /// Уникальный ключ этого поля метаданных
  ///
  /// Unique key for this metadata field
  final String key;

  /// Схема для валидации значения
  ///
  /// Schema field for value validation
  final SchemaField schema;

  /// Создает конфигурацию метаданных
  ///
  /// Creates a metadata configuration
  const MetadataConfig({required this.key, required this.schema});

  /// Конвертирует типизированное значение в JSON-совместимый тип
  ///
  /// Converts typed value to JSON-compatible type
  Object? toJson(T value);

  /// Конвертирует JSON-значение в типизированное
  ///
  /// Converts JSON value to typed value
  T fromJson(dynamic value);
}

/// Конфигурация для строковых метаданных
///
/// Configuration for string metadata
class StringMetadata extends MetadataConfig<String> {
  /// Создает конфигурацию строковых метаданных
  ///
  /// Creates a string metadata configuration
  const StringMetadata({
    required super.key,
    super.schema = const SchemaField(type: FieldType.string, required: false),
  });

  @override
  Object? toJson(String value) => value;

  @override
  String fromJson(dynamic value) => value as String;
}

/// Конфигурация для метаданных с датой
///
/// Configuration for date metadata
class DateMetadata extends MetadataConfig<DateTime> {
  /// Создает конфигурацию метаданных с датой
  ///
  /// Creates a date metadata configuration
  const DateMetadata({
    required super.key,
    super.schema = const SchemaField(
      type: FieldType.string, // Храним как строку в ISO формате
      required: false,
    ),
  });

  @override
  Object? toJson(DateTime value) => value.toUtc().toIso8601String();

  @override
  DateTime fromJson(dynamic value) => DateTime.parse(value as String).toUtc();
}

/// Конфигурация для Email метаданных
///
/// Configuration for email metadata
class EmailMetadata extends StringMetadata {
  /// Регулярное выражение для проверки email
  ///
  /// Regular expression for email validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Создает конфигурацию email метаданных
  ///
  /// Creates an email metadata configuration
  const EmailMetadata({
    required super.key,
    super.schema = const SchemaField(
      type: FieldType.string,
      required: false,
      validators: [_EmailValidator()],
    ),
  });
}

/// Валидатор email адресов
///
/// Email address validator
class _EmailValidator implements FieldValidator {
  /// Создает валидатор email
  ///
  /// Creates an email validator
  const _EmailValidator();

  @override
  SchemaValidationResult validate(dynamic value) {
    if (value is! String) {
      return SchemaValidationResult.failureMessage('Value must be a string');
    }

    if (!EmailMetadata._emailRegex.hasMatch(value)) {
      return SchemaValidationResult.failureMessage('Invalid email format');
    }

    return SchemaValidationResult.success();
  }
}

/// Конфигурация для числовых метаданных
///
/// Configuration for numeric metadata
class NumMetadata extends MetadataConfig<num> {
  /// Создает конфигурацию числовых метаданных
  ///
  /// Creates a numeric metadata configuration
  const NumMetadata({
    required super.key,
    super.schema = const SchemaField(type: FieldType.number, required: false),
  });

  @override
  Object? toJson(num value) => value;

  @override
  num fromJson(dynamic value) => value as num;
}
