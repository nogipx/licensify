![Licensify](https://img.shields.io/pub/v/licensify?label=Licensify&labelColor=1A365D&color=1A365D&style=for-the-badge&logo=dart)
![More Projects](https://img.shields.io/badge/More_Projects-nogipx-FF6B35?style=for-the-badge&labelColor=1A365D&link=https://github.com/nogipx?tab=repositories)

![GitHub stars](https://img.shields.io/github/stars/nogipx/licensify?style=flat-square&labelColor=1A365D&color=00A67E)
![GitHub last commit](https://img.shields.io/github/last-commit/nogipx/licensify?style=flat-square&labelColor=1A365D&color=00A67E)
![License](https://img.shields.io/badge/license-LPGL-blue.svg?style=flat-square&labelColor=1A365D&color=00A67E&link=https://pub.dev/packages/licensify/license)


# Licensify

A lightweight yet powerful license management solution for Dart applications with cryptographically secure signatures.

## Overview

Licensify is a Dart library for license validation, signing, and management. It provides:

- Cryptographically secure license validation
- RSA and ECDSA signature support
- License request generation and sharing
- Platform-independent implementation

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
  licensify: ^1.7.1
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
    'customerName': 'My Company',
    'contactEmail': 'support@mycompany.com',
  },
);

// Convert to bytes for transmission/storage
final bytes = LicenseEncoder.encodeToBytes(license);

// CLIENT: validating the received license
// Import public key with automatic type detection
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(publicKeyPem);
final validator = publicKey.licenseValidator;

// Read from bytes
final receivedLicense = LicenseEncoder.decodeFromBytes(bytes);

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
    "customerName": "My Company"
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

## License Request Generation

Licensify provides a platform-independent way to generate license requests. This is useful for implementing license activation in your applications.

### Basic Usage

```dart
import 'package:licensify/licensify.dart';

// Load your public key
final publicKeyString = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvtV2y6EHoHsQNH8v5hZG
5YlZOepxQ/xCh5IY5O7OYg+xEoSLgQ24MGkY7QnePxQiFpNJUwyQyQmEEp4XUZh5
NgXJKSiYLOaLMYh2AXNomR/CKn/8W2hp8qMGbpGxgJJRxR0I/pMSu/jEyGgeXOVt
R6r0UeM9Y52zu+qM0f8rXpGHVlk9Yvh5jFjIRRJjzAY6qNOZYGXwFvEkXRxBC16y
k/iuUfyPV3J0YoW+v2SgLemCCLFkBM0toIDFIw4PNRh7oyj/KLmvJ3OqUOGwUyVE
bllZnYPLFfqFXojKVOYHfUNVtWfWm6PWRxQ1XpOQvRgAD10EIxnQN5mJUBk24QCK
3QIDAQAB
-----END PUBLIC KEY-----
''';
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(publicKeyString);

// Create the request generator usecase
final useCase = GenerateLicenseRequestUseCase(
  publicKey: publicKey,
  // Optional: custom device info service
  // deviceInfoService: YourCustomDeviceInfoService(),
  // Optional: custom storage implementation
  // storage: YourCustomLicenseRequestStorage(),
);

// Generate binary license request
final requestBytes = await useCase.generateRequest(
  appId: 'com.example.app',
  expirationHours: 48, // default is 48 hours
);

// Generate and save the request (requires a storage implementation)
final filePath = await useCase.generateAndSaveRequest(
  appId: 'com.example.app',
);

// Generate, save and share the request (requires a storage implementation)
await useCase.generateAndShareRequest(
  appId: 'com.example.app',
);
```

### Custom Device Information Service

For platform-specific device information, implement the `IDeviceInfoService` interface:

```dart
import 'package:licensify/licensify.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FlutterDeviceInfoService implements IDeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  @override
  Future<String> getDeviceHash() async {
    // Implement platform-specific device info collection
    final Map<String, dynamic> deviceData = await _collectDeviceData();
    
    // Use the built-in hash generation method
    final hashGenerator = BasicDeviceInfoService();
    return hashGenerator._generateHash(deviceData);
  }
  
  Future<Map<String, dynamic>> _collectDeviceData() async {
    // Implement your platform-specific data collection
    // Example for Android:
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return {
        'id': info.id,
        'brand': info.brand,
        'model': info.model,
        // Add more identifiers
      };
    }
    
    // Add implementations for other platforms
    
    // Fallback
    return {'platform': Platform.operatingSystem};
  }
}
```

### Custom License Request Storage

For platform-specific file handling, implement the `ILicenseRequestStorage` interface:

```dart
import 'dart:io';
import 'package:licensify/licensify.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FlutterLicenseRequestStorage implements ILicenseRequestStorage {
  @override
  Future<String> saveLicenseRequest(Uint8List bytes, String appId) async {
    // Get a temporary directory
    final tempDir = await getTemporaryDirectory();
    
    // Create a file name
    final fileName = '${appId.replaceAll('.', '_')}_license_request${LicenseRequestGenerator.fileExtension}';
    
    // Create and write to the file
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    
    return file.path;
  }
  
  @override
  Future<void> shareLicenseRequest(String filePath, String appId) async {
    // Use the share_plus package to share the file
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'License request for $appId',
    );
  }
}
```
