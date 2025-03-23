// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Example of using license schema validation
class SchemaValidationExample {
  /// Example of creating and using a license schema
  static void validateLicenseWithSchema() {
    // Define schema for an enterprise license type
    final enterpriseSchema = LicenseSchema(
      // Feature fields schema
      featureSchema: {
        'maxUsers': SchemaField(
          type: FieldType.integer,
          required: true,
          validators: [NumberValidator(minimum: 1, maximum: 1000)],
        ),
        'modules': SchemaField(
          type: FieldType.array,
          required: true,
          validators: [
            ArrayValidator(minItems: 1, itemValidator: StringValidator()),
          ],
        ),
        'premium': SchemaField(type: FieldType.boolean, required: false),
        'settings': SchemaField(
          type: FieldType.object,
          validators: [
            ObjectValidator(
              schema: {
                'theme': SchemaField(type: FieldType.string),
                'notifications': SchemaField(type: FieldType.boolean),
              },
            ),
          ],
        ),
      },

      // Metadata fields schema
      metadataSchema: {
        'purchaseDate': SchemaField(
          type: FieldType.string,
          required: true,
          validators: [
            StringValidator(
              pattern: r'^\d{4}-\d{2}-\d{2}$', // ISO date format
            ),
          ],
        ),
        'companyName': SchemaField(
          type: FieldType.string,
          required: true,
          validators: [StringValidator(minLength: 2, maxLength: 100)],
        ),
        'contactEmail': SchemaField(
          type: FieldType.string,
          validators: [
            StringValidator(
              pattern: r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            ),
          ],
        ),
      },

      // We don't allow unknown features in enterprise licenses
      allowUnknownFeatures: false,

      // But we do allow additional metadata
      allowUnknownMetadata: true,
    );

    // Example of validating a license against the schema
    void validateLicense(License license) {
      // Create a validator
      final validator = LicenseValidator(publicKey: '--- PUBLIC KEY ---');

      // Validate the license against the schema
      final validationResult = validator.validateSchema(
        license,
        enterpriseSchema,
      );

      if (validationResult.isValid) {
        print('License schema is valid');
      } else {
        print('License schema validation failed:');
        print(validationResult.errors);
      }

      // Complete validation including signature, expiration and schema
      final isValid = validator.validateLicenseWithSchema(
        license,
        enterpriseSchema,
      );
      print('License is fully valid: $isValid');
    }

    // Example of creating a license with valid features and metadata
    final validLicense = License(
      id: 'license-id-123',
      appId: 'com.example.app',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
      createdAt: DateTime.now(),
      signature: 'base64-signature',
      type: LicenseType('enterprise'),
      features: {
        'maxUsers': 100,
        'modules': ['accounting', 'inventory', 'reporting'],
        'premium': true,
        'settings': {'theme': 'dark', 'notifications': true},
      },
      metadata: {
        'purchaseDate': '2024-08-01',
        'companyName': 'Example Corp',
        'contactEmail': 'license@example.com',
        // Additional fields are allowed
        'department': 'IT',
      },
    );

    // Example of a license with invalid features
    final invalidLicense = License(
      id: 'license-id-456',
      appId: 'com.example.app',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
      createdAt: DateTime.now(),
      signature: 'base64-signature',
      type: LicenseType('enterprise'),
      features: {
        'maxUsers': 0, // Invalid: less than minimum
        'modules': [], // Invalid: empty array
        'unknownFeature': 'value', // Invalid: unknown feature not allowed
      },
      metadata: {
        'purchaseDate': '2024/08/01', // Invalid: wrong format
        'companyName': 'A', // Invalid: too short
        'contactEmail': 'not-an-email', // Invalid: not an email format
      },
    );

    // Validate both licenses
    print('Validating valid license:');
    validateLicense(validLicense);

    print('\nValidating invalid license:');
    validateLicense(invalidLicense);
  }
}
