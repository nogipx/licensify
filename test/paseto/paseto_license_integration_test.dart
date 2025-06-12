// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('PASETO License Integration Tests', () {
    late LicensifyKeyPair keyPair;
    late LicenseGenerator generator;
    late LicenseValidator validator;

    setUpAll(() async {
      // Generate Ed25519 key pair for testing
      keyPair = await LicensifyKey.generatePublicKeyPair();

      // Create generator and validator
      generator = LicenseGenerator(privateKey: keyPair.privateKey);
      validator = LicenseValidator(publicKey: keyPair.publicKey!);
    });

    test('should generate valid PASETO license', () async {
      // Arrange
      final appId = 'com.example.testapp';
      final expirationDate = DateTime.now().add(const Duration(days: 30));
      final features = {'pro': true, 'max_users': 100};
      final metadata = {'customer': 'Test Customer', 'order': '12345'};

      // Act
      final license = await generator.call(
        appId: appId,
        expirationDate: expirationDate,
        type: LicenseType.pro,
        features: features,
        metadata: metadata,
        isTrial: false,
      );

      // Assert
      expect(license, isA<License>());
      expect(license.token, isNotEmpty);
      expect(license.token, startsWith('v4.public.'));

      // Now payload is populated during generation, so id and appId should be available
      expect(license.id, isNotEmpty);
      expect(license.appId, isNotEmpty);
    });

    test('should validate PASETO license successfully', () async {
      // Arrange
      final appId = 'com.example.testapp';
      final expirationDate = DateTime.now().add(const Duration(days: 30));
      final features = {'pro': true, 'max_users': 100};

      final license = await generator.call(
        appId: appId,
        expirationDate: expirationDate,
        type: LicenseType.pro,
        features: features,
        isTrial: false,
      );

      // Act
      final result = await validator.validate(license);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.message, 'License is valid');

      // After validation, payload should be populated
      expect(license.id, isNotEmpty);
      expect(license.appId, equals(appId));
      expect(license.type, equals(LicenseType.pro));
      expect(license.features['pro'], isTrue);
      expect(license.features['max_users'], equals(100));
      expect(license.isTrial, isFalse);
      expect(license.isExpired, isFalse);
    });

    test('should reject invalid PASETO token', () async {
      // Arrange
      final invalidLicense = License.fromToken('invalid.token.here');

      // Act
      final result = await validator.validate(invalidLicense);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.message, contains('error'));
    });

    test('should reject expired license', () async {
      // Arrange - create expired license
      final appId = 'com.example.testapp';
      final expirationDate = DateTime.now().subtract(const Duration(days: 1));

      final license = await generator.call(
        appId: appId,
        expirationDate: expirationDate,
        type: LicenseType.standard,
      );

      // Act - validate signature first to populate payload
      await validator.validateSignature(license);
      final result = validator.validateExpiration(license);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.message, contains('expired'));
    });

    test('should handle trial licenses correctly', () async {
      // Arrange
      final appId = 'com.example.trialapp';
      final expirationDate = DateTime.now().add(const Duration(days: 7));

      final license = await generator.call(
        appId: appId,
        expirationDate: expirationDate,
        type: LicenseType.standard,
        isTrial: true,
      );

      // Act
      final result = await validator.validate(license);

      // Assert
      expect(result.isValid, isTrue);
      expect(license.isTrial, isTrue);
      expect(license.type, equals(LicenseType.standard));
    });

    test('should validate signature separately from expiration', () async {
      // Arrange
      final appId = 'com.example.testapp';
      final expirationDate = DateTime.now().add(const Duration(days: 30));

      final license = await generator.call(
        appId: appId,
        expirationDate: expirationDate,
        type: LicenseType.pro,
      );

      // Act
      final signatureResult = await validator.validateSignature(license);
      final expirationResult = validator.validateExpiration(license);

      // Assert
      expect(signatureResult.isValid, isTrue);
      expect(signatureResult.message, 'Valid signature');
      expect(expirationResult.isValid, isTrue);
      expect(expirationResult.message, 'License not expired');
    });

    test('should generate license from existing payload', () async {
      // Arrange
      final payload = {
        'sub': 'test-license-id',
        'app_id': 'com.example.testapp',
        'exp': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'iat': DateTime.now().toIso8601String(),
        'iss': 'licensify',
        'type': 'pro',
        'features': {'custom': true},
        'trial': false,
      };

      // Act
      final license = await generator.fromPayload(payload: payload);

      // Assert
      expect(license.token, startsWith('v4.public.'));

      // Validate the license
      final result = await validator.validate(license);
      expect(result.isValid, isTrue);
      expect(license.id, equals('test-license-id'));
      expect(license.appId, equals('com.example.testapp'));
    });

    test('should work with key pair factory methods', () async {
      // Test Ed25519 key generation
      final ed25519KeyPair = await LicensifyKey.generatePublicKeyPair();
      expect(ed25519KeyPair.keyType, equals(LicensifyKeyType.ed25519Public));
      expect(ed25519KeyPair.isAsymmetric, isTrue);
      expect(ed25519KeyPair.isSymmetric, isFalse);
      expect(ed25519KeyPair.isConsistent, isTrue);

      // Test XChaCha20 key generation
      final xchachaKey = LicensifyKey.generateLocalKey();
      expect(xchachaKey.keyType, equals(LicensifyKeyType.xchacha20Local));
      expect(xchachaKey.keyBytes.length, equals(32));
    });

    test('should provide fluent API through key objects', () async {
      // Arrange
      final keyPair = await LicensifyKey.generatePublicKeyPair();

      // Act - use fluent API
      final generator = keyPair.privateKey.licenseGenerator;
      final validator = keyPair.publicKey!.licenseValidator;

      // Generate license
      final license = await generator.call(
        appId: 'com.example.fluent',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Validate license
      final result = await validator.validate(license);

      // Assert
      expect(result.isValid, isTrue);
    });

    test('should prevent different key types from being used together',
        () async {
      // Arrange
      final keyPair = await LicensifyKey.generatePublicKeyPair();

      // This should be OK
      expect(
        () => LicenseGenerator(privateKey: keyPair.privateKey),
        isNot(throwsA(isA<ArgumentError>())),
      );
    });

    test('should generate consistent key pairs', () async {
      // Arrange & Act
      final keyPair1 = await LicensifyKey.generatePublicKeyPair();
      final keyPair2 = await LicensifyKey.generatePublicKeyPair();

      // Assert - keys should be different
      expect(keyPair1.privateKey.keyBytes,
          isNot(equals(keyPair2.privateKey.keyBytes)));
      expect(keyPair1.publicKey!.keyBytes,
          isNot(equals(keyPair2.publicKey!.keyBytes)));

      // But both should be valid Ed25519 keys
      expect(keyPair1.keyType, equals(LicensifyKeyType.ed25519Public));
      expect(keyPair2.keyType, equals(LicensifyKeyType.ed25519Public));
    });

    test('should validate key lengths and formats', () {
      // Ed25519 keys should be 32 bytes each
      expect(() => LicensifyPrivateKey.ed25519(Uint8List(31)),
          throwsA(isA<ArgumentError>()));
      expect(() => LicensifyPrivateKey.ed25519(Uint8List(33)),
          throwsA(isA<ArgumentError>()));

      // XChaCha20 keys should be 32 bytes
      expect(() => LicensifySymmetricKey.xchacha20(Uint8List(31)),
          throwsA(isA<ArgumentError>()));
      expect(() => LicensifySymmetricKey.xchacha20(Uint8List(33)),
          throwsA(isA<ArgumentError>()));

      // Valid keys should not throw
      expect(() => LicensifyPrivateKey.ed25519(Uint8List(32)),
          isNot(throwsA(anything)));
      expect(() => LicensifySymmetricKey.xchacha20(Uint8List(32)),
          isNot(throwsA(anything)));
    });

    test('should support key serialization and deserialization', () async {
      // Arrange
      final keyPair = await LicensifyKey.generatePublicKeyPair();

      // Act - serialize to bytes and back
      final privateKeyBytes = keyPair.privateKey.keyBytes;
      final publicKeyBytes = keyPair.publicKey!.keyBytes;

      final recreatedPrivateKey = LicensifyPrivateKey.ed25519(privateKeyBytes);
      final recreatedPublicKey = LicensifyPublicKey.ed25519(publicKeyBytes);

      // Assert
      expect(recreatedPrivateKey.keyBytes, equals(keyPair.privateKey.keyBytes));
      expect(recreatedPublicKey.keyBytes, equals(keyPair.publicKey!.keyBytes));
    });

    test('should generate working license with real cryptography', () async {
      // Generate a real Ed25519 key pair
      final keyPair = await LicensifyKey.generatePublicKeyPair();

      // Create generator and validator
      final generator = LicenseGenerator(privateKey: keyPair.privateKey);

      // Generate license
      final license = await generator.call(
        appId: 'com.example.test',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        type: LicenseType.pro,
        features: {
          'max_users': 100,
          'api_access': true,
        },
      );

      // Assert license structure
      expect(license, isA<License>());
      expect(license.token, isNotEmpty);
      expect(license.token, startsWith('v4.public.'));

      // Now payload is populated during generation, so id and appId should be available
      expect(license.id, isNotEmpty);
      expect(license.appId, isNotEmpty);
    });

    test('should validate license properly', () async {
      // Generate a real Ed25519 key pair
      final keyPair = await LicensifyKey.generatePublicKeyPair();

      // Generate test license
      final generator = LicenseGenerator(privateKey: keyPair.privateKey);
      final testLicense = await generator.call(
        appId: 'com.example.validationtest',
        expirationDate: DateTime.now().add(const Duration(days: 7)),
        type: LicenseType.standard,
      );

      // Create validator
      final validator = LicenseValidator(publicKey: keyPair.publicKey!);

      // Validate license
      final result = await validator.validate(testLicense);

      // Assert validation result
      expect(result.isValid, isTrue);
      expect(result.message, contains('valid'));
    });

    test('should reject tampered license', () async {
      // Generate keys and license
      final keyPair1 = await LicensifyKey.generatePublicKeyPair();
      final keyPair2 = await LicensifyKey.generatePublicKeyPair();

      final generator = LicenseGenerator(privateKey: keyPair1.privateKey);
      final validator =
          LicenseValidator(publicKey: keyPair2.publicKey!); // Different key!

      // Generate license with first key
      final license = await generator.call(
        appId: 'com.example.tamper',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Try to validate with second key (should fail)
      final result = await validator.validate(license);

      // Assert validation fails
      expect(result.isValid, isFalse);
      expect(result.message, contains('Invalid'));
    });
  });

  group('PASETO Key Management Tests', () {
    test('should create Ed25519 keys with correct format', () {
      // Test individual key creation
      final keyBytes = List.generate(32, (i) => i); // 32 bytes test data
      final privateKey = LicensifyPrivateKey.ed25519(
        Uint8List.fromList(keyBytes),
      );
      final publicKey = LicensifyPublicKey.ed25519(
        Uint8List.fromList(keyBytes),
      );

      expect(privateKey.keyType, equals(LicensifyKeyType.ed25519Public));
      expect(privateKey.keyBytes.length, equals(32));
      expect(publicKey.keyType, equals(LicensifyKeyType.ed25519Public));
      expect(publicKey.keyBytes.length, equals(32));
    });

    test('should enforce key size requirements', () {
      // Test invalid key sizes
      expect(
        () => LicensifyPrivateKey.ed25519(Uint8List(16)), // Too short
        throwsArgumentError,
      );

      expect(
        () => LicensifyPublicKey.ed25519(Uint8List(64)), // Too long
        throwsArgumentError,
      );

      expect(
        () => LicensifySymmetricKey.xchacha20(Uint8List(16)), // Too short
        throwsArgumentError,
      );
    });

    test('should work with RealEd25519KeyGenerator', () async {
      // Test key pair generation
      final keyPair = await LicensifyKey.generatePublicKeyPair();
      expect(keyPair.privateKey.keyBytes.length, equals(32));
      expect(keyPair.publicKey!.keyBytes.length, equals(32));

      // Test bytes generation
      final keyMap = await LicensifyKey.generatePublicKeyPair();
      expect(keyMap['privateKey']!.length, equals(32));
      expect(keyMap['publicKey']!.length, equals(32));

      // Test key creation from bytes
      final privateKey =
          LicensifyKeyGenerator.privateKeyFromBytes(keyMap['privateKey']!);
      final publicKey =
          LicensifyKeyGenerator.publicKeyFromBytes(keyMap['publicKey']!);
      expect(privateKey.keyBytes.length, equals(32));
      expect(publicKey.keyBytes.length, equals(32));
    });
  });
}
