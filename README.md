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
- [Low-Level Cryptographic Use Cases](#low-level-cryptographic-use-cases)
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
- **Reusable Use Cases**: Low-level cryptographic operations for custom implementations

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

### Low-Level Cryptographic Use Cases

Licensify provides several low-level use cases that can be used directly for advanced cryptographic operations:

#### Signing and Verifying Data

```dart
import 'package:licensify/licensify.dart';

// Import existing keys
final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(privateKeyPem);
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(publicKeyPem);

// Create the use cases
final signDataUseCase = SignDataUseCase();
final verifySignatureUseCase = VerifySignatureUseCase();

// Sign data with private key
final data = 'Data to be signed';
final signature = signDataUseCase(
  data: data,
  privateKey: privateKey,
  // Optionally specify a different digest algorithm
  // digest: SHA256Digest(),
);

// Verify signature with public key
final isValid = verifySignatureUseCase(
  data: data,
  signature: signature,
  publicKey: publicKey,
  // Digest should match the one used for signing
  // digest: SHA256Digest(),
);

if (isValid) {
  print('✅ Signature verified successfully');
} else {
  print('❌ Signature verification failed');
}
```

#### Encrypting and Decrypting Data

```dart
import 'package:licensify/licensify.dart';
import 'dart:typed_data';
import 'dart:convert';

// Import existing keys
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(publicKeyPem);
final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(privateKeyPem);

// Create the use cases
final encryptDataUseCase = EncryptDataUseCase(
  publicKey: publicKey,
  // Optional parameters
  aesKeySize: 256,
  hkdfSalt: 'custom-salt',
  hkdfInfo: 'custom-info',
);

final decryptDataUseCase = DecryptDataUseCase(
  privateKey: privateKey,
  // Should match the encryption parameters
  aesKeySize: 256,
  hkdfSalt: 'custom-salt',
  hkdfInfo: 'custom-info',
);

// Encrypt string data
final dataToEncrypt = 'Sensitive information';
final encryptedBytes = encryptDataUseCase.encryptString(
  data: dataToEncrypt,
  // Optional: add a magic header for format identification
  magicHeader: 'TEXT',
  formatVersion: 1,
);

// Decrypt data back to string
final decryptedString = decryptDataUseCase.decryptToString(
  encryptedData: encryptedBytes,
  // Optional: validate the expected format
  expectedMagicHeader: 'TEXT',
);

print('Original: $dataToEncrypt');
print('Decrypted: $decryptedString');

// Working with binary data
final binaryData = Uint8List.fromList([1, 2, 3, 4, 5]);
final encryptedBinaryData = encryptDataUseCase(
  data: binaryData,
  magicHeader: 'BIN1',
);

final decryptedBinaryData = decryptDataUseCase(
  encryptedData: encryptedBinaryData,
  expectedMagicHeader: 'BIN1',
);
```

### Advanced Use Cases

These low-level use cases can be combined to create custom cryptographic solutions:

```dart
import 'package:licensify/licensify.dart';
import 'dart:convert';

// Example: Create a signed message
final message = {
  'action': 'purchase',
  'item': 'Premium Subscription',
  'amount': 99.99,
  'userId': 'user123',
  'timestamp': DateTime.now().toIso8601String(),
};

// Convert to JSON string
final jsonData = jsonEncode(message);

// Sign the message
final signature = signDataUseCase(
  data: jsonData,
  privateKey: privateKey,
);

// Create the complete signed message
final signedMessage = {
  'data': message,
  'signature': signature,
};

// Later, verify the signature
final receivedMessage = signedMessage['data'] as Map<String, dynamic>;
final receivedSignature = signedMessage['signature'] as String;
final receivedJsonData = jsonEncode(receivedMessage);

final isValidSignature = verifySignatureUseCase(
  data: receivedJsonData,
  signature: receivedSignature,
  publicKey: publicKey,
);

if (isValidSignature) {
  print('✅ Message is authentic');
} else {
  print('❌ Message has been tampered with');
}
```

## 🛠 CLI Tool

Licensify includes a powerful command-line interface for managing licenses:

```bash
# Activate the package globally
dart pub global activate licensify

# Get help on available commands
licensify --help
```

### Available Commands

```bash
# Generate a key pair
licensify keygen --output ./keys --name app_keys

# Create a license request (client side)
licensify request-create --appId com.example.app --publicKey ./keys/app.public.pem --output request.bin

# Create a license request with custom extension
licensify request-create --appId com.example.app --publicKey ./keys/app.public.pem --output request.lreq --extension lreq

# Decrypt and view a license request (server side)
licensify request-read --requestFile request.bin --privateKey ./keys/app.private.pem

# Generate a license directly (server side)
licensify license-create --appId com.example.app --privateKey ./keys/app.private.pem --expiration "2025-12-31" --type pro --output license.licensify

# Generate a license with custom extension
licensify license-create --appId com.example.app --privateKey ./keys/app.private.pem --expiration "2025-12-31" --type pro --extension lic --output license.lic

# Respond to a license request (server side)
licensify license-respond --requestFile request.bin --privateKey ./keys/app.private.pem --expiration "2025-12-31" --type pro --output license.licensify

# Verify a license
licensify license-verify --license license.licensify --publicKey ./keys/app.public.pem

# Show license details
licensify license-read --license license.licensify
```

### CLI Features

- **Comprehensive License Management**: Create, verify, and manage licenses
- **License Plans**: Create and manage license plans with predefined parameters
- **Custom License Types**: Define your own license types in plans
- **Custom File Extensions**: Customize extensions for license and request files
- **Trial Licenses**: Create and manage trial licenses with automatic expiration
- **Plan-Based License Generation**: Create licenses based on predefined plans

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

// In a real app, you would use the CLI command to generate this request:
// licensify request-create --appId com.example.app --publicKey ./keys/app.public.pem --output request.lreq --extension lreq
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

// In a real scenario, you would use the CLI commands:
// licensify request-read --requestFile request.lreq --privateKey ./keys/app.private.pem
// licensify license-respond --requestFile request.lreq --privateKey ./keys/app.private.pem --expiration "2025-12-31" --type pro --output license.licensify
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