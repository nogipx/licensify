# Licensify

Advanced licensing solution for Flutter/Dart applications with robust protection and flexible options.

## Description

`licensify` is a lightweight yet powerful library for implementing a licensing system in your Flutter and Dart applications. The library provides a secure mechanism for license verification using cryptographic signatures and a flexible system for configuring license types.

### Key Features

- 🔒 **Robust Protection**: Using RSA for license authenticity verification
- 🕒 **Expiration Management**: Automatic verification of license expiration dates
- 🔄 **Multiple License Types**: Support for standard predefined and custom license types
- 📋 **Extensible Data**: Ability to add custom parameters to licenses
- 💾 **Flexible Storage**: Support for file storage and in-memory storage
- 📲 **Simple Implementation**: Easy integration into any Dart/Flutter application

## Installation

Add `licensify` to your `pubspec.yaml`:

```yaml
dependencies:
  licensify: ^1.0.0
```

And run:

```bash
dart pub get
```

For Flutter projects:

```bash
flutter pub get
```

## Usage

### Key Generation

```dart
import 'package:licensify/licensify.dart';

// Generate RSA keys (store in a secure place!)
final keys = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

print('Public Key:');
print(keys.publicKey);

print('Private Key:');
print(keys.privateKey);
```

### Generating a New License

```dart
import 'package:licensify/licensify.dart';

// Create a license generator with private key
final generator = GenerateLicenseUseCase(privateKey: yourPrivateKey);

// Generate a new license with a standard type
final license = generator.generateLicense(
  appId: 'com.your.app',
  expirationDate: DateTime.now().add(const Duration(days: 30)),
  type: LicenseType.pro,
  features: {'maxUsers': 10, 'canExport': true},
);

// Export to bytes for saving to a file
final licenseBytes = generator.licenseToBytes(license);
```

### Custom License Types

Licensify allows you to define your own license types beyond the standard ones:

```dart
// Define custom license types
final enterpriseType = LicenseType('enterprise');
final educationType = LicenseType('education');
final lifetimeType = LicenseType('lifetime');

// Use custom type when generating a license
final enterpriseLicense = generator.generateLicense(
  appId: 'com.your.app',
  expirationDate: DateTime.now().add(const Duration(days: 365)),
  type: enterpriseType,
  features: {'maxUsers': 100, 'priority': 'high', 'supportLevel': 'premium'},
);
```

The predefined types (`LicenseType.trial`, `LicenseType.standard`, and `LicenseType.pro`) are available for common scenarios, but you can create any custom type that fits your business model.

### License Verification

```dart
import 'package:licensify/licensify.dart';

// Create repository and validator
final storage = LicenseStorage();
final repository = LicenseRepository(storage: storage);
final validator = LicenseValidator(publicKey: yourPublicKey);

// Create a use case for verification
final licenseChecker = CheckLicenseUseCase(
  repository: repository,
  validator: validator,
);

// Check current license
final licenseStatus = await licenseChecker.checkCurrentLicense();

if (licenseStatus.isActive) {
  // License is valid
  final activeLicense = (licenseStatus as ActiveLicenseStatus).license;
  print('License active until: ${activeLicense.expirationDate}');
  print('Days remaining: ${activeLicense.remainingDays}');
  
  // Check license type
  if (activeLicense.type == LicenseType.pro) {
    enableProFeatures();
  } else if (activeLicense.type.name == 'enterprise') {
    enableEnterpriseFeatures();
  }
} else if (licenseStatus.isExpired) {
  // License is expired
  print('License has expired');
} else if (licenseStatus.isInvalid) {
  // License is invalid
  print('License is invalid (incorrect signature)');
} else if (licenseStatus.isNoLicense) {
  // No license
  print('No license installed');
} else if (licenseStatus.isError) {
  // Error during verification
  print('An error occurred during license verification');
}
```

### Saving and Loading Licenses

```dart
// Save license from file
final success = await repository.saveLicenseFromFile('path/to/license.dat');

// Save license from bytes
final licenseBytes = readLicenseBytes(); // your function to read bytes
final savedFromBytes = await repository.saveLicenseFromBytes(licenseBytes);

// Remove license
final removed = await repository.removeLicense();
```

### Different Storage Types

#### File Storage (default)

```dart
final directoryProvider = DefaultLicenseDirectoryProvider();
final storage = FileLicenseStorage(
  directoryProvider: directoryProvider,
  licenseFileName: 'license.dat',
);
final repository = LicenseRepository(storage: storage);
```

#### In-Memory Storage

```dart
// Empty in-memory storage
final storage = InMemoryLicenseStorage();

// Or storage with pre-loaded data
final licenseData = Uint8List.fromList([/* license data */]);
final storage = InMemoryLicenseStorage.withData(licenseData);

final repository = LicenseRepository(storage: storage);
```

## Architecture

The library is built on Clean Architecture principles:

- **Domain Layer**: Business logic and core entities
  - Entities: License, LicenseStatus
  - Repositories: ILicenseRepository
  - UseCases: CheckLicenseUseCase, GenerateLicenseUseCase

- **Data Layer**: Implementation of repositories and data sources
  - Repositories: LicenseRepository
  - Data Sources: 
    - FileLicenseStorage - license storage in the file system
    - InMemoryLicenseStorage - license storage in memory 
  - Validators: LicenseValidator

## License Format

A license in `licensify` is a secured data structure that contains all the necessary information to verify the rights to use your application.

### License Structure

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "appId": "com.example.myapp",
  "createdAt": "2024-07-25T14:30:00Z",
  "expirationDate": "2025-07-25T14:30:00Z",
  "type": "enterprise",
  "features": {
    "maxUsers": 50,
    "canExport": true,
    "modules": ["analytics", "reporting", "admin"]
  },
  "metadata": {
    "clientName": "Example Corp",
    "contactEmail": "support@example.com"
  },
  "signature": "Base64EncodedSignature..."
}
```

License fields:
- `id` - unique license identifier
- `appId` - unique application identifier
- `createdAt` - license creation date in ISO 8601 format
- `expirationDate` - expiration date in ISO 8601 format
- `type` - license type (can be standard "trial", "standard", "pro", or any custom name)
- `features` - additional license parameters (can be any JSON-compatible types)
- `metadata` - license metadata (e.g., client information)
- `signature` - RSA signature for license authenticity verification

### License File Format

The license is saved in a format protected against tampering using cryptographic signature:

1. License data is serialized to JSON
2. RSA signature is applied to the data using the private key
3. Verification is performed using the public key

A pair of RSA keys is used for creating and verifying licenses:
- **Private key** - used only by the developer to create licenses
- **Public key** - embedded in the application to verify license authenticity

### Security Notes

- Store the private key in a secure location and do not include it in your application code
- For enhanced security, it is recommended to use code obfuscation in release builds
- The RSA mechanism provides reliable protection against license content modification
- For special security requirements, consider additional server-side license verification

## Complete Example

Check out the complete example of library usage in [example/rsa_license_demo.dart](https://github.com/nogipx/licensify/blob/main/example/rsa_license_demo.dart).

## License

```
SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
SPDX-License-Identifier: LGPL-3.0-or-later
```

This package is distributed under the LGPL-3.0 license. Details in the LICENSE file.

---

Created with ❤️ by nogipx
