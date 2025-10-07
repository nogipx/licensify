![Licensify](https://img.shields.io/pub/v/licensify?label=Licensify&logo=dart)
![License](https://img.shields.io/badge/license-LGPL-blue.svg?link=https://pub.dev/packages/licensify/license)

<div align="center">

# Licensify

**Modern cryptographically secure software licensing using PASETO v4 tokens**

*Quantum-resistant, tamper-proof, and high-performance licensing solution*

[Quick Start](#quick-start) • [Security](#security) • [API](#api-reference)

---

</div>

## Overview

Licensify is a professional software licensing library built on **PASETO v4** tokens, providing a cryptographically superior alternative to traditional JWT-based licensing systems.

### Why PASETO over JWT?

| Feature | JWT | **Licensify (PASETO v4)** |
|---------|-----|---------------------------|
| Algorithm Confusion | Vulnerable | **Fixed algorithms** |
| Quantum Resistance | No | **Ed25519 ready** |
| Performance | Slow | **10x faster** |
| Token Tampering | Easy | **Cryptographically impossible** |
| Key Size | 2048+ bits | **32 bytes** |

## Quick Start

### 🔑 Generate Keys & Create License

```dart
import 'package:licensify/licensify.dart';

// Method 1: Automatic key generation (recommended)
final result = await Licensify.createLicenseWithKeys(
  appId: 'com.company.product',
  expirationDate: DateTime.now().add(Duration(days: 365)),
  type: LicenseType.pro,
  features: {
    'analytics': true,
    'api_access': true,
    'max_users': 100,
  },
  metadata: {
    'customer': 'Acme Corporation',
    'license_id': 'LIC-2025-001',
  },
);

print('License: ${result.license.token}');
print('Public key: ${result.publicKeyBytes.length} bytes');
```

### ✅ Validate License

```dart
// Validate license with key bytes (production recommended)
final validation = await Licensify.validateLicenseWithKeyBytes(
  license: result.license,
  publicKeyBytes: result.publicKeyBytes,
);

if (validation.isValid) {
  print('✅ License is valid!');
  
  // Access verified license data
  final appId = await result.license.appId;
  final features = await result.license.features;
  final metadata = await result.license.metadata;
  
  // Check permissions
  if (features['analytics'] == true) {
    // Enable analytics features
  }
} else {
  print('❌ License invalid: ${validation.message}');
  // Deny access
}
```

### 🛡️ Tamper Protection

```dart
// Try to create "better" license with wrong keys
final wrongKeys = await Licensify.generateSigningKeys();
final fakeLicense = await Licensify.createLicense(
  privateKey: wrongKeys.privateKey,
  appId: 'com.company.product', // Same app ID
  expirationDate: DateTime.now().add(Duration(days: 999)), // Extended!
  type: LicenseType.enterprise, // Upgraded!
  features: {'max_users': 9999}, // More features!
);

// Try to validate with original key
final fakeValidation = await Licensify.validateLicenseWithKeyBytes(
  license: fakeLicense,
  publicKeyBytes: result.publicKeyBytes, // Original key
);

print('Fake license rejected: ${!fakeValidation.isValid}'); // true
print('Error: ${fakeValidation.message}'); // Signature verification error

// Cleanup
wrongKeys.privateKey.dispose();
wrongKeys.publicKey.dispose();
```

### 🔒 PASERK k4 Helpers

Licensify предоставляет фасадные методы для преобразования ключей в каноничные
строки PASERK и обратно:

- `k4.local` / `k4.local-pw` — для симметричных ключей шифрования. При
  необходимости ключ можно завернуть паролем, используя `Licensify.encryptionKeyToPaserkPassword()`.
- `k4.local-wrap.pie` — для обёртывания ключа шифрования другим симметричным
  ключом (например, мастер-ключом хранилища) через методы
  `Licensify.encryptionKeyToPaserkWrap()` и `Licensify.encryptionKeyFromPaserkWrap()`.
- `k4.secret` / `k4.secret-pw` — для Ed25519 пар ключей подписи. Формат хранит
  **обе** части пары (приватную и публичную) в том же 64-байтовом буфере, что и
  спецификация PASERK для `k4.secret`
  ([operations/secret.md](https://github.com/paseto-standard/paserk/blob/master/operations/secret.md)).
  Поэтому мы просим передавать `LicensifyPublicKey` даже при работе только с
  приватным ключом. Это гарантирует корректный `k4.sid` идентификатор и
  восстановление пары без скрытых зависимостей. Паролезащищённый вариант подходит
  для хранения приватных ключей в хранилищах.
  Спецификация требует **реальный** публичный ключ: при сериализации
  `paseto_dart` и другие реализации пересчитывают публичный компонент из
  приватного и проверяют, что он совпадает с переданным. Если заменить вторые 32
  байта нулями или любым другим значением, строка перестанет соответствовать
  стандарту, будет отвергнута при десериализации и приведёт к неверному
  `k4.sid`/`k4.pid`.
- `k4.secret-wrap.pie` — для шифрования пары ключей подписи симметричным ключом,
  используя `Licensify.signingKeysToPaserkWrap()` и
  `Licensify.signingKeysFromPaserkWrap()`.
- `k4.public` — для публичных ключей подписи. Этот формат уже предназначен для
  открытого распространения, поэтому дополнительное шифрование паролем не
  требуется.
- `k4.seal` — для безопасной передачи симметричного ключа держателю Ed25519
  публичного ключа. Используйте `Licensify.encryptionKeyToPaserkSeal()` для
  запечатывания и `Licensify.encryptionKeyFromPaserkSeal()` для восстановления
  ключа получателем.

Каждый формат сопровождается идентификатором (`k4.lid`, `k4.sid`, `k4.pid`),
который удобно использовать в логах и метаданных для ссылки на конкретный ключ
без раскрытия его содержимого.

> ℹ️ **Важно.** Представления `k4.local` и `k4.secret` остаются «сырыми» ключами.
> PASERK лишь кодирует материал в строку, поэтому такие ключи по-прежнему нужно
> хранить в защищённом хранилище (HSM, KMS, Secrets Manager и т. п.) или
> использовать паролезащищённые/обёрнутые варианты (`k4.local-pw`,
> `k4.secret-pw`, `k4.local-wrap.pie`, `k4.secret-wrap.pie`).

### Как упростить фасад Licensify

Хотя фасад `Licensify` стремится закрыть все сценарии единым набором статических
методов, по мере роста функций API превратился в «швейцарский нож» с десятками
однотипных вызовов: генерация ключей, конверсия PASERK, выпуск лицензий и
валидация все живут рядом, что усложняет onboarding и поддержку.【F:lib/src/licensify.dart†L21-L237】
Ниже — несколько идей, которые помогут сделать фасад компактнее без потери
возможностей:

- **Разделить домены на подпакеты.** Выделите небольшие объекты вроде
  `Licensify.keys`, `Licensify.paserk` и `Licensify.licenses`, чтобы сгруппировать
  родственные операции вместо сотни статических методов в одном интерфейсе.
  Например, все функции вокруг `k4.local`/`k4.secret` смогут жить внутри
  `Licensify.paserk`, а создание/валидация лицензий — внутри
  `Licensify.licenses`.
- **Инкапсулировать повторяющиеся параметры.** Паролезащищённые методы для
  `k4.local-pw` и `k4.secret-pw` постоянно требуют `memoryCost`, `timeCost` и
  `parallelism` с одинаковыми значениями по умолчанию.【F:lib/src/licensify.dart†L100-L187】
  Выделите класс-конфиг `PaserkPasswordParams` и передавайте один объект вместо
  набора позиционных аргументов — это снимет нагрузку на вызовы и облегчит
  чтение кода.
- **Возвращать связки результатов.** Сейчас, чтобы получить строку PASERK и её
  идентификатор, нужно делать два отдельных вызова (`encryptionKeyToPaserk` и
  `encryptionKeyIdentifier`, `signingKeysToPaserk` и `signingKeyIdentifier`).【F:lib/src/licensify.dart†L76-L164】
  Введите небольшие value-объекты (`PaserkSecret`, `PaserkLocal`), которые сразу
  содержат строку и `k4.*id`. Тогда разработчикам не придётся помнить, что
  идентификатор добывается другим методом.
- **Добавить «потоковые» помощники.** В сценариях с приватным ключом требуется
  вручную пробрасывать публичный ключ в каждый вызов `k4.secret*`, что ведёт к
  шуму в пользовательском коде.【F:lib/src/licensify.dart†L151-L206】 Можно
  предоставить метод наподобие `Licensify.paserk.forKeyPair(keyPair)`/`forKeys`
  (принимающий `privateKey` и `publicKey`) и возвращающий объект с уже
  привязанным контекстом, внутри которого вызовы `toSecret()`,
  `toSecretPassword()` и `toSecretWrap()` не потребуют повторного указания
  публичного ключа.

Такие шаги не ломают обратную совместимость (старые статические методы можно
перевести в deprecated-режим), но заметно облегчают документацию и снижают
порог входа для новых пользователей.

## Key Features

### 🔐 Security-by-Design
- **Secure-only API**: Impossible to create licenses without cryptographic validation
- **Tamper-proof**: Any modification invalidates the signature instantly
- **Quantum-resistant**: Ed25519 provides 128-bit security level

### ⚡ Performance
- **Fast**: ~151 licenses/second throughput
- **Compact**: 32-byte keys vs 2048+ bit RSA
- **Efficient**: Automatic key cleanup and disposal

### 🛠️ Developer Experience
- **Type-safe**: Full Dart type safety with async/await
- **Unified API**: Single `Licensify` class for all operations
- **Automatic cleanup**: Built-in memory management

## Security

### Cryptographic Foundation
```
Algorithm:    Ed25519 (Curve25519)
Token Format: PASETO v4.public
Security:     128-bit quantum-resistant
Key Size:     32 bytes
```

### Production Best Practices

```dart
// Use short-lived tokens
final license = await Licensify.createLicense(
  privateKey: keys.privateKey,
  appId: 'com.company.app',
  expirationDate: DateTime.now().add(Duration(minutes: 15)), // Short-lived
  type: LicenseType.standard,
  metadata: {
    'jti': generateUniqueId(), // Prevents replay attacks
  },
);

// Always dispose keys
try {
  // Use license...
} finally {
  keys.privateKey.dispose();
  keys.publicKey.dispose();
}
```

## Advanced Usage

### Enterprise License Validation

```dart
class LicenseManager {
  static Future<bool> validateEnterpriseLicense(
    String licenseToken,
    List<int> publicKeyBytes,
  ) async {
    try {
      final license = License.fromToken(licenseToken);
      final result = await Licensify.validateLicenseWithKeyBytes(
        license: license,
        publicKeyBytes: publicKeyBytes,
      );
      
      if (!result.isValid) return false;
      
      // All data is cryptographically verified
      final type = await license.type;
      final features = await license.features;
      
      // Business validation
      return type.name == 'enterprise' && 
             features['user_management'] == true;
             
    } catch (e) {
      return false;
    }
  }
}
```

### Data Encryption

```dart
// Encrypt sensitive data
final encryptionResult = await Licensify.encryptDataWithKey(
  data: {
    'user_id': 'user_123',
    'permissions': ['read', 'write', 'admin'],
  },
);

// Decrypt data
final decryptionKey = Licensify.encryptionKeyFromBytes(encryptionResult.keyBytes);
try {
  final decryptedData = await Licensify.decryptData(
    encryptedToken: encryptionResult.encryptedToken,
    encryptionKey: decryptionKey,
  );
} finally {
  decryptionKey.dispose();
}
```

## API Reference

### Core Methods

```dart
// Key Management
static Future<LicensifyKeyPair> generateSigningKeys()
static LicensifySymmetricKey generateEncryptionKey()

// License Creation
static Future<License> createLicense({...})
static Future<({License license, List<int> publicKeyBytes})> createLicenseWithKeys({...})

// License Validation
static Future<LicenseValidationResult> validateLicense({...})
static Future<LicenseValidationResult> validateLicenseWithKeyBytes({...})

// Data Encryption
static Future<Map<String, dynamic>> encryptData({...})
static Future<Map<String, dynamic>> decryptData({...})
```

## License

This project is licensed under the **LGPL-3.0-or-later** license.

---

<div align="center">

**Developed by [Karim "nogipx" Mamatkazin](https://github.com/nogipx)**

[⭐ Star](https://github.com/nogipx/licensify) • [🐛 Issues](https://github.com/nogipx/licensify/issues)

</div>