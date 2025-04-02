# Migration Guide: Upgrading to Licensify 2.0.0

This guide will help you migrate your application from Licensify 1.x to 2.0.0.

## Major Changes in 2.0.0

### Deprecation of RSA for Cryptographic Operations

In version 2.0.0, RSA support has been deprecated for all cryptographic operations including:
- License generation
- License validation
- License request generation
- License request decryption

RSA key generation and importing remain available for backward compatibility, but attempting to use RSA keys for the operations above will throw an `UnsupportedError`.

### New Cryptographic Utilities

- `ECDHCryptoUtils`: Dedicated class for ECDH encryption operations
- `ECCipher`: Class for hybrid encryption using EC keys and AES

## Migration Steps

### 1. Update Dependency

Update your `pubspec.yaml` to use the latest version:

```yaml
dependencies:
  licensify: ^2.0.0
```

### 2. Migrate from RSA to ECDSA

If you are currently using RSA keys for license operations:

#### Generate New ECDSA Keys

```dart
// Generate new ECDSA key pair
final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);

// Save these keys to replace your current RSA keys
final privateKeyPem = keyPair.privateKey.content;
final publicKeyPem = keyPair.publicKey.content;
```

#### Create Keys with Explicit Type

While the importer continues to support both RSA and ECDSA keys, you should migrate to ECDSA:

```dart
// Both of these still work in 2.0.0:
final rsaOrEcdsaKey = LicensifyKeyImporter.importPrivateKeyFromString(pemPrivateKey);
final explicitEcdsaKey = LicensifyPrivateKey.ecdsa(ecdsaPemPrivateKey);

// But using RSA keys for license operations will throw an UnsupportedError:
if (rsaOrEcdsaKey.keyType == LicensifyKeyType.rsa) {
  // Need to regenerate as ECDSA for license operations
  throw UnsupportedError('RSA keys cannot be used for license operations in 2.0.0+');
}
```

### 3. Update License Generation Code

Use imported or new ECDSA keys:

```dart
// Import with automatic type detection (still works)
final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(pemPrivateKey);

// Verify that imported key is ECDSA
if (privateKey.keyType != LicensifyKeyType.ecdsa) {
  throw UnsupportedError('Only ECDSA keys can be used for license operations');
}

// Generate license with ECDSA key
final license = privateKey.licenseGenerator(
  appId: 'com.example.app',
  expirationDate: DateTime.now().add(Duration(days: 365)),
  type: LicenseType.pro,
);
```

### 4. Update License Request Generation

License requests now only support ECDSA, but automatic detection still works:

```dart
// Import with automatic detection (still works for both key types)
final publicKey = LicensifyKeyImporter.importPublicKeyFromString(publicKeyPem);

// Check if imported key is valid for license operations
if (publicKey.keyType != LicensifyKeyType.ecdsa) {
  throw UnsupportedError('Only ECDSA keys can be used for license operations');
}

// Create a license request generator with ECDSA key
final generator = publicKey.licenseRequestGenerator(
  // Custom parameters if needed
  aesKeySize: 256,
  hkdfSalt: 'custom-salt',
  hkdfInfo: 'license-request-info',
);
```

### 5. Testing Your Migration

After migrating to ECDSA keys, ensure that:

1. All existing validation code works with ECDSA keys
2. License generation produces valid licenses
3. License request generation and decryption work correctly

## Benefits of ECDSA

Migrating to ECDSA provides several advantages:

1. **Better Performance**: ECDSA operations are significantly faster than RSA
2. **Smaller Key Sizes**: ECDSA keys are 72% smaller than RSA keys with equivalent security
3. **Future-Proof**: ECDSA is more resistant to quantum computing attacks
4. **Industry Standard**: ECDSA is widely adopted in modern cryptographic applications

## Need Help?

If you encounter any issues migrating to Licensify 2.0.0:

1. Check the [documentation](https://github.com/nogipx/licensify/blob/main/README.md)
2. Open an issue on [GitHub](https://github.com/nogipx/licensify/issues) 