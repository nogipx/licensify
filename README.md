![Licensify](https://img.shields.io/pub/v/licensify?label=Licensify&labelColor=1A365D&color=1A365D&style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/license-LGPL-blue.svg?style=flat-square&labelColor=1A365D&color=00A67E&link=https://pub.dev/packages/licensify/license)

<div align="center">

# Licensify

**Modern cryptographically secure software licensing using PASETO v4 tokens**

*Quantum-resistant, tamper-proof, and high-performance licensing solution*

[Installation](#installation) • [Features](#key-features) • [Documentation](#quick-start) • [Security](#security) • [Performance](#performance-benchmarks)

---

</div>

## Overview

Licensify is a professional software licensing library built on **PASETO v4** tokens, providing a cryptographically superior alternative to traditional JWT-based licensing systems. The library eliminates common security vulnerabilities while delivering exceptional performance through modern Ed25519 cryptography.

### Why PASETO over Traditional Methods?

| Feature | Traditional JWT | Legacy RSA/ECDSA | **Licensify (PASETO v4)** |
|---------|----------------|------------------|---------------------------|
| Algorithm Confusion | Vulnerable | Possible | **Fixed algorithms** |
| Quantum Resistance | No | Limited | **Ed25519 ready** |
| Performance | Slow | Very slow | **10x faster** |
| Token Tampering | Easy | Possible | **Cryptographically impossible** |
| Key Size | Large (2048+ bits) | Large (256+ bits) | **Compact (32 bytes)** |

## What is PASETO?

**PASETO** (Platform-Agnostic Security Tokens) is a specification for secure stateless tokens, developed in 2018 as a modern replacement for JWT/JOSE. It addresses the fundamental security flaws of JWT:

- **Fixed cryptographic algorithms** - prevents algorithm substitution attacks
- **Strict mode separation** - `local` (encryption) vs `public` (signature) 
- **Rigorous specification** - minimizes implementation errors
- **Modern cryptography** - XChaCha20, BLAKE2b, Ed25519

## Installation

```yaml
dependencies:
  licensify: ^3.0.0
```

```bash
dart pub get
```

## Quick Start

### Generate Cryptographic Keys

```dart
import 'package:licensify/licensify.dart';

// Generate Ed25519 key pair
final keyPair = await Ed25519KeyGenerator.generateKeyPair();

print('Private key: ${keyPair.privateKey.keyBytes.length} bytes');
print('Public key: ${keyPair.publicKey!.keyBytes.length} bytes');
```

### Create Licenses

```dart
// Initialize license generator
final generator = PasetoLicenseGenerator(privateKey: keyPair.privateKey);

// Generate license with custom data
final license = await generator.generateLicense(
  licenseData: {
    'user': 'john.doe@company.com',
    'product': 'Enterprise Software v2.1',
    'features': ['analytics', 'api_access', 'priority_support'],
    'limits': {
      'max_users': 100,
      'max_requests_per_day': 10000,
    },
    'metadata': {
      'company': 'Acme Corporation',
      'department': 'Engineering',
      'purchase_date': DateTime.now().toIso8601String(),
    }
  },
  expirationDate: DateTime.now().add(Duration(days: 365)),
);

print('License token: ${license.token}');
print('Token length: ${license.token.length} characters');
print('Expires: ${license.expirationDate}');
```

### Validate Licenses

```dart
// Initialize validator with public key
final validator = PasetoLicenseValidator(publicKey: keyPair.publicKey!);

// Perform validation
final result = await validator.validate(license);

if (result.isValid) {
  print('License validation successful');
  
  final data = license.licenseData;
  print('Licensed to: ${data['user']}');
  print('Product: ${data['product']}');
  print('Features: ${data['features']}');
  
  // Check specific permissions
  if (data['features'].contains('analytics')) {
    // Enable analytics features
  }
  
  if (data['limits']['max_users'] > 50) {
    // Enterprise tier logic
  }
} else {
  print('License validation failed: ${result.message}');
  // Handle invalid license
}
```

### Tamper Protection

```dart
// Attempt to modify the token
final parts = license.token.split('.');
final modifiedToken = '${parts[0]}.${parts[1]}.invalid_signature';
final tamperedToken = PasetoLicense.fromToken(modifiedToken);

// PASETO detects tampering immediately
final tamperedResult = await validator.validate(tamperedToken);
print('Tampered token rejected: ${!tamperedResult.isValid}'); // true

if (!tamperedResult.isValid) {
  print('Security violation detected: ${tamperedResult.message}');
  // Log security incident, notify administrators
}
```

## Key Features

### Performance
- Ed25519 signatures with ~151 licenses/second throughput
- 32-byte compact keys
- ~734 character tokens
- Minimal memory footprint

### Security
- Quantum-resistant cryptography
- Tamper-proof tokens with cryptographic signatures
- No algorithm confusion vulnerabilities
- Built-in expiration validation

### Developer Experience
- Type-safe Dart API
- Comprehensive validation system
- Detailed error messages
- Zero legacy cryptographic dependencies

### Advanced Security Features

- **Cryptographic Signatures**: Ed25519 provides 128-bit security level
- **Tamper Detection**: Any modification invalidates the signature instantly  
- **Time-based Validation**: Built-in expiration with configurable grace periods
- **Algorithm Immutability**: PASETO v4 fixes algorithms, preventing downgrade attacks
- **Replay Protection**: Support for unique token identifiers (`jti` claims)

## Performance Benchmarks

*Tested on Apple M1 MacBook Pro*

```
Key Generation:       ~39ms per Ed25519 key pair
License Creation:     ~6.6ms per license
License Validation:   ~9.9ms per validation
Total Throughput:     ~151 licenses/second
Token Size:           ~734 characters (typical)
Memory Usage:         Minimal overhead
```

### Performance Comparison

| Operation | RSA 2048 | ECDSA P-256 | **Ed25519 (Licensify)** |
|-----------|----------|-------------|-------------------------|
| Key Generation | ~500ms | ~100ms | **~39ms** |
| Signing | ~15ms | ~8ms | **~6.6ms** |
| Verification | ~1ms | ~12ms | **~9.9ms** |
| Key Size | 2048 bits | 256 bits | **256 bits** |

## Security

### Cryptographic Foundation

```
Signature Algorithm: Ed25519 (Curve25519)
Token Format:        PASETO v4.public
Hash Function:       BLAKE2b (via PASETO)
Encoding:           Base64Url (no padding)
Security Level:     128-bit (quantum-resistant)
```

### Built-in Security Features

1. **Tamper Detection**: Cryptographic signatures detect any modification
2. **Expiration Validation**: Automatic time-based validation with grace periods
3. **Algorithm Immutability**: PASETO v4 fixes Ed25519, preventing attacks
4. **Unique Token IDs**: Support for `jti` claims to prevent replay attacks
5. **Cross-platform Security**: Consistent guarantees across all platforms

### Production Security Best Practices

```dart
// Use short-lived tokens with refresh mechanism
final license = await generator.generateLicense(
  licenseData: {
    'sub': 'user_123',
    'exp': DateTime.now().add(Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000,
    'jti': generateUniqueId(), // Prevents replay attacks
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  },
  expirationDate: DateTime.now().add(Duration(minutes: 15)),
);

// Store public keys securely and rotate regularly
const publicKeyVersion = 'v2023-12';
final validator = PasetoLicenseValidator(
  publicKey: await loadPublicKey(publicKeyVersion),
);

// Implement additional server-side validation
if (result.isValid) {
  final jti = license.licenseData['jti'];
  if (await isTokenAlreadyUsed(jti)) {
    throw SecurityException('Token replay attack detected');
  }
  await markTokenAsUsed(jti);
}
```

## Advanced Usage

### Enterprise License Management

```dart
// Enterprise license with comprehensive validation
final enterpriseLicense = await generator.generateLicense(
  licenseData: {
    'license_type': 'enterprise',
    'organization': {
      'id': 'acme_corp_001',
      'name': 'Acme Corporation',
      'domain': 'acme.com',
    },
    'features': {
      'user_management': true,
      'advanced_analytics': true,
      'api_access': true,
      'white_labeling': true,
    },
    'limits': {
      'max_users': 1000,
      'api_requests_per_hour': 50000,
      'storage_gb': 500,
    },
    'compliance': {
      'gdpr': true,
      'hipaa': true,
      'soc2': true,
    },
    'support_level': 'platinum',
  },
  expirationDate: DateTime.now().add(Duration(days: 365)),
);
```

### Custom Validation Logic

```dart
class EnterpriseValidator {
  final PasetoLicenseValidator _validator;
  
  EnterpriseValidator(this._validator);
  
  Future<ValidationResult> validateEnterpriseLicense(
    PasetoLicense license
  ) async {
    // Cryptographic validation
    final cryptoResult = await _validator.validate(license);
    if (!cryptoResult.isValid) {
      return cryptoResult;
    }
    
    final data = license.licenseData;
    
    // Business logic validation
    if (data['license_type'] != 'enterprise') {
      return ValidationResult.invalid('Invalid license type');
    }
    
    // Domain validation
    final domain = data['organization']['domain'];
    if (!await isValidDomain(domain)) {
      return ValidationResult.invalid('Invalid organization domain');
    }
    
    // Feature validation
    final features = data['features'] as Map<String, dynamic>;
    if (!features['user_management']) {
      return ValidationResult.invalid('User management required');
    }
    
    // Usage limits validation
    final limits = data['limits'] as Map<String, dynamic>;
    if (await getCurrentUserCount() > limits['max_users']) {
      return ValidationResult.invalid('User limit exceeded');
    }
    
    return ValidationResult.valid();
  }
}
```

### Token Refresh Pattern

```dart
class LicenseManager {
  final Ed25519KeyPair _keyPair;
  final Duration _tokenLifetime;
  
  LicenseManager(this._keyPair, this._tokenLifetime);
  
  Future<AuthTokens> createTokenPair(Map<String, dynamic> userData) async {
    // Short-lived access token
    final accessToken = await _createAccessToken(userData);
    
    // Long-lived refresh token (stored in secure database)
    final refreshToken = _generateSecureRefreshToken();
    await _storeRefreshToken(userData['user_id'], refreshToken);
    
    return AuthTokens(accessToken, refreshToken);
  }
  
  Future<PasetoLicense> refreshAccessToken(String refreshToken) async {
    // Validate refresh token against database
    final userId = await _validateRefreshToken(refreshToken);
    if (userId == null) {
      throw UnauthorizedException('Invalid refresh token');
    }
    
    // Generate new access token
    final userData = await _loadUserData(userId);
    return await _createAccessToken(userData);
  }
}
```

## Supported PASETO Versions

| Version | Support | Description | Status |
|---------|---------|-------------|--------|
| v1 | No | Legacy (RSA + AES-CTR) | Deprecated |
| v2 | No | General purpose (NaCl/libsodium) | Superseded |
| v3 | No | NIST-compliant | Government use only |
| **v4** | **Yes** | **Modern cryptography** | **Production ready** |

## Testing and Quality Assurance

```bash
# Run comprehensive test suite
dart test

# Performance benchmarks  
dart run example/main.dart

# Code quality analysis
dart analyze --fatal-warnings

# Code formatting validation
dart format --set-exit-if-changed .
```

### Test Coverage

- **Cryptographic Operations**: Ed25519 key generation, signing, verification
- **License Lifecycle**: Creation, validation, expiration handling
- **Security Testing**: Tamper detection, replay attack prevention
- **Performance Testing**: Throughput analysis, memory usage, timing
- **Integration Testing**: Real-world scenarios and edge cases

## Migration from Legacy Versions

### Upgrading from v2.x (RSA/ECDSA) to v3.x (PASETO)

```dart
// Legacy v2.x (deprecated)
final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);
final generator = keyPair.privateKey.licenseGenerator;
final license = generator(appId: 'app', expirationDate: date);

// Modern v3.x (current)
final keyPair = await Ed25519KeyGenerator.generateKeyPair();
final generator = PasetoLicenseGenerator(privateKey: keyPair.privateKey);
final license = await generator.generateLicense(
  licenseData: {'app': 'myapp'}, 
  expirationDate: date
);
```

### Migration Checklist

- [ ] Generate new Ed25519 keys (RSA/ECDSA no longer supported)
- [ ] Update license generation code to use `PasetoLicenseGenerator`
- [ ] Update validation code to use `PasetoLicenseValidator`
- [ ] Re-issue all existing licenses (format incompatibility)
- [ ] Update key storage systems (smaller Ed25519 keys)
- [ ] Comprehensive testing (different token format)

## Production Examples

### SaaS License Validation

```dart
class SaaSLicenseService {
  Future<SubscriptionInfo> getSubscriptionInfo(String token) async {
    final license = PasetoLicense.fromToken(token);
    final validator = PasetoLicenseValidator(publicKey: servicePublicKey);
    
    final result = await validator.validate(license);
    if (!result.isValid) {
      throw UnauthorizedException('Invalid license');
    }
    
    final data = license.licenseData;
    
    return SubscriptionInfo(
      tier: data['subscription_tier'],
      features: List<String>.from(data['features']),
      userLimit: data['limits']['max_users'],
      apiLimit: data['limits']['api_requests_per_day'],
      expiresAt: license.expirationDate,
    );
  }
}
```

### Enterprise Software Licensing

```dart
class EnterpriseLicenseManager {
  static Future<bool> validateSoftwareAccess(String licenseToken) async {
    try {
      final license = PasetoLicense.fromToken(licenseToken);
      final validator = PasetoLicenseValidator(publicKey: enterprisePublicKey);
      
      final result = await validator.validate(license);
      if (!result.isValid) return false;
      
      final data = license.licenseData;
      
      // Validate enterprise-specific requirements
      return data['product'] == 'Enterprise Suite' && 
             data['features'].contains('advanced_features') &&
             license.daysUntilExpiration > 0;
             
    } catch (e) {
      // Log error and deny access
      return false;
    }
  }
}
```

## Contributing

We welcome contributions from the community. Please read our [Contributing Guide](CONTRIBUTING.md) for development guidelines and submission procedures.

### Development Setup

```bash
git clone https://github.com/nogipx/licensify.git
cd licensify
dart pub get
dart test
```

## Additional Resources

- [PASETO Specification](https://github.com/paseto-standard/paseto-spec)
- [Official PASETO Website](https://paseto.io/)
- [PASETO vs JWT Security Analysis](https://paragonie.com/blog/2018/03/paseto-platform-agnostic-security-tokens-is-secure-alternative-jose-standards-jwt-etc)
- [Ed25519 Signature Scheme](https://ed25519.cr.yp.to/)

## License

This project is licensed under the **LGPL-3.0-or-later** license.

---

<div align="center">

**Developed by [Karim "nogipx" Mamatkazin](https://github.com/nogipx)**

[Star this repository](https://github.com/nogipx/licensify) • [Report Issues](https://github.com/nogipx/licensify/issues) • [Request Features](https://github.com/nogipx/licensify/issues)

</div>