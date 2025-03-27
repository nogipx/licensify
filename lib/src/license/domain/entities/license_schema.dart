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
  SchemaValidationResult validateFeatures(Map<String, dynamic> features) {
    return _validateFields(
      features,
      featureSchema,
      allowUnknownFields: allowUnknownFeatures,
    );
  }

  /// Validates metadata against schema
  SchemaValidationResult validateMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) {
      return SchemaValidationResult.success();
    }
    return _validateFields(
      metadata,
      metadataSchema,
      allowUnknownFields: allowUnknownMetadata,
    );
  }

  /// Validates a license object against this schema
  SchemaValidationResult validateLicense(License license) {
    final featureResult = validateFeatures(license.features);
    final metadataResult = validateMetadata(license.metadata);

    if (!metadataResult.isValid || !featureResult.isValid) {
      return SchemaValidationResult.failure({
        'metadata': metadataResult.errors,
        'features': featureResult.errors,
      });
    }

    return SchemaValidationResult.success();
  }

  SchemaValidationResult _validateFields(
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
      return SchemaValidationResult.success();
    } else {
      return SchemaValidationResult.failure(errors);
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
  SchemaValidationResult validate(dynamic value) {
    // Check type
    if (!_checkType(value, type)) {
      return SchemaValidationResult.failureMessage(
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

    return SchemaValidationResult.success();
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
  SchemaValidationResult validate(dynamic value);
}

/// Result of a validation operation
class SchemaValidationResult {
  /// Whether validation passed
  final bool isValid;

  /// Validation errors by field
  final Map<String, dynamic> errors;

  /// Creates a validation result
  const SchemaValidationResult._({
    required this.isValid,
    this.errors = const {},
  });

  /// Creates a successful validation result
  factory SchemaValidationResult.success() =>
      const SchemaValidationResult._(isValid: true);

  /// Creates a failed validation result with error message
  factory SchemaValidationResult.failure(Map<String, dynamic> errors) =>
      SchemaValidationResult._(isValid: false, errors: errors);

  /// Creates a failed validation result with error message
  factory SchemaValidationResult.failureMessage(String message) =>
      SchemaValidationResult._(isValid: false, errors: {'error': message});

  /// Gets a human-readable error message
  String? get errorMessage {
    if (errors.isEmpty) return null;

    if (errors.length == 1 && errors.containsKey('error')) {
      return errors['error'].toString();
    }

    return errors.toString();
  }

  @override
  String toString() =>
      'SchemaValidationResult(isValid: $isValid, errors: $errors)';
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
  SchemaValidationResult validate(dynamic value) {
    if (value is! String) {
      return SchemaValidationResult.failureMessage('Value is not a string');
    }

    if (minLength != null && value.length < minLength!) {
      return SchemaValidationResult.failureMessage(
        'String length must be at least $minLength characters',
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return SchemaValidationResult.failureMessage(
        'String length must not exceed $maxLength characters',
      );
    }

    if (pattern != null) {
      final regex = RegExp(pattern!);
      if (!regex.hasMatch(value)) {
        return SchemaValidationResult.failureMessage(
          'String must match pattern: $pattern',
        );
      }
    }

    return SchemaValidationResult.success();
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
  SchemaValidationResult validate(dynamic value) {
    if (value is! num) {
      return SchemaValidationResult.failureMessage('Value is not a number');
    }

    if (minimum != null) {
      if (exclusiveMinimum) {
        if (value <= minimum!) {
          return SchemaValidationResult.failureMessage(
            'Value must be greater than $minimum',
          );
        }
      } else {
        if (value < minimum!) {
          return SchemaValidationResult.failureMessage(
            'Value must be greater than or equal to $minimum',
          );
        }
      }
    }

    if (maximum != null) {
      if (exclusiveMaximum) {
        if (value >= maximum!) {
          return SchemaValidationResult.failureMessage(
            'Value must be less than $maximum',
          );
        }
      } else {
        if (value > maximum!) {
          return SchemaValidationResult.failureMessage(
            'Value must be less than or equal to $maximum',
          );
        }
      }
    }

    return SchemaValidationResult.success();
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
  SchemaValidationResult validate(dynamic value) {
    if (value is! List) {
      return SchemaValidationResult.failureMessage('Value is not an array');
    }

    if (minItems != null && value.length < minItems!) {
      return SchemaValidationResult.failureMessage(
        'Array must contain at least $minItems items',
      );
    }

    if (maxItems != null && value.length > maxItems!) {
      return SchemaValidationResult.failureMessage(
        'Array must not contain more than $maxItems items',
      );
    }

    if (itemValidator != null) {
      for (var i = 0; i < value.length; i++) {
        final itemResult = itemValidator!.validate(value[i]);
        if (!itemResult.isValid) {
          return SchemaValidationResult.failureMessage(
            'Item at index $i is invalid: ${itemResult.errorMessage}',
          );
        }
      }
    }

    return SchemaValidationResult.success();
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
  SchemaValidationResult validate(dynamic value) {
    if (value is! Map) {
      return SchemaValidationResult.failureMessage('Value is not an object');
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
      return SchemaValidationResult.success();
    } else {
      return SchemaValidationResult.failure(errors);
    }
  }
}
