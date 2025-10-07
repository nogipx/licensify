# Changelog

All notable changes to this project will be documented in this file.

## [3.2.0] - 2025-08-30

### ✨ New Features

- **PASERK k4 Facade**: Added high-level helpers on `Licensify` to convert
  symmetric, signing, and public keys to and from PASERK strings, detect
  PASERK inputs, and compute the matching `k4.lid`, `k4.sid`, and `k4.pid`
  identifiers.
- **Password-Protected Keys**: Introduced async helpers for wrapping and
  restoring encryption and signing keys using PASERK `k4.local-pw` and
  `k4.secret-pw`, including configurable Argon2 parameters through the
  facade.
- **Key Wrapping & Sealing**: Enabled symmetric wrapping flows for
  `k4.local-wrap.pie` and `k4.secret-wrap.pie`, plus secure delivery of
  encryption keys through `k4.seal`.
- **Simplified Private Key PASERK API**: `LicensifyPrivateKey` теперь принимает
  явный `LicensifyPublicKey` при конвертации в `k4.secret`, `k4.secret-pw` и
  `k4.secret-wrap.pie`, избавляясь от скрытого кэширования и делая поток
  использования очевидным.

### 📚 Documentation

- Documented PASERK k4 formats in the README, clarifying usage scenarios for
  password-protected и публичных вариантов, объяснив необходимость передачи
  публичного ключа для `k4.secret*`, а также подчеркнув важность защищённого
  хранения `k4.local` и `k4.secret` представлений.
- Сослались на спецификацию PASERK, поясняя, что полезная нагрузка `k4.secret`
  содержит полный 64-байтовый буфер (приватный + публичный ключ) по стандарту.
- Разъяснили, что публичная часть не может быть заполнена нулями: реализации
  PASERK проверяют соответствие публичного компонента приватному ключу, поэтому
  строка с произвольными байтами будет отвергнута и даст неверные идентификаторы.

### 🧪 Testing

- Expanded the PASERK test suite with round-trips covering identifiers,
  password-protected flows, key wrapping, and sealed delivery for encryption
  and signing keys.

## [3.1.0] - 2025-06-13

### ✨ New Features

- **Token to License API**: Added `Licensify.fromToken()` method for creating License objects directly from PASETO tokens
- **Key Bytes Support**: Added `Licensify.fromTokenWithKeyBytes()` method for convenience when working with key bytes
- **Complete License Validation**: Both new methods include full cryptographic validation (signature + expiration + structure)
- **Streamlined Developer Workflow**: Developers can now easily go from stored token → validated License object in one call

### 🔧 API Improvements

- **Resolved API Mismatch**: Fixed the circular dependency where `validateLicense()` required a `License` object, but creating `License` required validation
- **Enhanced Error Handling**: Comprehensive error handling for invalid tokens, wrong keys, expired licenses, and corrupted data
- **Automatic Key Cleanup**: Both new methods automatically dispose of keys in memory for security

### 🧪 Testing

- **Comprehensive Test Suite**: Added 11 new tests covering all scenarios:
  - Positive cases: valid token restoration, key bytes support, expiration handling, trial licenses
  - Error cases: invalid formats, expired tokens, wrong keys, corrupted tokens  
  - Consistency tests: roundtrip data integrity, multiple calls consistency
- **Full Code Coverage**: All new API methods are thoroughly tested

### 📚 Documentation

- **Updated Examples**: Added demonstrations of the new API in `example/main.dart`
- **Complete API Documentation**: Full Dart documentation for both new methods with usage examples

### 🎯 Usage Example

```dart
// Simple workflow: token → License object with validation
try {
  final license = await Licensify.fromToken(
    token: storedLicenseToken,
    publicKey: publicKey,
  );
  
  // Now use the validated license
  print('App: ${await license.appId}');
  print('Expires: ${await license.expirationDate}');
  
  if (await license.isExpired) {
    showExpiredDialog();
  }
} catch (e) {
  // Handle validation errors
  showInvalidLicenseError();
} finally {
  publicKey.dispose();
}
```

---

## [3.0.0] - 2025-01-XX

### ✨ Revolutionary Changes - Complete PASETO Migration

This is a **complete rewrite** of the licensify library. The entire cryptographic foundation has been rebuilt from the ground up.

#### 🚀 New Features

- **PASETO v4.public Implementation**: Complete migration to PASETO tokens using Ed25519 signatures
- **Modern Cryptography**: Replaced all legacy RSA/ECDSA with Ed25519 + BLAKE2b
- **PasetoLicenseGenerator**: New license generator using PASETO v4.public tokens
- **PasetoLicenseValidator**: New validator with tamper-proof signature verification  
- **Real Ed25519 Key Generation**: Powered by the `cryptography` package
- **Zero Legacy Dependencies**: Removed PointyCastle, asn1lib, and crypto packages
- **Performance Boost**: Ed25519 operations ~10x faster than previous ECDSA implementation
- **Compact Tokens**: PASETO tokens are smaller and more efficient
- **Type-Safe API**: Complete Dart type safety throughout the new architecture

#### 💥 Breaking Changes

- **COMPLETE API REWRITE**: All previous classes and methods have been replaced
- **RSA/ECDSA REMOVED**: No longer supported - generate new Ed25519 keys  
- **License Format Changed**: Existing licenses cannot be validated - re-issue required
- **Dependencies Changed**: New cryptographic dependencies (cryptography, paseto_dart)
- **CLI Temporarily Disabled**: Will be restored in future versions

#### 🔄 Migration Required

**Old (v2.x) → New (v3.x)**

```dart
// OLD - No longer works
final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);
final generator = keyPair.privateKey.licenseGenerator;
final license = generator(appId: 'app', expirationDate: date);

// NEW - PASETO v4
final keyPair = await Ed25519KeyGenerator.generateKeyPair();
final generator = PasetoLicenseGenerator(privateKey: keyPair.privateKey);
final license = await generator.generateLicense(
  licenseData: {'app': 'myapp'}, 
  expirationDate: date
);
```

#### ⚡ Performance Improvements

- **Key Generation**: ~39ms per Ed25519 key pair (vs ~100ms+ for ECDSA)
- **License Generation**: ~6.6ms per license 
- **License Validation**: ~9.9ms per validation
- **Throughput**: ~151 licenses/second total throughput
- **Token Size**: ~734 characters (compact and efficient)

#### 🛡️ Security Enhancements

- **Quantum-Resistant Foundation**: Ed25519 provides better long-term security
- **No Algorithm Confusion**: PASETO v4 fixes algorithms, preventing downgrade attacks
- **Tamper-Proof Tokens**: PASETO provides built-in integrity protection
- **Modern Standards**: Follows latest cryptographic best practices

---

## [2.2.0] - 2024-XX-XX (Legacy)

### Added
- Support for importing ECDSA keys from base64 parameters
- Support for importing ECDSA keys from raw parameters  
- `EcdsaParamsConverter` utility for converting parameters to PEM format
- Methods for importing ECDSA public keys from x, y coordinates and curve name
- Methods for importing ECDSA private keys from scalar (d) value and curve name

### Deprecated
- RSA for all cryptographic operations except key generation

---

## [2.1.0] - 2024-XX-XX (Legacy)

### Added
- ECDSA key generation support as an alternative to RSA
- Utilities for comparing and choosing between RSA and ECDSA

### Fixed
- Performance improvements in key operations
- Better error handling for unsupported operations

---

## [1.0.0] - 2023-XX-XX (Legacy)

### Added
- Initial release with RSA-based license generation and validation
- Basic CLI tool
- License request/response workflow

**Note**: All versions prior to 3.0.0 are considered legacy and are no longer supported. Please upgrade to 3.0.0+ for PASETO-based modern cryptographic security.
