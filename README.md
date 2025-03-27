# Licensify

![Licensify](https://img.shields.io/pub/v/licensify.svg) ![Flutter](https://img.shields.io/badge/Platform-Flutter%20%7C%20Dart-blue)

Advanced licensing solution for Flutter/Dart applications with cryptographic protection.

**Licensify** transforms complex license management into a simple process, providing maximum security and flexibility.

## 🚀 Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Examples](#-usage-examples)
- [Documentation](#-documentation)
- [Security](#-security)
- [License](#-license)

## 🔥 Features

- **Powerful Cryptography**: RSA and ECDSA with SHA-512 for robust protection
- **Flexible Licenses**: Built-in and custom types, metadata, and features
- **Expiration**: Automatic expiration verification
- **Schema Validation**: Validate license structures with custom schemas
- **Storage Independence**: Bring your own storage implementation
- **Cross-Platform**: Works on all platforms including web (WASM)
- **High Performance**: ECDSA up to 10x faster with 72% smaller key sizes

## 📦 Installation

```yaml
dependencies:
  licensify: ^1.7.0
```

## 🏁 Quick Start

### ECDSA (recommended)

```dart
// 1. Generate key pair (server-side/developer only)
final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);

// 2. Create license (for your user)
final license = keyPair.privateKey.licenseGenerator(
  appId: 'com.example.app',
  expirationDate: DateTime.now().add(Duration(days: 365)),
  type: LicenseType.pro,
);

// 3. Validate license (client-side)
final validator = keyPair.publicKey.licenseValidator;
final result = validator.validateLicense(license);
if (result.isValid) {
  print('✅ License is valid');
} else {
  print('❌ License is invalid: ${result.message}');
}
```

### RSA (traditional approach)

```dart
// 1. Generate key pair
final keyPair = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

// 2 and 3 - same as with ECDSA
```

## 📚 Usage Examples

### Complete License Workflow

```dart
// SERVER: generating a license
// Import private key with automatic type detection
final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(privateKeyPem);
final generator = privateKey.licenseGenerator;

final license = generator(
  appId: 'com.example.app',
  expirationDate: DateTime.now().add(Duration(days: 365)),
  type: LicenseType.pro,
  features: {
    'maxUsers': 50,
    'modules': ['reporting', 'analytics', 'export'],
    'premium': true,
  },
  metadata: {
    'customerName': 'Acme Corp',
    'contactEmail': 'support@acme.com',
  },
);

// Convert to bytes for transmission/storage
final bytes = LicenseEncoder.encodeToBytes(license);

// CLIENT: validating the received license
// Import public key with automatic type detection
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(publicKeyPem);
final validator = publicKey.licenseValidator;

// Read from bytes
final decodedData = LicenseEncoder.decodeFromBytes(bytes);
final receivedLicense = License.fromMap(decodedData!);

// Validate
final result = validator.validateLicense(receivedLicense);
if (result.isValid && !receivedLicense.isExpired) {
  print('✅ License is valid - available level: ${receivedLicense.type.name}');
} else {
  print('❌ License is invalid or expired');
}

// Check license features
if (receivedLicense.features?['premium'] == true) {
  print('Premium features activated');
}
```

### License Storage

```dart
// Built-in In-Memory storage
final storage = InMemoryLicenseStorage();
final repository = LicenseRepository(storage: storage);

// Save license
await repository.saveLicense(license);

// Retrieve current license
final savedLicense = await repository.getCurrentLicense();

// Custom storage implementation
class FileSystemLicenseStorage implements ILicenseStorage {
  final String filePath;
  
  FileSystemLicenseStorage(this.filePath);
  
  @override
  Future<bool> deleteLicenseData() async {
    // Implementation to delete file
    return true;
  }
  
  @override
  Future<bool> hasLicense() async {
    // Implementation to check if file exists
    return true;
  }
  
  @override
  Future<Uint8List?> loadLicenseData() async {
    // Implementation to read file
    return null;
  }
  
  @override
  Future<bool> saveLicenseData(Uint8List data) async {
    // Implementation to write to file
    return true;
  }
}
```

### Schema Validation

```dart
// Define license schema
final schema = LicenseSchema(
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
  },
  metadataSchema: {
    'customerName': SchemaField(
      type: FieldType.string,
      required: true,
    ),
  },
  allowUnknownFeatures: false,
  allowUnknownMetadata: true,
);

// Validate license against schema
final schemaResult = validator.validateSchema(license, schema);
if (schemaResult.isValid) {
  print('✅ License schema is valid');
} else {
  print('❌ License schema is invalid:');
  for (final entry in schemaResult.errors.entries) {
    print('  - ${entry.key}: ${entry.value}');
  }
}

// Comprehensive validation of signature, expiration, and schema
final isValid = validator.validateLicenseWithSchema(license, schema);
```

### ECDSA vs RSA: Advantages

```dart
// Key generation comparison
final rsaStartTime = DateTime.now();
final rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);
final rsaEndTime = DateTime.now();

final ecdsaStartTime = DateTime.now();
final ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);
final ecdsaEndTime = DateTime.now();

print('ECDSA advantages:');
print('- Generation is ${rsaEndTime.difference(rsaStartTime).inMilliseconds / 
       ecdsaEndTime.difference(ecdsaStartTime).inMilliseconds}x faster');
print('- Private key size: ${rsaKeyPair.privateKey.content.length / 
       ecdsaKeyPair.privateKey.content.length}x smaller');
print('- Public key size: ${rsaKeyPair.publicKey.content.length / 
       ecdsaKeyPair.publicKey.content.length}x smaller');
print('- ECDSA P-256: ~128-bit security level (vs RSA-2048: ~112-bit)');
```

## 📖 Documentation

### Key Formats and Importing

```dart
// Generate keys
final ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem();

// Create keys with explicit type specification
final privateKey = LicensifyPrivateKey.rsa(privateKeyPemString);
final publicKey = LicensifyPublicKey.ecdsa(publicKeyPemString);

// Import keys with automatic type detection
final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(pemPrivateKey);
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(pemPublicKey);

// Import keys from bytes
final privateKeyBytes = Uint8List.fromList(utf8.encode(privateKeyPem));
final privateKey = LicensifyKeyImporter.importPrivateKeyFromBytes(privateKeyBytes);

// Import key pair with auto type detection and compatibility check
final keyPair = LicensifyKeyImporter.importKeyPairFromStrings(
  privateKeyPem: privatePemString, 
  publicKeyPem: publicPemString,
);

// The importer automatically:
// 1. Detects key type (RSA or ECDSA)
// 2. Verifies key format correctness
// 3. Ensures key pair consistency (matching types)
```

### License Types

```dart
// Built-in types
final trial = LicenseType.trial;
final standard = LicenseType.standard;
final pro = LicenseType.pro;

// Custom types
final enterprise = LicenseType('enterprise');
final premium = LicenseType('premium');
```

### License Format

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "appId": "com.example.app",
  "createdAt": "2024-07-25T14:30:00Z",
  "expirationDate": "2025-07-25T14:30:00Z",
  "type": "pro",
  "features": {
    "maxUsers": 50,
    "modules": ["analytics", "reporting"]
  },
  "metadata": {
    "customerName": "Example Corp"
  },
  "signature": "Base64EncodedSignature..."
}
```

## 🔒 Security

1. **Private key** should be stored only on the server or licensing authority side
2. **Public key** can be safely embedded in your application
3. Code obfuscation is recommended in release builds
4. ECDSA with P-256 curve provides high security level with smaller key sizes

## 📝 License

```
SPDX-License-Identifier: LGPL-3.0-or-later
```

Created by Karim "nogipx" Mamatkazin
