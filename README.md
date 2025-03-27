# Licensify

Advanced licensing solution for Flutter/Dart applications with cryptographic protection.

## Features

- 🔐 **Cryptography**: RSA and ECDSA with SHA-256, SHA-384, SHA-512 algorithms
- ⏰ **Expiration**: Automatic expiration verification
- 🏷️ **Custom Types**: Built-in and custom license types
- 🧩 **Flexible Parameters**: Add metadata and features
- 💾 **Storage Independence**: Bring your own storage solution
- 🌐 **Cross-Platform**: Works on all platforms including web (WASM)
- 📋 **Schema Validation**: Validate structure with customizable schemas

## Installation

```yaml
dependencies:
  licensify: ^1.7.0
```

## Quick Start

### Key Generation

```dart
// RSA keys
final rsaKeyPair = await RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

// ECDSA keys (91% smaller, 10x faster generation)
final ecdsaKeyPair = await EcdsaKeyGenerator.generateKeyPairAsPem(
  curve: EcCurve.p256, 
  randomAlgorithm: SecureRandomAlgorithm.fortuna,
);
```

### License Creation

```dart
// Create license generator
final generator = LicenseGenerateUseCase(
  privateKey: keyPair.privateKey,
);

// Generate license
final license = generator.generateLicense(
  appId: 'your-app-id',
  expirationDate: DateTime.now().add(Duration(days: 365)),
  type: LicenseType.pro,
  metadata: {'user': 'John Doe', 'plan': 'premium'},
);

// License in JSON format for distribution to users
String licenseJson = license.toJson();

// Convert to binary format for storage
Uint8List licenseBytes = LicenseEncoder.encodeToBytes(license.toJson());
```

### License Encoding/Decoding

The `LicenseEncoder` class provides utilities for working with the binary license format:

```dart
// Convert license JSON to binary format
final licenseBytes = LicenseEncoder.encodeToBytes(license.toJson());

// Decode license from binary data
final licenseData = LicenseEncoder.decodeFromBytes(licenseBytes);
if (licenseData != null) {
  // Create license instance from decoded data
  final license = License(
    id: licenseData['id'],
    appId: licenseData['appId'],
    expirationDate: DateTime.parse(licenseData['expirationDate']),
    createdAt: DateTime.parse(licenseData['createdAt']),
    signature: licenseData['signature'],
    type: LicenseType(licenseData['type']),
    features: Map<String, dynamic>.from(licenseData['features']),
    metadata: licenseData['metadata'] != null 
        ? Map<String, dynamic>.from(licenseData['metadata']) 
        : null,
  );
}

// Check if bytes have valid license format
final isValidFormat = LicenseEncoder.isValidLicenseFile(bytes);
```

### License Validation

```dart
// Create validator
final validator = LicenseValidator(
  publicKey: keyPair.publicKey,
);

// Optional: Create schema for validation
final schema = LicenseSchema(
  featureSchema: {
    'maxUsers': SchemaField(
      type: FieldType.integer,
      required: true,
    ),
  },
);

// Create validation use case
final licenseValidator = LicenseValidateUseCase(
  validator: validator,
  schema: schema, // Optional
);

// Read license from binary data
final licenseData = LicenseEncoder.decodeFromBytes(licenseBytes);
if (licenseData == null) {
  print('Invalid license format');
  return;
}

// Create license instance from decoded data
final license = License(
  id: licenseData['id'],
  appId: licenseData['appId'],
  expirationDate: DateTime.parse(licenseData['expirationDate']),
  createdAt: DateTime.parse(licenseData['createdAt']),
  signature: licenseData['signature'],
  type: LicenseType(licenseData['type']),
  features: Map<String, dynamic>.from(licenseData['features']),
  metadata: licenseData['metadata'] != null 
      ? Map<String, dynamic>.from(licenseData['metadata']) 
      : null,
);

// Validate license
final result = await licenseValidator(license);

// Check result status
if (result.status is ActiveLicenseStatus) {
  // License is valid and active
  final activeLicense = (result.status as ActiveLicenseStatus).license;
  print('Active license: ${activeLicense.type}');
} else if (result.status is ExpiredLicenseStatus) {
  // License has expired
  print('License expired');
} else if (result.status is InvalidLicenseSignatureStatus) {
  // Invalid signature
  print('Invalid license signature');
} else if (result.status is InvalidLicenseSchemaStatus) {
  // Schema validation failed
  final schemaErrors = (result.status as InvalidLicenseSchemaStatus).result.errors;
  print('Schema validation failed: $schemaErrors');
}
```

## Storage

Implement the `ILicenseStorage` interface to create your own storage mechanism:

```dart
class MyCustomStorage implements ILicenseStorage {
  @override
  Future<bool> deleteLicenseData() async { /* implementation */ }
  
  @override
  Future<bool> hasLicense() async { /* implementation */ }
  
  @override
  Future<Uint8List?> loadLicenseData() async { /* implementation */ }
  
  @override
  Future<bool> saveLicenseData(Uint8List data) async { /* implementation */ }
}
```

## Schema Validation

```dart
// Define schema for enterprise licenses
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
      validators: [
        ArrayValidator(minItems: 1, itemValidator: StringValidator()),
      ],
    ),
  },
  metadataSchema: {
    'clientName': SchemaField(
      type: FieldType.string,
      required: true,
    ),
  },
);

// Validate license against schema
final isValid = validator.validateLicenseWithSchema(license, schema);
```

## Custom License Types

```dart
// Standard types
final trial = LicenseType.trial;
final standard = LicenseType.standard;
final pro = LicenseType.pro;

// Custom types
final enterprise = LicenseType('enterprise');
final education = LicenseType('education');
```

## License Format

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
    "clientName": "Example Corp"
  },
  "signature": "Base64EncodedSignature..."
}
```

## Security

- Store private keys securely, never in your app
- Public key is safe to embed in your application
- Consider using code obfuscation in release builds

## Key Types

### RSA

```dart
final rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);
```

### ECDSA (more efficient)

```dart
// NIST P-256
final ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem(
  curve: EcCurve.p256,
  randomAlgorithm: SecureRandomAlgorithm.fortuna,
);

// Bitcoin/Ethereum compatible
final bitcoinKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem(
  curve: EcCurve.secp256k1,
);
```

### ECDSA Advantages
- Smaller key sizes (256-bit ECDSA ≈ 3072-bit RSA)
- Up to 10x faster generation
- Significantly lower CPU and memory usage
- Signatures are 72% smaller than RSA

## License

```
SPDX-License-Identifier: LGPL-3.0-or-later
```

Created by Karim "nogipx" Mamatkazin
