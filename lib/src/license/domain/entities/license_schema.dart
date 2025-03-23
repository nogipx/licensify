// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Defines schema for license fields validation
class LicenseSchema {
  /// Schema for feature fields
  final Map<String, SchemaField> featureSchema;

  /// Schema for metadata fields
  final Map<String, SchemaField> metadataSchema;

  /// Whether to allow unknown/undeclared fields in features
  final bool allowUnknownFeatures;

  /// Whether to allow unknown/undeclared fields in metadata
  final bool allowUnknownMetadata;

  /// Creates a new license schema
  const LicenseSchema({
    this.featureSchema = const {},
    this.metadataSchema = const {},
    this.allowUnknownFeatures = true,
    this.allowUnknownMetadata = true,
  });

  /// Validates features against schema
  ValidationResult validateFeatures(Map<String, dynamic> features) {
    return _validateFields(
      features,
      featureSchema,
      allowUnknownFields: allowUnknownFeatures,
    );
  }

  /// Validates metadata against schema
  ValidationResult validateMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) {
      return ValidationResult.success();
    }
    return _validateFields(
      metadata,
      metadataSchema,
      allowUnknownFields: allowUnknownMetadata,
    );
  }

  /// Validates a license object against this schema
  ValidationResult validateLicense(License license) {
    final featureResult = validateFeatures(license.features);
    if (!featureResult.isValid) {
      return ValidationResult(
        isValid: false,
        errors: {'features': featureResult.errors ?? {}},
      );
    }

    final metadataResult = validateMetadata(license.metadata);
    if (!metadataResult.isValid) {
      return ValidationResult(
        isValid: false,
        errors: {'metadata': metadataResult.errors ?? {}},
      );
    }

    return ValidationResult.success();
  }

  ValidationResult _validateFields(
    Map<String, dynamic> data,
    Map<String, SchemaField> schema, {
    required bool allowUnknownFields,
  }) {
    final errors = <String, String>{};

    // Check required fields and validate values
    for (final entry in schema.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value;

      if (fieldSchema.required && !data.containsKey(fieldName)) {
        errors[fieldName] = 'Required field is missing';
        continue;
      }

      if (!data.containsKey(fieldName)) {
        continue; // Optional field is absent
      }

      // Validate type and additional constraints
      final value = data[fieldName];
      final validationResult = fieldSchema.validate(value);
      if (!validationResult.isValid) {
        errors[fieldName] = validationResult.errorMessage ?? 'Invalid value';
      }
    }

    // Check for unknown fields
    if (!allowUnknownFields) {
      for (final fieldName in data.keys) {
        if (!schema.containsKey(fieldName)) {
          errors[fieldName] = 'Unknown field not allowed by schema';
        }
      }
    }

    if (errors.isEmpty) {
      return ValidationResult.success();
    } else {
      return ValidationResult.failure(errors);
    }
  }
}

/// Defines a field in the schema
class SchemaField {
  /// Whether the field is required
  final bool required;

  /// Expected field type
  final FieldType type;

  /// Additional validators for the field
  final List<FieldValidator> validators;

  /// Creates a new schema field definition
  const SchemaField({
    this.required = false,
    this.type = FieldType.string,
    this.validators = const [],
  });

  /// Validates a value against this field schema
  ValidationResult validate(dynamic value) {
    // Check type
    if (!_checkType(value, type)) {
      return ValidationResult.failure(
        'Expected $type but got ${value.runtimeType}',
      );
    }

    // Run additional validators
    for (final validator in validators) {
      final result = validator.validate(value);
      if (!result.isValid) {
        return result;
      }
    }

    return ValidationResult.success();
  }

  bool _checkType(dynamic value, FieldType type) {
    switch (type) {
      case FieldType.string:
        return value is String;
      case FieldType.integer:
        return value is int;
      case FieldType.number:
        return value is num;
      case FieldType.boolean:
        return value is bool;
      case FieldType.array:
        return value is List;
      case FieldType.object:
        return value is Map;
      case FieldType.any:
        return true;
    }
  }
}

/// Types supported in schema fields
enum FieldType {
  /// String value
  string,

  /// Integer value
  integer,

  /// Number (int or double)
  number,

  /// Boolean value
  boolean,

  /// List/array value
  array,

  /// Map/object value
  object,

  /// Any type is accepted
  any,
}

/// Interface for field validators
abstract class FieldValidator {
  /// Validates a field value
  ValidationResult validate(dynamic value);
}

/// Result of a validation operation
class ValidationResult {
  /// Whether validation passed
  final bool isValid;

  /// Validation errors by field
  final Map<String, dynamic>? errors;

  /// Creates a validation result
  const ValidationResult({required this.isValid, this.errors});

  /// Creates a successful validation result
  factory ValidationResult.success() => const ValidationResult(isValid: true);

  /// Creates a failed validation result with error message
  factory ValidationResult.failure(dynamic errorMessage) =>
      ValidationResult(isValid: false, errors: {'error': errorMessage});

  /// Gets a human-readable error message
  String? get errorMessage {
    if (errors == null || errors!.isEmpty) return null;

    if (errors!.length == 1 && errors!.containsKey('error')) {
      return errors!['error'].toString();
    }

    return errors.toString();
  }
}

/// Validator for string values
class StringValidator implements FieldValidator {
  /// Minimum string length
  final int? minLength;

  /// Maximum string length
  final int? maxLength;

  /// RegExp pattern to match
  final String? pattern;

  /// Creates a string validator
  const StringValidator({this.minLength, this.maxLength, this.pattern});

  @override
  ValidationResult validate(dynamic value) {
    if (value is! String) {
      return ValidationResult.failure('Value is not a string');
    }

    if (minLength != null && value.length < minLength!) {
      return ValidationResult.failure(
        'String length must be at least $minLength characters',
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return ValidationResult.failure(
        'String length must not exceed $maxLength characters',
      );
    }

    if (pattern != null) {
      final regex = RegExp(pattern!);
      if (!regex.hasMatch(value)) {
        return ValidationResult.failure('String must match pattern: $pattern');
      }
    }

    return ValidationResult.success();
  }
}

/// Validator for numeric values
class NumberValidator implements FieldValidator {
  /// Minimum allowed value
  final num? minimum;

  /// Maximum allowed value
  final num? maximum;

  /// Whether minimum is exclusive
  final bool exclusiveMinimum;

  /// Whether maximum is exclusive
  final bool exclusiveMaximum;

  /// Creates a number validator
  const NumberValidator({
    this.minimum,
    this.maximum,
    this.exclusiveMinimum = false,
    this.exclusiveMaximum = false,
  });

  @override
  ValidationResult validate(dynamic value) {
    if (value is! num) {
      return ValidationResult.failure('Value is not a number');
    }

    if (minimum != null) {
      if (exclusiveMinimum) {
        if (value <= minimum!) {
          return ValidationResult.failure(
            'Value must be greater than $minimum',
          );
        }
      } else {
        if (value < minimum!) {
          return ValidationResult.failure(
            'Value must be greater than or equal to $minimum',
          );
        }
      }
    }

    if (maximum != null) {
      if (exclusiveMaximum) {
        if (value >= maximum!) {
          return ValidationResult.failure('Value must be less than $maximum');
        }
      } else {
        if (value > maximum!) {
          return ValidationResult.failure(
            'Value must be less than or equal to $maximum',
          );
        }
      }
    }

    return ValidationResult.success();
  }
}

/// Validator for array values
class ArrayValidator implements FieldValidator {
  /// Minimum array length
  final int? minItems;

  /// Maximum array length
  final int? maxItems;

  /// Item validator (applied to each item)
  final FieldValidator? itemValidator;

  /// Creates an array validator
  const ArrayValidator({this.minItems, this.maxItems, this.itemValidator});

  @override
  ValidationResult validate(dynamic value) {
    if (value is! List) {
      return ValidationResult.failure('Value is not an array');
    }

    if (minItems != null && value.length < minItems!) {
      return ValidationResult.failure(
        'Array must contain at least $minItems items',
      );
    }

    if (maxItems != null && value.length > maxItems!) {
      return ValidationResult.failure(
        'Array must not contain more than $maxItems items',
      );
    }

    if (itemValidator != null) {
      for (var i = 0; i < value.length; i++) {
        final itemResult = itemValidator!.validate(value[i]);
        if (!itemResult.isValid) {
          return ValidationResult.failure(
            'Item at index $i is invalid: ${itemResult.errorMessage}',
          );
        }
      }
    }

    return ValidationResult.success();
  }
}

/// Validator for object/map values
class ObjectValidator implements FieldValidator {
  /// Schema for object fields
  final Map<String, SchemaField> schema;

  /// Whether to allow unknown fields
  final bool allowUnknownFields;

  /// Creates an object validator
  const ObjectValidator({
    this.schema = const {},
    this.allowUnknownFields = true,
  });

  @override
  ValidationResult validate(dynamic value) {
    if (value is! Map) {
      return ValidationResult.failure('Value is not an object');
    }

    final errors = <String, dynamic>{};

    // Check required fields and validate values
    for (final entry in schema.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value;

      if (fieldSchema.required && !value.containsKey(fieldName)) {
        errors[fieldName] = 'Required field is missing';
        continue;
      }

      if (!value.containsKey(fieldName)) {
        continue; // Optional field is absent
      }

      // Validate field value
      final fieldValue = value[fieldName];
      final validationResult = fieldSchema.validate(fieldValue);
      if (!validationResult.isValid) {
        errors[fieldName] = validationResult.errorMessage ?? 'Invalid value';
      }
    }

    // Check for unknown fields
    if (!allowUnknownFields) {
      for (final key in value.keys) {
        final fieldName = key.toString();
        if (!schema.containsKey(fieldName)) {
          errors[fieldName] = 'Unknown field not allowed by schema';
        }
      }
    }

    if (errors.isEmpty) {
      return ValidationResult.success();
    } else {
      return ValidationResult.failure(errors);
    }
  }
}
