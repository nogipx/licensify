# Licensify

Advanced licensing solution for Flutter/Dart applications with robust protection and flexible options.

## Features

- 🔒 **RSA Verification**: Secure cryptographic signatures
- 🕒 **Expiration Dates**: Automatic expiration verification
- 🔄 **Custom License Types**: Standard and custom license types
- 📋 **Flexible Features**: Add custom parameters and metadata
- 💾 **Multiple Storages**: File, memory, and web storage options
- 📲 **Cross-Platform**: Works on mobile, desktop, and web (WASM)

## Installation

```yaml
dependencies:
  licensify: ^1.1.0
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

// Export license to file or bytes for distribution
final licenseBytes = generator.licenseToBytes(license);
```

### Verify Licenses in Your App

```dart
// Setup (do once at app startup)
final storage = FileLicenseStorage(
  directoryProvider: DefaultLicenseDirectoryProvider(),
  licenseFileName: 'license.dat',
);
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

### File Storage (Default for Mobile/Desktop)

```dart
final storage = FileLicenseStorage(
  directoryProvider: DefaultLicenseDirectoryProvider(),
  licenseFileName: 'license.dat',
);
```

### In-Memory Storage (Testing)

```dart
final storage = InMemoryLicenseStorage();
```

### Web Storage (WASM)

```dart
final storage = WebStorageFactory.createStorage(
  storageKey: 'app_license',
);
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
