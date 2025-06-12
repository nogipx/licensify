// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

/// 🧪 Тесты для унифицированного API Licensify
///
/// Все тесты используют только secure операции с автоматической очисткой ключей.
/// Тесты следуют классическому стилю AAA (Arrange-Act-Assert) без мокирования.
void main() {
  group('🔐 Licensify Unified API Tests', () {
    group('🔑 Key Management', () {
      test('should generate signing keys with correct properties', () async {
        // Arrange & Act
        final keys = await Licensify.generateSigningKeys();

        // Assert
        expect(keys.privateKey.keyLength, 32);
        expect(keys.publicKey.keyLength, 32);
        expect(keys.privateKey.keyType, LicensifyKeyType.ed25519Public);
        expect(keys.publicKey.keyType, LicensifyKeyType.ed25519Public);
        expect(keys.isConsistent, isTrue);

        // Cleanup
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      });

      test('should generate encryption key with correct properties', () {
        // Arrange & Act
        final encryptionKey = Licensify.generateEncryptionKey();

        // Assert
        expect(encryptionKey.keyLength, 32);
        expect(encryptionKey.keyType, LicensifyKeyType.xchacha20Local);

        // Cleanup
        encryptionKey.dispose();
      });

      test('should restore keys from bytes', () async {
        // Arrange
        final originalKeys = await Licensify.generateSigningKeys();
        final keyBytes = originalKeys.asBytes;

        try {
          // Act
          final restoredKeys = Licensify.keysFromBytes(
            privateKeyBytes: keyBytes.privateKeyBytes,
            publicKeyBytes: keyBytes.publicKeyBytes,
          );

          // Assert
          expect(restoredKeys.privateKey.keyBytes, keyBytes.privateKeyBytes);
          expect(restoredKeys.publicKey.keyBytes, keyBytes.publicKeyBytes);
          expect(restoredKeys.isConsistent, isTrue);

          // Cleanup
          restoredKeys.privateKey.dispose();
          restoredKeys.publicKey.dispose();
        } finally {
          originalKeys.privateKey.dispose();
          originalKeys.publicKey.dispose();
        }
      });
    });

    group('📝 License Creation (Secure)', () {
      test('should create license with manual key management', () async {
        // Arrange
        final keys = await Licensify.generateSigningKeys();
        final appId = 'com.test.app';
        final expirationDate = DateTime.now().add(Duration(days: 30));

        try {
          // Act
          final license = await Licensify.createLicense(
            privateKey: keys.privateKey,
            appId: appId,
            expirationDate: expirationDate,
            type: LicenseType.pro,
            features: {'premium': true, 'api_access': true},
            metadata: {'customer': 'Test Corp'},
          );

          // Assert
          expect(await license.appId, appId);
          expect((await license.type).name, 'pro');
          expect((await license.features)['premium'], isTrue);
          expect((await license.features)['api_access'], isTrue);
          expect((await license.metadata)?['customer'], 'Test Corp');
          expect(await license.isTrial, isFalse);
          expect(license.token, isNotEmpty);
          expect(license.token, startsWith('v4.public.'));
        } finally {
          // Cleanup
          keys.privateKey.dispose();
          keys.publicKey.dispose();
        }
      });

      test('should create license with automatic key generation', () async {
        // Act
        final result = await Licensify.createLicenseWithKeys(
          appId: 'com.test.auto-app',
          expirationDate: DateTime.now().add(Duration(days: 7)),
          type: LicenseType('trial'),
          features: {'limited_access': true},
          isTrial: true,
        );

        // Assert
        expect(await result.license.appId, 'com.test.auto-app');
        expect((await result.license.type).name, 'trial');
        expect(await result.license.isTrial, isTrue);
        expect((await result.license.features)['limited_access'], isTrue);
        expect(result.publicKeyBytes.length, 32);
        expect(result.license.token, startsWith('v4.public.'));
      });

      test('should create trial license', () async {
        // Arrange
        final keys = await Licensify.generateSigningKeys();

        try {
          // Act
          final license = await Licensify.createLicense(
            privateKey: keys.privateKey,
            appId: 'com.test.trial',
            expirationDate: DateTime.now().add(Duration(days: 7)),
            type: LicenseType('trial'),
            isTrial: true,
            features: {'basic_access': true},
          );

          // Assert
          expect(await license.appId, 'com.test.trial');
          expect((await license.type).name, 'trial');
          expect(await license.isTrial, isTrue);
          expect((await license.features)['basic_access'], isTrue);
        } finally {
          keys.privateKey.dispose();
          keys.publicKey.dispose();
        }
      });
    });

    group('✅ License Validation (Secure)', () {
      test('should validate valid license', () async {
        // Arrange
        final keys = await Licensify.generateSigningKeys();
        final license = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.valid',
          expirationDate: DateTime.now().add(Duration(days: 30)),
          type: LicenseType.standard,
        );

        try {
          // Act
          final result = await Licensify.validateLicense(
            license: license,
            publicKey: keys.publicKey,
          );

          // Assert
          expect(result.isValid, isTrue);
          expect(result.message, contains('valid'));
        } finally {
          keys.privateKey.dispose();
          keys.publicKey.dispose();
        }
      });

      test('should reject expired license', () async {
        // Arrange
        final keys = await Licensify.generateSigningKeys();
        final license = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.expired',
          expirationDate: DateTime.now().subtract(Duration(days: 1)),
          type: LicenseType.standard,
        );

        try {
          // Act
          final result = await Licensify.validateLicense(
            license: license,
            publicKey: keys.publicKey,
          );

          // Assert
          expect(result.isValid, isFalse);
          expect(result.message, contains('expired'));
        } finally {
          keys.privateKey.dispose();
          keys.publicKey.dispose();
        }
      });

      test('should validate license with key bytes', () async {
        // Arrange
        final result = await Licensify.createLicenseWithKeys(
          appId: 'com.test.bytes',
          expirationDate: DateTime.now().add(Duration(days: 15)),
          type: LicenseType.pro,
        );

        // Act
        final validation = await Licensify.validateLicenseWithKeyBytes(
          license: result.license,
          publicKeyBytes: result.publicKeyBytes,
        );

        // Assert
        expect(validation.isValid, isTrue);
      });

      test('should validate signature only', () async {
        // Arrange
        final keys = await Licensify.generateSigningKeys();
        // Создаем просроченную лицензию
        final expiredLicense = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.signature',
          expirationDate: DateTime.now().subtract(Duration(days: 1)),
          type: LicenseType.standard,
        );

        try {
          // Act
          final result = await Licensify.validateSignature(
            license: expiredLicense,
            publicKey: keys.publicKey,
          );

          // Assert - подпись должна быть валидной, даже если лицензия просрочена
          expect(result.isValid, isTrue);
        } finally {
          keys.privateKey.dispose();
          keys.publicKey.dispose();
        }
      });

      test('should handle invalid license tokens gracefully', () async {
        // Act - пытаемся валидировать лицензию с неправильным ключом
        final validLicense = await Licensify.createLicenseWithKeys(
          appId: 'com.test.invalid',
          expirationDate: DateTime.now().add(Duration(days: 1)),
          type: LicenseType.standard,
        );

        final wrongKeys = await Licensify.generateSigningKeys();

        try {
          final result = await Licensify.validateLicense(
            license: validLicense.license,
            publicKey: wrongKeys.publicKey,
          );

          // Assert - валидация должна провалиться
          expect(result.isValid, isFalse);
          expect(result.message, contains('verification error'));
        } finally {
          wrongKeys.privateKey.dispose();
          wrongKeys.publicKey.dispose();
        }
      });
    });

    group('🔒 Data Encryption (Secure)', () {
      test('should encrypt and decrypt data', () async {
        // Arrange
        final testData = {
          'user_id': 'test123',
          'permissions': ['read', 'write'],
          'config': {'debug': true, 'timeout': 5000},
        };

        // Act - используем автогенерацию ключа для полного secure workflow
        final result = await Licensify.encryptDataWithKey(
          data: testData,
          footer: 'test_footer',
        );

        final decryptionKey = Licensify.encryptionKeyFromBytes(result.keyBytes);
        try {
          final decryptedData = await Licensify.decryptData(
            encryptedToken: result.encryptedToken,
            encryptionKey: decryptionKey,
          );

          // Assert
          expect(result.encryptedToken, startsWith('v4.local.'));
          expect(decryptedData['user_id'], testData['user_id']);
          expect(decryptedData['permissions'], testData['permissions']);
          expect(decryptedData['config'], testData['config']);
        } finally {
          decryptionKey.dispose();
        }
      });

      test('should encrypt data with automatic key generation', () async {
        // Arrange
        final testData = {
          'secret': 'top-secret-data',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Act
        final result = await Licensify.encryptDataWithKey(
          data: testData,
          footer: 'auto_generated',
        );

        // Assert
        expect(result.encryptedToken, startsWith('v4.local.'));
        expect(result.keyBytes.length, 32);

        // Verify we can decrypt
        final decryptionKey = Licensify.encryptionKeyFromBytes(result.keyBytes);
        try {
          final decryptedData = await Licensify.decryptData(
            encryptedToken: result.encryptedToken,
            encryptionKey: decryptionKey,
          );

          expect(decryptedData['secret'], testData['secret']);
          expect(decryptedData['timestamp'], testData['timestamp']);
        } finally {
          decryptionKey.dispose();
        }
      });

      test('should handle complex data structures', () async {
        // Arrange
        final complexData = {
          'nested': {
            'deep': {'value': 42},
            'array': [1, 2, 3, 'string'],
          },
          'boolean': true,
          'null_value': null,
          'number': 3.14159,
        };

        // Act - используем автогенерацию ключа
        final result = await Licensify.encryptDataWithKey(
          data: complexData,
        );

        final decryptionKey = Licensify.encryptionKeyFromBytes(result.keyBytes);
        try {
          final decrypted = await Licensify.decryptData(
            encryptedToken: result.encryptedToken,
            encryptionKey: decryptionKey,
          );

          // Assert
          expect(decrypted['nested']['deep']['value'], 42);
          expect(decrypted['nested']['array'], [1, 2, 3, 'string']);
          expect(decrypted['boolean'], isTrue);
          expect(decrypted['null_value'], isNull);
          expect(decrypted['number'], 3.14159);
        } finally {
          decryptionKey.dispose();
        }
      });
    });

    group('🛠️ Utility Functions', () {
      test('should validate license token securely', () async {
        // Arrange
        final keys = await Licensify.generateSigningKeys();
        final originalLicense = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.validate',
          expirationDate: DateTime.now().add(Duration(days: 10)),
          type: LicenseType('custom'),
          features: {'validate_test': true},
        );

        try {
          // Act - используем безопасную валидацию вместо небезопасного парсинга
          final result = await Licensify.validateLicense(
            license: originalLicense,
            publicKey: keys.publicKey,
          );

          // Assert
          expect(result.isValid, isTrue);
          expect(await originalLicense.appId, 'com.test.validate');
          expect((await originalLicense.features)['validate_test'], isTrue);
        } finally {
          keys.privateKey.dispose();
          keys.publicKey.dispose();
        }
      });

      test('should provide version information', () {
        // Act & Assert
        expect(Licensify.version, isNotEmpty);
        expect(Licensify.supportedPasetoVersions, contains('v4.public'));
        expect(Licensify.supportedPasetoVersions, contains('v4.local'));
      });
    });

    group('🛡️ Security Tests', () {
      test('should properly clean up keys after operations', () async {
        // Arrange
        final keys = await Licensify.generateSigningKeys();

        try {
          // Act - создаем лицензию с secure операцией
          final license = await Licensify.createLicense(
            privateKey: keys.privateKey,
            appId: 'com.test.security',
            expirationDate: DateTime.now().add(Duration(days: 1)),
            type: LicenseType.standard,
          );

          // Assert - лицензия создана успешно
          expect(await license.appId, 'com.test.security');

          // Act - проверяем лицензию с secure операцией
          final result = await Licensify.validateLicense(
            license: license,
            publicKey: keys.publicKey,
          );

          // Assert - валидация прошла успешно
          expect(result.isValid, isTrue);
        } finally {
          // Act - очищаем ключи
          keys.privateKey.dispose();
          keys.publicKey.dispose();

          // Assert - ключи должны быть помечены как disposed
          expect(keys.privateKey.isDisposed, isTrue);
          expect(keys.publicKey.isDisposed, isTrue);
        }
      });

      test('should handle multiple operations securely', () async {
        // Проверяем что multiple secure операции работают корректно
        for (int i = 0; i < 3; i++) {
          final result = await Licensify.createLicenseWithKeys(
            appId: 'com.test.multiple-$i',
            expirationDate: DateTime.now().add(Duration(days: i + 1)),
            type: LicenseType('test'),
          );

          expect(await result.license.appId, 'com.test.multiple-$i');
          expect(result.publicKeyBytes.length, 32);

          // Валидируем каждую лицензию
          final validation = await Licensify.validateLicenseWithKeyBytes(
            license: result.license,
            publicKeyBytes: result.publicKeyBytes,
          );

          expect(validation.isValid, isTrue);
        }
      });
    });

    group('🚨 Error Handling', () {
      test('should fail validation with wrong public key', () async {
        // Arrange
        final correctKeys = await Licensify.generateSigningKeys();
        final wrongKeys = await Licensify.generateSigningKeys();

        final license = await Licensify.createLicense(
          privateKey: correctKeys.privateKey,
          appId: 'com.test.wrong-key',
          expirationDate: DateTime.now().add(Duration(days: 1)),
          type: LicenseType.standard,
        );

        try {
          // Act
          final result = await Licensify.validateLicense(
            license: license,
            publicKey: wrongKeys.publicKey, // Неправильный ключ!
          );

          // Assert
          expect(result.isValid, isFalse);
          expect(result.message, contains('verification error'));
        } finally {
          correctKeys.privateKey.dispose();
          correctKeys.publicKey.dispose();
          wrongKeys.privateKey.dispose();
          wrongKeys.publicKey.dispose();
        }
      });

      test('should fail decryption with wrong key', () async {
        // Arrange
        final testData = {'test': 'data'};

        // Encrypt with auto-generated key
        final encryptResult =
            await Licensify.encryptDataWithKey(data: testData);
        final wrongKey = Licensify.generateEncryptionKey();

        try {
          // Act & Assert
          await expectLater(
            Licensify.decryptData(
              encryptedToken: encryptResult.encryptedToken,
              encryptionKey: wrongKey, // Неправильный ключ!
            ),
            throwsA(isA<Exception>()),
          );
        } finally {
          wrongKey.dispose();
        }
      });
    });
  });
}
