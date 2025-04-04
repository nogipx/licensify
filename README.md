![Licensify](https://img.shields.io/pub/v/licensify?label=Licensify&labelColor=1A365D&color=1A365D&style=for-the-badge&logo=dart)
![More Projects](https://img.shields.io/badge/More_Projects-nogipx-FF6B35?style=for-the-badge&labelColor=1A365D&link=https://github.com/nogipx?tab=repositories)

![GitHub stars](https://img.shields.io/github/stars/nogipx/licensify?style=flat-square&labelColor=1A365D&color=00A67E)
![GitHub last commit](https://img.shields.io/github/last-commit/nogipx/licensify?style=flat-square&labelColor=1A365D&color=00A67E)
![License](https://img.shields.io/badge/license-LGPL-blue.svg?style=flat-square&labelColor=1A365D&color=00A67E&link=https://pub.dev/packages/licensify/license)


# Licensify

A lightweight yet powerful license management solution for Dart applications with cryptographically secure signatures.

## Overview

Licensify is a Dart library for license validation, signing, and management. It provides:

- Cryptographically secure license validation
- ECDSA signature support with legacy RSA key generation
- License request generation and sharing
- Platform-independent implementation
- Command-line interface (CLI) for license management

## 🚀 Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Examples](#-usage-examples)
- [CLI Tool](#-cli-tool)
- [Documentation](#-documentation)
- [License Request Generation](#license-request-generation)
- [Security](#security)
- [License](#license)

## 🔥 Features

- **Powerful Cryptography**: ECDSA with SHA-512 for robust protection
- **Flexible Licenses**: Built-in and custom types, metadata, and features
- **Expiration**: Automatic expiration verification
- **Schema Validation**: Validate license structures with custom schemas
- **Storage Independence**: Bring your own storage implementation
- **Cross-Platform**: Works on all platforms including web (WASM)
- **High Performance**: ECDSA up to 10x faster with 72% smaller key sizes

## 📦 Installation

```yaml
dependencies:
  licensify: ^2.0.0
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

### Legacy RSA Key Generation

```dart
// While RSA keys can still be generated for backward compatibility,
// they cannot be used for license operations in v2.0.0+
final keyPair = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

// Note: Using RSA keys for license operations will throw UnsupportedError
```

## 📚 Usage Examples

### Complete License Workflow

```dart
// SERVER: generating a license
// Import private key 
final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(privateKeyPem);
// Note: Only ECDSA keys can be used for license operations
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
// Import public key
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

## 🛠 CLI Tool

Licensify includes a command-line interface for managing licenses without writing code:

```bash
# Activate the package globally
dart pub global activate licensify

# Generate a key pair
licensify keygen --output ./keys --name customer1

# Generate a license
licensify generate --privateKey ./keys/customer1.private.pem --appId com.example.app --expiration 2025-01-01 --output license.licensify

# Verify a license
licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem

# Create a license request
licensify request --appId com.example.app --publicKey ./keys/customer1.public.pem --output request.bin

# Process a license request and generate a license
licensify respond --requestFile request.bin --privateKey ./keys/customer1.private.pem --expiration 2025-01-01
```

For detailed CLI documentation, see the **[Licensify CLI Guide](bin/README.md)** with complete commands reference and usage examples.

### Available Commands

- `keygen`: Generate a new ECDSA key pair
- `generate`: Create and sign a new license
- `verify`: Verify an existing license
- `request`: Create a license request (client-side)
- `decrypt-request`: Decrypt and view a license request (server-side)
- `respond`: Process a license request and generate a license (server-side)

## 📖 Documentation

### Key Formats and Importing

```dart
// Generate ECDSA keys (recommended)
final ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem();

// Create keys with explicit type specification
// Note: RSA keys are supported for generation only
final publicKey = LicensifyPublicKey.ecdsa(publicKeyPemString);
final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPemString);

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
// 1. Detects key type (ECDSA or RSA)
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



## License Request Generation

Licensify provides a platform-independent way to generate license requests and decrypt them. This is useful for implementing license activation in your applications.

### License Request Generation (Client-side)

```dart
import 'package:licensify/licensify.dart';
import 'dart:typed_data';
import 'dart:io';

// Load your public key - IMPORTANT: Only ECDSA keys are supported in v2.0.0+
final publicKeyString = '''
-----BEGIN PUBLIC KEY-----
...
-----END PUBLIC KEY-----
''';
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(publicKeyString);

// Verify that the key is ECDSA
if (publicKey.keyType != LicensifyKeyType.ecdsa) {
  throw UnsupportedError('Only ECDSA keys are supported for license operations');
}

// Create a license request generator from the public key
final generator = publicKey.licenseRequestGenerator(
  // Optional: customize encryption parameters
  aesKeySize: 256, 
  hkdfSalt: 'custom-salt',
  hkdfInfo: 'license-request-info',
);

// Get device hash (in real app, implement proper device info collection)
final deviceHash = await DeviceHashGenerator.getDeviceHash();

// Generate a license request
final encryptedBytes = generator(
  deviceHash: deviceHash,
  appId: 'com.example.app',
  expirationHours: 48, // default is 48 hours
);

// Save the request to a file (simple example)
final file = File('license_request.lreq');
await file.writeAsBytes(encryptedBytes);
print('License request saved to: ${file.path}');

// In a real app, you would typically share this file with the licensing server
```

### License Request Decryption (Server-side)

```dart
import 'package:licensify/licensify.dart';
import 'dart:io';
import 'dart:typed_data';

// Load the private key (server-side only)
final privateKeyString = '''
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
''';
final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(privateKeyString);

// Verify that the key is ECDSA
if (privateKey.keyType != LicensifyKeyType.ecdsa) {
  throw UnsupportedError('Only ECDSA keys are supported for license operations');
}

// Create a license request decrypter
final decrypter = privateKey.licenseRequestDecrypter();

// Read the encrypted request file
final File requestFile = File('license_request.lreq');
final Uint8List encryptedBytes = await requestFile.readAsBytes();

// Decrypt the request
final decryptedRequest = decrypter(encryptedBytes);

// Access the request data
print('App ID: ${decryptedRequest.appId}');
print('Device Hash: ${decryptedRequest.deviceHash}');
print('Created At: ${decryptedRequest.createdAt}');
print('Expires At: ${decryptedRequest.expiresAt}');

// Check if the request has expired
final bool isExpired = DateTime.now().isAfter(decryptedRequest.expiresAt);
if (isExpired) {
  print('Request has expired');
} else {
  // Generate a license for this device
  final license = privateKey.licenseGenerator(
    appId: decryptedRequest.appId,
    expirationDate: DateTime.now().add(Duration(days: 365)),
    type: LicenseType.pro,
    metadata: {
      'deviceHash': decryptedRequest.deviceHash,
    }
  );
  
  // Encode the license to bytes and send it back to the user
  final licenseBytes = LicenseEncoder.encodeToBytes(license);
  await File('license.lic').writeAsBytes(licenseBytes);
  print('License generated for device: ${decryptedRequest.deviceHash}');
}
```

### Custom Device Information Service

For platform-specific device information, implement the `IDeviceInfoService` interface:

```dart
import 'package:licensify/licensify.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class FlutterDeviceInfoService implements IDeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  @override
  Future<String> getDeviceHash() async {
    // Implement platform-specific device info collection
    final Map<String, dynamic> deviceData = await _collectDeviceData();
    
    // Generate a hash from the collected data
    return DeviceHashGenerator.generateHash(deviceData);
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