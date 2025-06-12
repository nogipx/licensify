// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('PASETO License Integration Tests', () {
    late LicensifyPasetoKeyPair keyPair;
    late PasetoLicenseGenerator generator;
    late PasetoLicenseValidator validator;

    setUpAll(() async {
      // Generate Ed25519 key pair for testing
      keyPair = await LicensifyPasetoKeyPair.generateEd25519();

      // Create generator and validator
      generator = PasetoLicenseGenerator(privateKey: keyPair.privateKey);
      validator = PasetoLicenseValidator(publicKey: keyPair.publicKey!);
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
      expect(license, isA<PasetoLicense>());
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
      final invalidLicense = PasetoLicense.fromToken('invalid.token.here');

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
      final ed25519KeyPair = await LicensifyPasetoKeyPair.generateEd25519();
      expect(ed25519KeyPair.keyType, equals(PasetoKeyType.ed25519Public));
      expect(ed25519KeyPair.isAsymmetric, isTrue);
      expect(ed25519KeyPair.isSymmetric, isFalse);
      expect(ed25519KeyPair.isConsistent, isTrue);

      // Test XChaCha20 key generation
      final xchachaKeyPair = LicensifyPasetoKeyPair.generateXChaCha20();
      expect(xchachaKeyPair.keyType, equals(PasetoKeyType.xchacha20Local));
      expect(xchachaKeyPair.isAsymmetric, isFalse);
      expect(xchachaKeyPair.isSymmetric, isTrue);
      expect(xchachaKeyPair.isConsistent, isTrue);
    });

    test('should provide fluent API through key objects', () async {
      // Arrange
      final keyPair = await LicensifyPasetoKeyPair.generateEd25519();

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
      expect(license.token, startsWith('v4.public.'));
    });
  });

  group('PASETO Key Management Tests', () {
    test('should create Ed25519 keys with correct format', () {
      // Test individual key creation
      final keyBytes = List.generate(32, (i) => i); // 32 bytes test data
      final privateKey = LicensifyPasetoPrivateKey.ed25519(
        Uint8List.fromList(keyBytes),
      );
      final publicKey = LicensifyPasetoPublicKey.ed25519(
        Uint8List.fromList(keyBytes),
      );

      expect(privateKey.keyType, equals(PasetoKeyType.ed25519Public));
      expect(privateKey.keyBytes.length, equals(32));
      expect(publicKey.keyType, equals(PasetoKeyType.ed25519Public));
      expect(publicKey.keyBytes.length, equals(32));
    });

    test('should enforce key size requirements', () {
      // Test invalid key sizes
      expect(
        () => LicensifyPasetoPrivateKey.ed25519(Uint8List(16)), // Too short
        throwsArgumentError,
      );

      expect(
        () => LicensifyPasetoPublicKey.ed25519(Uint8List(64)), // Too long
        throwsArgumentError,
      );

      expect(
        () => LicensifyPasetoPrivateKey.xchacha20(Uint8List(16)), // Too short
        throwsArgumentError,
      );
    });

    test('should work with Ed25519KeyGenerator', () async {
      // Test key pair generation
      final keyPair = await Ed25519KeyGenerator.generateKeyPair();
      expect(keyPair.privateKey.keyBytes.length, equals(32));
      expect(keyPair.publicKey!.keyBytes.length, equals(32));

      // Test bytes generation
      final keyMap = await Ed25519KeyGenerator.generateKeyPairAsBytes();
      expect(keyMap['privateKey']!.length, equals(32));
      expect(keyMap['publicKey']!.length, equals(32));

      // Test key creation from bytes
      final privateKey =
          Ed25519KeyGenerator.privateKeyFromBytes(keyMap['privateKey']!);
      final publicKey =
          Ed25519KeyGenerator.publicKeyFromBytes(keyMap['publicKey']!);
      expect(privateKey.keyBytes.length, equals(32));
      expect(publicKey.keyBytes.length, equals(32));
    });
  });
}
