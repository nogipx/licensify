# Licensify

Advanced licensing solution for Flutter/Dart applications with robust protection and flexible options.

## Features

- 🔒 **RSA Verification**: Secure cryptographic signatures
- 🕒 **Expiration Dates**: Automatic expiration verification
- 🔄 **Custom License Types**: Standard and custom license types
- 📋 **Flexible Features**: Add custom parameters and metadata
- 💾 **Storage Independence**: Bring your own storage solution
- 📲 **Cross-Platform**: Works on all platforms including web (WASM)

## Installation

```yaml
dependencies:
  licensify: ^1.2.2
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
  features: {'maxUsers': 10, 'modules': ['reporting', 'export']},
);

// Export license to bytes for distribution
final licenseBytes = generator.licenseToBytes(license);
```

### Verify Licenses in Your App

```dart
// Setup (do once at app startup)
// Use your own storage mechanism or use built-in InMemoryLicenseStorage for testing
final storage = InMemoryLicenseStorage();
final repository = LicenseRepository(storage: storage);
final validator = LicenseValidator(publicKey: yourPublicKey); 
final licenseChecker = CheckLicenseUseCase(
  repository: repository,
  validator: validator,
);

// Check license
final status = await licenseChecker.checkCurrentLicense();
if (status.isActive) {
  final license = (status as ActiveLicenseStatus).license;
  // Enable features based on license type and features
  if (license.type == LicenseType.pro || license.type.name == 'enterprise') {
    enableProFeatures();
  }
} else {
  // Handle invalid/expired/missing license
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

## License Monitoring

```dart
final monitor = MonitorLicenseUseCase(repository: repository, validator: validator);

// Auto-check license status periodically
monitor.startMonitoring(
  onStatusChanged: (status) {
    // Update UI based on status
  }
);
```

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
    "clientName": "Example Corp"
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
