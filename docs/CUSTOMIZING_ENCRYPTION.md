# Customizing License Request Encryption in Licensify

This guide explains how to use the custom encryption parameters in Licensify when generating and decrypting license requests, including support for different elliptic curves like p521.

## Overview

Licensify now provides advanced customization options for license request encryption:

- Configurable AES key size (128, 192, 256 bits)
- Customizable HKDF digest algorithm 
- Custom salt and info strings for key derivation
- Support for different elliptic curves (p256, p384, p521, secp256k1)

These features allow you to:
- Increase security for highly sensitive applications
- Match your organizational security policies
- Support specific compliance requirements

## Generating License Requests with Custom Parameters

### Using a Stronger Curve

The default curve is p256, but you can use stronger curves like p521 for higher security:

```dart
// Generate a key pair with p521 curve
final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p521);

// Create a basic generator with p521 public key
final generator = keyPair.publicKey.licenseRequestGenerator();

// Generate license request
final requestBytes = generator(
  deviceHash: deviceHash,
  appId: appId,
);
```

### Customizing Encryption Parameters

For complete customization:

```dart
// Create generator with fully customized parameters
final generator = publicKey.licenseRequestGenerator(
  // Custom AES key size (128, 192, or 256 bits)
  aesKeySize: 192,
  
  // Custom digest algorithm for HKDF
  hkdfDigest: SHA384Digest(),
  
  // Custom salt and info for HKDF
  hkdfSalt: 'YOUR-ORGANIZATION-ECDH-SALT',
  hkdfInfo: 'YOUR-APPLICATION-AES-KEY',
);

// Generate request with custom expiration time
final requestBytes = generator(
  deviceHash: deviceHash,
  appId: appId,
  expirationHours: 24, // Custom expiration (default is 48 hours)
);
```

## Decrypting License Requests on the Server

When using custom encryption parameters, the server must use the same parameters:

```dart
// Server-side decryption with matching custom parameters
final decoder = privateKey.licenseRequestDecoder(
  aesKeySize: 192,
  hkdfDigest: SHA384Digest(),
  hkdfSalt: 'YOUR-ORGANIZATION-ECDH-SALT',
  hkdfInfo: 'YOUR-APPLICATION-AES-KEY',
);

// Decrypt the received request
final licenseRequest = decoder(receivedBytes);
```

## Integration with Dependency Injection

For production applications using dependency injection:

```dart
// Register the custom generator in your DI container
container.register<ILicenseRequestGenerator>((c) => 
  c.resolve<LicensifyPublicKey>().licenseRequestGenerator(
    aesKeySize: 192,
    hkdfDigest: SHA384Digest(),
    hkdfSalt: 'YOUR-ORGANIZATION-ECDH-SALT',
    hkdfInfo: 'YOUR-APPLICATION-AES-KEY',
  )
);

// Or register the use case
container.register<GenerateLicenseRequestUseCase>((c) => 
  GenerateLicenseRequestUseCase(
    publicKey: c.resolve<LicensifyPublicKey>(),
    generatorFactory: () => c.resolve<ILicenseRequestGenerator>(),
    deviceInfoService: c.resolve<IDeviceInfoService>(),
    storage: c.resolve<ILicenseRequestStorage>(),
  )
);
```

## Security Considerations

- **Parameters Consistency**: Always use the exact same parameters for encryption and decryption.
- **Key Size**: Larger AES keys (256-bit) provide more security at the cost of slightly increased processing time.
- **Curve Selection**: 
  - p256: Good balance of security and performance (128-bit security)
  - p384: Higher security (192-bit)
  - p521: Highest security (256-bit) but more computational cost
  - secp256k1: Used in blockchain applications (128-bit)
- **Salt and Info**: Use unique values for your organization and application to prevent rainbow table attacks.

## Performance Considerations

- **p521 Curve**: Uses larger key sizes and requires more computation
- **SHA-512**: Slower than SHA-256 but provides higher security
- **256-bit AES**: Slightly slower than 128-bit AES

For most applications, the default parameters (p256 curve, SHA-256, 256-bit AES) provide an excellent balance of security and performance. Only customize if you have specific security requirements. 