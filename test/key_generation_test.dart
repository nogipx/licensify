import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('LicensifyKey Factory Methods', () {
    test('should_generate_ed25519_key_pair_with_correct_properties', () async {
      // Act
      final sut = await LicensifyKey.generatePublicKeyPair();

      // Assert
      expect(sut, isA<LicensifyKeyPair>());
      expect(sut.keyType, equals(LicensifyKeyType.ed25519Public));
      expect(sut.privateKey.keyBytes.length, equals(32));
      expect(sut.publicKey.keyBytes.length, equals(32));
      expect(sut.isConsistent, isTrue);

      // Cleanup
      sut.privateKey.dispose();
      sut.publicKey.dispose();
    });

    test('should_generate_symmetric_key_with_correct_properties', () {
      // Act
      final sut = LicensifyKey.generateLocalKey();

      // Assert
      expect(sut, isA<LicensifySymmetricKey>());
      expect(sut.keyType, equals(LicensifyKeyType.xchacha20Local));
      expect(sut.keyBytes.length, equals(32));

      // Cleanup
      sut.dispose();
    });

    test('should_generate_different_keys_each_time', () async {
      // Act
      final keyPair1 = await LicensifyKey.generatePublicKeyPair();
      final keyPair2 = await LicensifyKey.generatePublicKeyPair();
      final symmetricKey1 = LicensifyKey.generateLocalKey();
      final symmetricKey2 = LicensifyKey.generateLocalKey();

      // Assert - keys should be different
      expect(keyPair1.privateKey.keyBytes,
          isNot(equals(keyPair2.privateKey.keyBytes)));
      expect(keyPair1.publicKey.keyBytes,
          isNot(equals(keyPair2.publicKey.keyBytes)));
      expect(symmetricKey1.keyBytes, isNot(equals(symmetricKey2.keyBytes)));

      // Cleanup
      keyPair1.privateKey.dispose();
      keyPair1.publicKey.dispose();
      keyPair2.privateKey.dispose();
      keyPair2.publicKey.dispose();
      symmetricKey1.dispose();
      symmetricKey2.dispose();
    });

    test('should_create_and_validate_license_using_unified_api', () async {
      // Arrange
      final keyPair = await LicensifyKey.generatePublicKeyPair();
      final publicKeyBytes = List<int>.from(keyPair.publicKey.keyBytes);

      try {
        // Act
        final license = await Licensify.createLicense(
          privateKey: keyPair.privateKey,
          appId: 'com.example.test',
          expirationDate: DateTime.now().add(const Duration(days: 30)),
          type: LicenseType.pro,
          features: {'premium': true},
        );

        final validationResult = await Licensify.validateLicenseWithKeyBytes(
          license: license,
          publicKeyBytes: publicKeyBytes,
        );

        // Assert
        expect(license.token, startsWith('v4.public.'));
        expect(validationResult.isValid, isTrue);
        expect(await license.appId, equals('com.example.test'));
        expect(await license.type, equals(LicenseType.pro));
        expect((await license.features)['premium'], isTrue);

        // Verify license content
        expect((await license.toMap())['app_id'], equals('com.example.test'));
      } finally {
        // Cleanup
        keyPair.privateKey.dispose();
        keyPair.publicKey.dispose();
      }
    });

    test('should_encrypt_and_decrypt_data_using_unified_api', () async {
      // Arrange
      final symmetricKey = LicensifyKey.generateLocalKey();
      final keyBytes = List<int>.from(symmetricKey.keyBytes);
      symmetricKey.dispose(); // Dispose original key

      final testData = {
        'message': 'Hello, World!',
        'timestamp': DateTime.now().toIso8601String()
      };

      // Act
      final encryptKey =
          LicensifySymmetricKey.xchacha20(Uint8List.fromList(keyBytes));
      final encryptedToken = await Licensify.encryptData(
        data: testData,
        encryptionKey: encryptKey,
      );

      final decryptKey =
          LicensifySymmetricKey.xchacha20(Uint8List.fromList(keyBytes));
      final decryptedData = await Licensify.decryptData(
        encryptedToken: encryptedToken,
        encryptionKey: decryptKey,
      );

      // Assert
      expect(encryptedToken, isA<String>());
      expect(encryptedToken, startsWith('v4.local.'));
      expect(decryptedData['message'], equals('Hello, World!'));
      expect(decryptedData['timestamp'], equals(testData['timestamp']));

      // Cleanup
      encryptKey.dispose();
      decryptKey.dispose();
    });

    test('should_work_with_auto_generated_keys', () async {
      // Act
      final result = await Licensify.createLicenseWithKeys(
        appId: 'com.example.auto',
        expirationDate: DateTime.now().add(const Duration(days: 90)),
        type: LicenseType.standard,
        features: {'auto_generated': true},
      );

      final validationResult = await Licensify.validateLicenseWithKeyBytes(
        license: result.license,
        publicKeyBytes: result.publicKeyBytes,
      );

      // Assert
      expect(result.license.token, startsWith('v4.public.'));
      expect(result.publicKeyBytes.length, equals(32));
      expect(validationResult.isValid, isTrue);
      expect(await result.license.appId, equals('com.example.auto'));
      expect((await result.license.features)['auto_generated'], isTrue);
    });

    test('should_work_with_auto_generated_encryption_key', () async {
      // Arrange
      final testData = {
        'secret': 'confidential information',
        'level': 'top-secret'
      };

      // Act
      final encryptResult = await Licensify.encryptDataWithKey(data: testData);

      final decryptKey =
          LicensifySymmetricKey.xchacha20(encryptResult.keyBytes);
      final decryptedData = await Licensify.decryptData(
        encryptedToken: encryptResult.encryptedToken,
        encryptionKey: decryptKey,
      );

      // Assert
      expect(encryptResult.encryptedToken, startsWith('v4.local.'));
      expect(encryptResult.keyBytes.length, equals(32));
      expect(decryptedData['secret'], equals('confidential information'));
      expect(decryptedData['level'], equals('top-secret'));

      // Cleanup
      decryptKey.dispose();
    });
  });
}
