# Licensify

[![Licensify](https://img.shields.io/pub/v/licensify?label=Licensify&logo=dart)](https://pub.dev/packages/licensify)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?link=https://pub.dev/packages/licensify/license)](https://github.com/nogipx/licensify/blob/main/LICENSE)

Licensify is a Dart library for issuing and validating software licenses backed by **PASETO v4** tokens. It provides a strongly typed façade over the cryptography primitives in `paseto_dart`, making it straightforward to build licensing workflows that remain verifiable and tamper resistant.

## Contents
- [Overview](#overview)
- [Key capabilities](#key-capabilities)
- [Command-line interface](#command-line-interface)
- [Quick start](#quick-start)
- [Data encryption](#data-encryption)
- [Key lifecycle requirements](#key-lifecycle-requirements)
- [Security guidance](#security-guidance)
- [API reference](#api-reference)
- [License](#license)

## Overview
Licensify encapsulates key generation, license issuance, validation, and symmetric encryption in a single static API. Every license is represented as a signed PASETO v4 token with an authenticated payload containing application, expiry, feature, and metadata details. The library is designed for server-side issuance and on-device or in-application validation scenarios where deterministic and verifiable behavior is critical.

## Key capabilities
### Licensing workflow
- Generate Ed25519 key pairs for signing and verifying licenses.
- Assemble signed license tokens with strongly typed payload helpers.
- Validate licenses using keys or raw key bytes, exposing structured validation results.
- Inspect validated license metadata through the `License` domain object.

### Cryptography support
- Convert between key objects and PASERK representations (`k4.local`, `k4.local-pw`, `k4.local-wrap`, `k4.seal`).
- Derive symmetric keys from passwords using Argon2id with configurable parameters.
- Encrypt and decrypt structured data using XChaCha20-Poly1305 (PASETO v4.local) tokens.
- Seal encrypted payloads to a recipient's public key and recover them with the
  matching key pair via PASERK `k4.seal` helpers.

### Developer ergonomics
- Asynchronous API surfaces for IO-bound cryptographic operations.
- Deterministic exceptions for malformed tokens and unsupported payloads.
- Memory management helpers to ensure explicit key disposal.

## Command-line interface

The package ships with a dedicated CLI that streamlines key management and PASERK
conversions without requiring you to write any Dart code. You can run it with
`dart run bin/licensify.dart ...` inside the repository, or install it globally:

```bash
dart pub global activate licensify
licensify --help
```

### Available commands

| Command | Description |
| --- | --- |
| `keypair generate` | Mint a new Ed25519 signing key pair and emit PASERK `k4.secret`, `k4.secret-pw`, `k4.secret-wrap.pie`, and identifiers. |
| `keypair info` | Inspect existing PASERK material (`k4.secret*`, `k4.public`) and re-export it in other formats. |
| `symmetric generate` | Create an XChaCha20 encryption key and export `k4.local`, `k4.local-pw`, `k4.local-wrap.pie`, and optional sealed copies. |
| `symmetric info` | Decode password-protected, wrapped, or sealed symmetric keys and convert them to other PASERK encodings. |
| `symmetric derive` | Derive an encryption key from a password + salt using Argon2id with configurable parameters. |
| `salt generate` | Produce base64url salts that satisfy PASERK `k4.local-pw` requirements. |

All commands output JSON (pretty-printed by default, disable with `--no-pretty`).
Use `-o/--output` to write the JSON response to a file and `-i/--input` to
reuse PASERK strings (plain text) or previously exported JSON when invoking
other commands. You can append `-h/--help` to any command or subcommand to see
its dedicated usage, for example `licensify symmetric -h` or
`licensify symmetric generate -h`. The command-level help now lists the
available subcommands so you can quickly discover what each area supports:

```bash
$ licensify symmetric -h
Usage: licensify symmetric <subcommand> [arguments]

Global options:
-h, --help    Show usage information.

Subcommands:
  generate  Create a new symmetric key with PASERK exports
  info      Decode or convert existing symmetric keys
  derive    Derive a key from a password and salt
```

The same pattern works for `licensify keypair -h` and `licensify salt -h` to
see their focused command lists.

```bash
# Persist generated keys and inspect them later without copy/paste.
licensify keypair generate -o secrets/signing.json
licensify keypair info -i secrets/signing.json
```

### Example

```bash
$ licensify keypair generate --password "correct horse battery staple"
{
  "type": "ed25519-keypair",
  "publicKeyPaserk": "k4.public...",
  "publicKeyId": "k4.pid...",
  "secretKeyPaserk": "k4.secret...",
  "secretKeyId": "k4.sid...",
  "passwordWrappedSecretKey": "k4.secret-pw...",
  "passwordWrapSalt": "base64url-salt...",
  "passwordWrapMemoryCost": 67108864,
  "passwordWrapTimeCost": 3,
  "passwordWrapParallelism": 1
}
```

Whenever you request a password-protected export (`--password`), the CLI also
records the Argon2 salt and cost parameters under the `passwordWrap*` keys.
Persist these values alongside the PASERK string so the key can be restored
later with `licensify symmetric derive` or the equivalent library helpers. When
deriving symmetric material, the CLI also returns `derive*` keys that describe
the salt and cost settings you provided explicitly, while the
`passwordWrap*` keys mirror the values encoded inside the emitted `k4.*-pw`
string.

Use `licensify symmetric info --paserk <value>` to unwrap `k4.local-pw`,
`k4.local-wrap.pie`, or `k4.seal` payloads by providing the required password
or companion keys via flags.

## Quick start
### Generate signing keys and create a license
```dart
import 'package:licensify/licensify.dart';

Future<void> issueLicense() async {
  final keyPair = await Licensify.generateSigningKeys();

  try {
    final license = await Licensify.createLicense(
      privateKey: keyPair.privateKey,
      appId: 'com.example.product',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
      type: LicenseType.pro,
      features: const {
        'analytics': true,
        'api_access': true,
        'max_users': 100,
      },
      metadata: const {
        'customer': 'Example Corp',
        'license_id': 'LIC-2025-001',
      },
    );

    // Persist the license token in your licensing backend or provisioning flow.
    print('License token: ${license.token}');
  } finally {
    keyPair.privateKey.dispose();
    keyPair.publicKey.dispose();
  }
}
```

### Validate a license
```dart
Future<void> validateLicense() async {
  final keyPair = await Licensify.generateSigningKeys();

  try {
    final license = await Licensify.createLicense(
      privateKey: keyPair.privateKey,
      appId: 'com.example.product',
      expirationDate: DateTime.now().add(const Duration(days: 30)),
    );

    final validation = await Licensify.validateLicense(
      license: license,
      publicKey: keyPair.publicKey,
    );

    if (!validation.isValid) {
      throw StateError('License rejected: ${validation.message}');
    }

    final appId = await license.appId;
    final features = await license.features;
    final metadata = await license.metadata;

    print('Validated license for: ' + appId);
    print('Features: ' + features.toString());
    print('Metadata: ' + (metadata ?? {}).toString());
  } finally {
    keyPair.privateKey.dispose();
    keyPair.publicKey.dispose();
  }
}
```

### Detect tampering attempts
```dart
Future<bool> isTamperedLicenseRejected() async {
  final legitimateKeys = await Licensify.generateSigningKeys();
  final attackerKeys = await Licensify.generateSigningKeys();

  try {
    final forgedLicense = await Licensify.createLicense(
      privateKey: attackerKeys.privateKey,
      appId: 'com.example.product',
      expirationDate: DateTime.now().add(const Duration(days: 999)),
      type: LicenseType.enterprise,
      features: const {'max_users': 9999},
    );

    final result = await Licensify.validateLicense(
      license: forgedLicense,
      publicKey: legitimateKeys.publicKey,
    );

    return !result.isValid;
  } finally {
    attackerKeys.privateKey.dispose();
    attackerKeys.publicKey.dispose();
    legitimateKeys.privateKey.dispose();
    legitimateKeys.publicKey.dispose();
  }
}
```

## Data encryption
```dart
Future<Map<String, dynamic>> encryptAndDecrypt() async {
  final encryptionKey = Licensify.generateEncryptionKey();

  try {
    final encryptedToken = await Licensify.encryptData(
      data: const {
        'user_id': 'user_123',
        'permissions': ['read', 'write', 'admin'],
      },
      encryptionKey: encryptionKey,
    );

    final decrypted = await Licensify.decryptData(
      encryptedToken: encryptedToken,
      encryptionKey: encryptionKey,
    );

    return decrypted;
  } finally {
    encryptionKey.dispose();
  }
}
```

```dart
Future<Map<String, dynamic>> encryptForRecipient() async {
  final keyPair = await Licensify.generateSigningKeys();

  try {
    final payload = await Licensify.encryptDataForPublicKey(
      data: const {
        'backup': 'delta',
        'issued_at': '2025-10-18T12:00:00Z',
      },
      publicKey: keyPair.publicKey,
      footer: 'backup:v1',
    );

    final recovered = await Licensify.decryptDataForKeyPair(
      payload: payload,
      keyPair: keyPair,
    );

    return recovered;
  } finally {
    keyPair.privateKey.dispose();
    keyPair.publicKey.dispose();
  }
}
```

## Key lifecycle requirements
Every `LicensifyPrivateKey`, `LicensifyPublicKey`, and `LicensifySymmetricKey` holds sensitive material in memory. Keys **must** be disposed explicitly with `.dispose()` once an operation completes. Failing to dispose keys leaves confidential bytes resident in memory until garbage collection and violates the library's security model.

## Security guidance
- Issue short-lived licenses where possible and rely on revocation metadata in your backend.
- Store signing keys in hardware security modules or dedicated secrets managers; never distribute private keys with client applications.
- Persist salts required for password-derived keys alongside encrypted payloads and protect them with the same rigor as the data they guard.
- Audit logging should record both successful and failed validations for anomaly detection.
- Treat decrypted license payloads as sensitive data and limit their exposure within your application.

## API reference
```dart
// Key management
static Future<LicensifyKeyPair> generateSigningKeys();
static LicensifyKeyPair keysFromBytes({required List<int> privateKeyBytes, required List<int> publicKeyBytes});
static LicensifySymmetricKey generateEncryptionKey();
static Future<LicensifySymmetricKey> encryptionKeyFromPassword({...});
static LicensifySymmetricKey encryptionKeyFromBytes({required List<int> keyBytes});
static LicensifySymmetricKey encryptionKeyFromPaserk({required String paserk});
static String encryptionKeyToPaserk({required LicensifySymmetricKey key});
static String encryptionKeyIdentifier({required LicensifySymmetricKey key});
static Future<LicensifySymmetricKey> encryptionKeyFromPaserkPassword({...});
static Future<String> encryptionKeyToPaserkPassword({...});
static LicensifySymmetricKey encryptionKeyFromPaserkWrap({...});
static String encryptionKeyToPaserkWrap({...});
static Future<LicensifySymmetricKey> encryptionKeyFromPaserkSeal({...});
static String encryptionKeyToPaserkSeal({...});
static LicensifySalt generatePasswordSalt({int length = K4LocalPw.saltLength});

// License creation
static Future<License> createLicense({
  required LicensifyPrivateKey privateKey,
  required String appId,
  required DateTime expirationDate,
  LicenseType type = LicenseType.standard,
  Map<String, dynamic> features = const {},
  Map<String, dynamic>? metadata,
  bool isTrial = false,
});

// License validation
static Future<License> fromToken({required String token, required LicensifyPublicKey publicKey});
static Future<License> fromTokenWithKeyBytes({...});
static Future<LicenseValidationResult> validateLicense({
  required License license,
  required LicensifyPublicKey publicKey,
});
static Future<LicenseValidationResult> validateLicenseWithKeyBytes({...});

// Data encryption
static Future<String> encryptData({required Map<String, dynamic> data, required LicensifySymmetricKey encryptionKey});
static Future<Map<String, dynamic>> decryptData({required String encryptedToken, required LicensifySymmetricKey encryptionKey});
static Future<LicensifyAsymmetricEncryptedPayload> encryptDataForPublicKey({required Map<String, dynamic> data, required LicensifyPublicKey publicKey});
static Future<Map<String, dynamic>> decryptDataForKeyPair({required LicensifyAsymmetricEncryptedPayload payload, required LicensifyKeyPair keyPair});
```

Refer to the inline API documentation for parameter details and advanced usage notes.

## License
This project is distributed under the terms of the **MIT** license. See [LICENSE](LICENSE) for the full text.

