import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('Explicit Key Management API', () {
    test('should create and validate license with explicit keys', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      try {
        // Act - создаем лицензию
        final license = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.explicit',
          expirationDate: DateTime.now().add(Duration(days: 30)),
          type: LicenseType.standard,
          features: {'test_feature': true},
        );

        // Act - валидируем лицензию
        final result = await Licensify.validateLicense(
          license: license,
          publicKey: keys.publicKey,
        );

        // Assert
        expect(result.isValid, isTrue);
        expect(await license.appId, 'com.test.explicit');
        expect((await license.features)['test_feature'], isTrue);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('should encrypt and decrypt data with explicit keys', () async {
      // Arrange
      final encryptionKey = Licensify.generateEncryptionKey();
      final testData = {
        'user_id': 'test123',
        'permissions': ['read', 'write'],
      };

      try {
        // Act - шифруем
        final encryptedToken = await Licensify.encryptData(
          data: testData,
          encryptionKey: encryptionKey,
        );

        // Act - расшифровываем
        final decryptedData = await Licensify.decryptData(
          encryptedToken: encryptedToken,
          encryptionKey: encryptionKey,
        );

        // Assert
        expect(encryptedToken, startsWith('v4.local.'));
        expect(decryptedData['user_id'], testData['user_id']);
        expect(decryptedData['permissions'], testData['permissions']);
      } finally {
        encryptionKey.dispose();
      }
    });

    test('should validate signature only', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      try {
        // Создаем просроченную лицензию
        final expiredLicense = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.test.expired',
          expirationDate: DateTime.now().subtract(Duration(days: 1)),
          type: LicenseType.standard,
        );

        // Act - проверяем только подпись
        final signatureResult = await Licensify.validateSignature(
          license: expiredLicense,
          publicKey: keys.publicKey,
        );

        // Assert - подпись должна быть валидной, даже если лицензия просрочена
        expect(signatureResult.isValid, isTrue);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });
  });
}
