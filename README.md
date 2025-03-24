# Licensify

Advanced licensing solution for Flutter/Dart applications with robust protection and flexible options.

## Features

- 🔒 **RSA Verification**: Secure cryptographic signatures
- 🕒 **Expiration Dates**: Automatic expiration verification
- 🔄 **Custom License Types**: Standard and custom license types
- 📋 **Flexible Features**: Add custom parameters and metadata
- 💾 **Storage Independence**: Bring your own storage solution
- 📲 **Cross-Platform**: Works on all platforms including web (WASM)
- 🔍 **Schema Validation**: Validate license feature structure with customizable schemas

## Installation

```yaml
dependencies:
  licensify: ^1.6.1
```

## Quick Start

### Generate License Keys

```dart
// Generate RSA keys (do this once, store private key securely!)
final keys = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);
```

### Create & Distribute Licenses

```dart
// Generate a license for a customer
final generator = GenerateLicenseUseCase(privateKey: yourPrivateKey);
final license = generator.generateLicense(
  appId: 'com.your.app',
  expirationDate: DateTime.now().add(const Duration(days: 365)),
  type: LicenseType.pro,  // Or custom: LicenseType('enterprise')
  features: {
    'maxUsers': 50,
    'modules': ['reporting', 'analytics', 'export'],
    'premium': true,
  },
  // Optional metadata and device binding
  metadata: {
    'clientName': 'Example Corp',
    'deviceHash': 'unique-device-identifier',
  },
);

// Convert to JSON for distribution
final licenseModel = LicenseModel.fromDomain(license);
final licenseJson = licenseModel.toJson();
print(jsonEncode(licenseJson)); // For displaying or distributing as JSON string

// Or convert to binary format for storage
final licenseBytes = LicenseEncoder.encodeToBytes(licenseJson);
```

### Verify Licenses in Your App

```dart
// Setup license validation (do once at app startup)
final storage = InMemoryLicenseStorage(); // Or your own storage implementation
final repository = LicenseRepository(storage: storage);
final validator = LicenseValidator(publicKey: yourPublicKey); 

// Define schema for validation (optional)
final schema = LicenseSchema(
  featureSchema: {
    'maxUsers': SchemaField(
      type: FieldType.integer,
      required: true,
      validators: [NumberValidator(minimum: 5, maximum: 1000)],
    ),
    'modules': SchemaField(
      type: FieldType.array,
      required: true,
    ),
    'premium': SchemaField(type: FieldType.boolean),
  },
  allowUnknownFeatures: false,
);

// Check and store a license
final licenseString = '{"id":"...","appId":"...","features":{},...}'; // From user input
final jsonData = jsonDecode(licenseString); // Parse JSON string
final licenseModel = LicenseModel.fromJson(jsonData);
final license = licenseModel.toDomain();

// Save license to storage
final licenseJson = licenseModel.toJson();
final licenseBytes = LicenseEncoder.encodeToBytes(licenseJson);
await storage.saveLicenseData(licenseBytes);

// Check current license
final validateUseCase = LicenseValidateUseCase(
  validator: validator,
  schema: schema, // Optional schema validation
);

// Get current license from repository
final currentLicense = await repository.getCurrentLicense();

// Validate license
final status = await validateUseCase(currentLicense);

if (status.isActive) {
  final license = (status as ActiveLicenseStatus).license;
  
  // Enable features based on license
  if (license.type == LicenseType.pro) {
    final maxUsers = license.features['maxUsers'] as int;
    final modules = license.features['modules'] as List;
    print('Pro license active with $maxUsers users and modules: $modules');
  }
} else if (status is ExpiredLicenseStatus) {
  print('License has expired on ${status.license.expirationDate}');
} else if (status is InvalidLicenseSchemaStatus) {
  print('License schema invalid: ${status.errors}');
} else {
  print('License is invalid: ${status.runtimeType}');
  // Show license input screen to user
}
```

## Storage Options

The Licensify package follows the repository pattern and allows you to implement your own storage solution. Simply implement the `ILicenseStorage` interface to provide your own mechanism.

### In-Memory Storage (For Testing)

```dart
final storage = InMemoryLicenseStorage();
```

### Implement Your Own Storage

```dart
// Implement ILicenseStorage to create your own storage mechanism
class MyCustomStorage implements ILicenseStorage {
  @override
  Future<bool> deleteLicenseData() async {
    // Your implementation
  }

  @override
  Future<bool> hasLicense() async {
    // Your implementation
  }

  @override
  Future<Uint8List?> loadLicenseData() async {
    // Your implementation
  }

  @override
  Future<bool> saveLicenseData(Uint8List data) async {
    // Your implementation
  }
}
```

## Schema Validation

Define and validate expected structure for license features and metadata:

```dart
// Define a schema for enterprise licenses
final enterpriseSchema = LicenseSchema(
  // Feature fields schema
  featureSchema: {
    'maxUsers': SchemaField(
      type: FieldType.integer,
      required: true,
      validators: [NumberValidator(minimum: 5, maximum: 1000)],
    ),
    'modules': SchemaField(
      type: FieldType.array,
      required: true,
      validators: [
        ArrayValidator(
          minItems: 1, 
          itemValidator: StringValidator(),
        ),
      ],
    ),
    'premium': SchemaField(type: FieldType.boolean),
  },
  // Metadata fields schema
  metadataSchema: {
    'clientName': SchemaField(
      type: FieldType.string,
      required: true,
      validators: [StringValidator(minLength: 3)],
    ),
    'deviceHash': SchemaField(type: FieldType.string),
  },
  // Control whether unknown fields are allowed
  allowUnknownFeatures: false,
  allowUnknownMetadata: true,
);

// Validate license features against the schema
final featureResult = enterpriseSchema.validateFeatures(license.features);
if (!featureResult.isValid) {
  print('Feature validation failed: ${featureResult.errors}');
}

// Validate license metadata against the schema
final metadataResult = enterpriseSchema.validateMetadata(license.metadata);
if (!metadataResult.isValid) {
  print('Metadata validation failed: ${metadataResult.errors}');
}

// Validate the entire license against the schema
final licenseResult = enterpriseSchema.validateLicense(license);
if (licenseResult.isValid) {
  print('License schema valid!');
} else {
  print('Schema validation failed: ${licenseResult.errors}');
}

// Use with LicenseValidator for comprehensive validation
final validator = LicenseValidator(publicKey: yourPublicKey);

// Validate just the schema (signature and expiration not checked)
final validationResult = validator.validateSchema(license, enterpriseSchema);
if (!validationResult.isValid) {
  print('Schema validation failed: ${validationResult.errors}');
}

// Validate everything at once (signature, expiration, and schema)
final isValid = validator.validateLicenseWithSchema(license, enterpriseSchema);
if (isValid) {
  print('License is completely valid!');
} else {
  print('License validation failed');
}
```

## Advanced Schema Validation

For more complex validation needs, Licensify offers robust schema validation with nested objects:

```dart
// Define a more complex schema
final advancedSchema = LicenseSchema(
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
    'contactEmail': SchemaField(
      type: FieldType.string,
      validators: [
        StringValidator(
          pattern: r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ),
      ],
    ),
  },
  allowUnknownFeatures: false,
  allowUnknownMetadata: true,
);
```

See [example/schema_validation_example.dart](https://github.com/nogipx/licensify/blob/main/example/schema_validation_example.dart) for a complete example of schema validation.

## Custom License Types

```dart
// Define custom license types beyond standard ones
final enterpriseType = LicenseType('enterprise');
final educationType = LicenseType('education');

// Standard types are predefined
final trial = LicenseType.trial;
final standard = LicenseType.standard;
final pro = LicenseType.pro;
```

## License Format

Licenses include:
- Unique ID and app ID
- Creation and expiration dates
- License type (standard or custom)
- Custom features and metadata
- RSA signature for verification

Full JSON structure:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "appId": "com.example.myapp",
  "createdAt": "2024-07-25T14:30:00Z",
  "expirationDate": "2025-07-25T14:30:00Z",
  "type": "enterprise",
  "features": {
    "maxUsers": 50,
    "modules": ["analytics", "reporting"]
  },
  "metadata": {
    "clientName": "Example Corp",
    "deviceHash": "device-unique-identifier"
  },
  "signature": "Base64EncodedSignature..."
}
```

## Security Notes

- Store private keys securely, never in your app
- Public key is safe to embed in your application
- Consider using code obfuscation in release builds
- For high-security needs, add server-side verification

## Complete Example

See [example/rsa_license_demo.dart](https://github.com/nogipx/licensify/blob/main/example/rsa_license_demo.dart) for a complete implementation.

## License

```
SPDX-License-Identifier: LGPL-3.0-or-later
```

Created by Karim "nogipx" Mamatkazin
