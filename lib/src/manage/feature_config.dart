// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/src/license/domain/entities/license_schema.dart';

/// Базовый класс для типобезопасной конфигурации фич в лицензии
///
/// Feature configuration base class for type-safe license features
abstract class FeatureConfig<T> {
  /// Уникальный ключ этой фичи
  ///
  /// Unique key for this feature
  final String key;

  /// Схема для валидации значения
  ///
  /// Schema field for value validation
  final SchemaField schema;

  /// Значение по умолчанию
  ///
  /// Default value
  final T defaultValue;

  /// Создает конфигурацию фичи
  ///
  /// Creates a feature configuration
  const FeatureConfig({
    required this.key,
    required this.schema,
    required this.defaultValue,
  });

  /// Конвертирует типизированное значение в JSON-совместимый тип
  ///
  /// Converts typed value to JSON-compatible type
  Object? toJson(T value);

  /// Конвертирует JSON-значение в типизированное
  ///
  /// Converts JSON value to typed value
  T fromJson(dynamic value);
}

/// Конфигурация для целочисленных фич
///
/// Configuration for integer features
class IntFeature extends FeatureConfig<int> {
  /// Создает конфигурацию целочисленной фичи
  ///
  /// Creates an integer feature configuration
  const IntFeature({
    required super.key,
    super.schema = const SchemaField(type: FieldType.integer, required: true),
    super.defaultValue = 0,
  });

  @override
  Object? toJson(int value) => value;

  @override
  int fromJson(dynamic value) => value as int;
}

/// Конфигурация для строковых фич
///
/// Configuration for string features
class StringFeature extends FeatureConfig<String> {
  /// Создает конфигурацию строковой фичи
  ///
  /// Creates a string feature configuration
  const StringFeature({
    required super.key,
    super.schema = const SchemaField(type: FieldType.string, required: true),
    super.defaultValue = '',
  });

  @override
  Object? toJson(String value) => value;

  @override
  String fromJson(dynamic value) => value as String;
}

/// Конфигурация для булевых фич
///
/// Configuration for boolean features
class BoolFeature extends FeatureConfig<bool> {
  /// Создает конфигурацию булевой фичи
  ///
  /// Creates a boolean feature configuration
  const BoolFeature({
    required super.key,
    super.schema = const SchemaField(type: FieldType.boolean, required: true),
    super.defaultValue = false,
  });

  @override
  Object? toJson(bool value) => value;

  @override
  bool fromJson(dynamic value) => value as bool;
}

/// Конфигурация для числовых фич
///
/// Configuration for numeric features
class NumFeature extends FeatureConfig<num> {
  /// Создает конфигурацию числовой фичи
  ///
  /// Creates a numeric feature configuration
  const NumFeature({
    required super.key,
    super.schema = const SchemaField(type: FieldType.number, required: true),
    super.defaultValue = 0,
  });

  @override
  Object? toJson(num value) => value;

  @override
  num fromJson(dynamic value) => value as num;
}

/// Конфигурация для списочных фич
///
/// Configuration for list features
class ListFeature<E> extends FeatureConfig<List<E>> {
  /// Функция конвертации элемента в JSON
  ///
  /// Element to JSON conversion function
  final Object? Function(E value) elementToJson;

  /// Функция конвертации из JSON в элемент
  ///
  /// JSON to element conversion function
  final E Function(dynamic value) elementFromJson;

  /// Создает конфигурацию списочной фичи
  ///
  /// Creates a list feature configuration
  const ListFeature({
    required super.key,
    required this.elementToJson,
    required this.elementFromJson,
    super.schema = const SchemaField(type: FieldType.array, required: true),
    super.defaultValue = const [],
  });

  @override
  Object? toJson(List<E> value) => value.map((e) => elementToJson(e)).toList();

  @override
  List<E> fromJson(dynamic value) =>
      (value as List).map((e) => elementFromJson(e)).toList();
}
