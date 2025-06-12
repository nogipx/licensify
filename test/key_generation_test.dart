import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('LicensifyKey Factory Methods', () {
    test('should generate Ed25519 key pair', () async {
      // Act
      final keyPair = await LicensifyKey.generatePublicKeyPair();

      // Assert
      expect(keyPair, isA<LicensifyKeyPair>());
      expect(keyPair.keyType, equals(LicensifyKeyType.ed25519Public));
      expect(keyPair.privateKey.keyBytes.length, equals(32));
      expect(keyPair.publicKey.keyBytes.length, equals(32));
      expect(keyPair.isConsistent, isTrue);
    });

    test('should generate symmetric key', () {
      // Act
      final symmetricKey = LicensifyKey.generateLocalKey();

      // Assert
      expect(symmetricKey, isA<LicensifySymmetricKey>());
      expect(symmetricKey.keyType, equals(LicensifyKeyType.xchacha20Local));
      expect(symmetricKey.keyBytes.length, equals(32));
    });

    test('should generate different keys each time', () async {
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
    });

    test('should provide crypto functionality', () async {
      // Arrange
      final keyPair = await LicensifyKey.generatePublicKeyPair();
      final symmetricKey = LicensifyKey.generateLocalKey();

      // Act - check fluent API access
      final generator = keyPair.privateKey.licenseGenerator;
      final validator = keyPair.publicKey.licenseValidator;
      final crypto = symmetricKey.crypto;

      // Assert
      expect(generator, isA<LicenseGenerator>());
      expect(validator, isA<LicenseValidator>());
      expect(crypto, isA<LicensifySymmetricCrypto>());
    });

    test('should work with symmetric crypto operations', () async {
      // Arrange
      final symmetricKey = LicensifyKey.generateLocalKey();
      final crypto = symmetricKey.crypto;

      final testData = {
        'message': 'Hello, World!',
        'timestamp': DateTime.now().toIso8601String()
      };

      // Act
      final encryptedToken = await crypto.encrypt(testData);
      final decryptedData = await crypto.decrypt(encryptedToken);

      // Assert
      expect(encryptedToken, isA<String>());
      expect(encryptedToken, startsWith('v4.local.'));
      expect(decryptedData['message'], equals('Hello, World!'));
      expect(decryptedData['timestamp'], equals(testData['timestamp']));
    });

    test('should work with raw bytes encryption', () async {
      // Arrange
      final symmetricKey = LicensifyKey.generateLocalKey();
      final crypto = symmetricKey.crypto;

      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

      // Act
      final encryptedToken = await crypto.encryptBytes(testBytes);
      final decryptedBytes = await crypto.decryptBytes(encryptedToken);

      // Assert
      expect(encryptedToken, isA<String>());
      expect(encryptedToken, startsWith('v4.local.'));
      expect(decryptedBytes, equals(testBytes));
    });

    test('should generate working license', () async {
      // Arrange
      final keyPair = await LicensifyKey.generatePublicKeyPair();
      final generator = keyPair.privateKey.licenseGenerator;
      final validator = keyPair.publicKey!.licenseValidator;

      // Act
      final license = await generator.call(
        appId: 'com.example.test',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        type: LicenseType.pro,
        features: {'premium': true},
      );

      final validationResult = await validator.validate(license);

      // Assert
      expect(license.token, startsWith('v4.public.'));
      expect(validationResult.isValid, isTrue);
      expect(license.appId, equals('com.example.test'));
      expect(license.type, equals(LicenseType.pro));
      expect(license.features['premium'], isTrue);
    });
  });
}
