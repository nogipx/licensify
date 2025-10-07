import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('🔑 License Creation with Explicit Keys', () {
    test('license_creation_with_explicit_keys_produces_valid_trial_license',
        () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      try {
        // Act
        final sut = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.trial',
          expirationDate: DateTime.now().add(Duration(days: 7)),
          type: LicenseType('trial'),
          features: {'limited_access': true},
          isTrial: true,
        );

        // Assert
        expect(await sut.appId, 'com.test.trial');
        expect((await sut.type).name, 'trial');
        expect(await sut.isTrial, isTrue);
        expect((await sut.features)['limited_access'], isTrue);
        expect(sut.token, startsWith('v4.public.'));
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('license_creation_with_explicit_keys_produces_valid_standard_license',
        () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      try {
        // Act
        final sut = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.standard',
          expirationDate: DateTime.now().add(Duration(days: 30)),
          type: LicenseType.standard,
          features: {'basic_access': true, 'support': false},
          metadata: {'customer': 'Test Corp'},
        );

        // Assert
        expect(await sut.appId, 'com.test.standard');
        expect((await sut.type).name, 'standard');
        expect(await sut.isTrial, isFalse);
        expect((await sut.features)['basic_access'], isTrue);
        expect((await sut.features)['support'], isFalse);
        expect((await sut.metadata)!['customer'], 'Test Corp');
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });
  });

  group('✅ License Validation with Explicit Keys', () {
    test('license_validation_succeeds_for_valid_license', () async {
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
        final sut = await Licensify.validateLicense(
          license: license,
          publicKey: keys.publicKey,
        );

        // Assert
        expect(sut.isValid, isTrue);
        expect(sut.message, contains('valid'));
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('license_validation_fails_for_expired_license', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();
      final expiredLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.expired',
        expirationDate: DateTime.now().subtract(Duration(days: 1)),
        type: LicenseType.standard,
      );

      try {
        // Act
        final sut = await Licensify.validateLicense(
          license: expiredLicense,
          publicKey: keys.publicKey,
        );

        // Assert
        expect(sut.isValid, isFalse);
        expect(sut.message, contains('expired'));
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('license_validation_with_key_bytes_succeeds_for_valid_license',
        () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();
      try {
        final license = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.bytes',
          expirationDate: DateTime.now().add(Duration(days: 15)),
          type: LicenseType.pro,
        );

        final publicKeyBytes = keys.publicKey.keyBytes;

        // Act
        final sut = await Licensify.validateLicenseWithKeyBytes(
          license: license,
          publicKeyBytes: publicKeyBytes,
        );

        // Assert
        expect(sut.isValid, isTrue);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('signature_validation_succeeds_even_for_expired_license', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();
      final expiredLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.signature',
        expirationDate: DateTime.now().subtract(Duration(days: 1)),
        type: LicenseType.standard,
      );

      try {
        // Act
        final sut = await Licensify.validateSignature(
          license: expiredLicense,
          publicKey: keys.publicKey,
        );

        // Assert
        expect(sut.isValid, isTrue);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('license_validation_fails_when_using_wrong_public_key', () async {
      // Arrange
      final validKeys = await Licensify.generateSigningKeys();
      final license = await Licensify.createLicense(
        privateKey: validKeys.privateKey,
        appId: 'com.test.invalid',
        expirationDate: DateTime.now().add(Duration(days: 1)),
        type: LicenseType.standard,
      );
      validKeys.privateKey.dispose();
      validKeys.publicKey.dispose();

      final wrongKeys = await Licensify.generateSigningKeys();

      try {
        // Act
        final sut = await Licensify.validateLicense(
          license: license,
          publicKey: wrongKeys.publicKey,
        );

        // Assert
        expect(sut.isValid, isFalse);
        expect(sut.message, contains('verification error'));
      } finally {
        wrongKeys.privateKey.dispose();
        wrongKeys.publicKey.dispose();
      }
    });
  });

  group('🔒 Data Encryption with Explicit Keys', () {
    test('data_encryption_and_decryption_succeeds_with_explicit_key', () async {
      // Arrange
      final encryptionKey = Licensify.generateEncryptionKey();
      final testData = {
        'user_id': 'test123',
        'permissions': ['read', 'write'],
        'config': {'debug': true, 'timeout': 5000},
      };

      try {
        // Act
        final encryptedToken = await Licensify.encryptData(
          data: testData,
          encryptionKey: encryptionKey,
          footer: 'test_footer',
        );

        final sut = await Licensify.decryptData(
          encryptedToken: encryptedToken,
          encryptionKey: encryptionKey,
        );

        // Assert
        expect(encryptedToken, startsWith('v4.local.'));
        expect(sut['user_id'], testData['user_id']);
        expect(sut['permissions'], testData['permissions']);
        expect(sut['config'], testData['config']);
      } finally {
        encryptionKey.dispose();
      }
    });

    test('data_encryption_handles_complex_data_structures', () async {
      // Arrange
      final encryptionKey = Licensify.generateEncryptionKey();
      final complexData = {
        'nested': {
          'deep': {'value': 42},
          'array': [1, 2, 3, 'string'],
        },
        'boolean': true,
        'null_value': null,
        'number': 3.14159,
      };

      try {
        // Act
        final encryptedToken = await Licensify.encryptData(
          data: complexData,
          encryptionKey: encryptionKey,
        );

        final sut = await Licensify.decryptData(
          encryptedToken: encryptedToken,
          encryptionKey: encryptionKey,
        );

        // Assert
        expect(sut['nested']['deep']['value'], 42);
        expect(sut['nested']['array'], [1, 2, 3, 'string']);
        expect(sut['boolean'], isTrue);
        expect(sut['null_value'], isNull);
        expect(sut['number'], 3.14159);
      } finally {
        encryptionKey.dispose();
      }
    });

    test('data_encryption_with_footer_creates_valid_token', () async {
      // Arrange
      final encryptionKey = Licensify.generateEncryptionKey();
      final testData = {'secret': 'top-secret-data'};
      final footer = 'version=1.0';

      try {
        // Act
        final sut = await Licensify.encryptData(
          data: testData,
          encryptionKey: encryptionKey,
          footer: footer,
        );

        // Assert
        expect(sut, startsWith('v4.local.'));
        // Footer is base64 encoded in PASETO tokens, so we check token structure
        final parts = sut.split('.');
        expect(parts.length, 4); // header.payload.ciphertext.footer
        expect(parts[3].isNotEmpty, isTrue); // Footer part exists
      } finally {
        encryptionKey.dispose();
      }
    });
  });

  group('🛠️ Key Management', () {
    test('key_generation_produces_valid_signing_keys', () async {
      // Act
      final sut = await Licensify.generateSigningKeys();

      try {
        // Assert
        expect(sut.privateKey.keyLength, 32);
        expect(sut.publicKey.keyLength, 32);
        expect(sut.privateKey.keyType, LicensifyKeyType.ed25519Public);
        expect(sut.publicKey.keyType, LicensifyKeyType.ed25519Public);
      } finally {
        sut.privateKey.dispose();
        sut.publicKey.dispose();
      }
    });

    test('key_generation_produces_valid_encryption_key', () {
      // Act
      final sut = Licensify.generateEncryptionKey();

      try {
        // Assert
        expect(sut.keyLength, 32);
        expect(sut.keyType, LicensifyKeyType.xchacha20Local);
      } finally {
        sut.dispose();
      }
    });

    test('keys_from_bytes_recreates_original_keys', () async {
      // Arrange
      final originalKeys = await Licensify.generateSigningKeys();
      final keyStorage = originalKeys.asBytes;
      originalKeys.privateKey.dispose();
      originalKeys.publicKey.dispose();

      // Act
      final sut = Licensify.keysFromBytes(
        privateKeyBytes: keyStorage.privateKeyBytes,
        publicKeyBytes: keyStorage.publicKeyBytes,
      );

      try {
        // Assert
        expect(sut.privateKey.keyLength, 32);
        expect(sut.publicKey.keyLength, 32);
        expect(sut.privateKey.keyType, LicensifyKeyType.ed25519Public);
        expect(sut.publicKey.keyType, LicensifyKeyType.ed25519Public);
      } finally {
        sut.privateKey.dispose();
        sut.publicKey.dispose();
      }
    });

    test('encryption_key_from_bytes_recreates_original_key', () {
      // Arrange
      final originalKey = Licensify.generateEncryptionKey();
      final keyBytes = originalKey.keyBytes;
      originalKey.dispose();

      // Act
      final sut = Licensify.encryptionKeyFromBytes(keyBytes: keyBytes);

      try {
        // Assert
        expect(sut.keyLength, 32);
        expect(sut.keyType, LicensifyKeyType.xchacha20Local);
      } finally {
        sut.dispose();
      }
    });
  });
}
