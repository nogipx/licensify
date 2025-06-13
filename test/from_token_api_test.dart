import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('🎯 License Creation from Token API', () {
    test('fromToken_creates_valid_license_from_token_string', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      // Create a license first
      final originalLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.fromtoken',
        expirationDate: DateTime.now().add(Duration(days: 30)),
        type: LicenseType.pro,
        features: {'api_access': true, 'max_users': 50},
        metadata: {'customer': 'Test Customer', 'order_id': 'ORD-123'},
        isTrial: false,
      );

      try {
        // Act - Create license from token string
        final sut = await Licensify.fromToken(
          token: originalLicense.token,
          publicKey: keys.publicKey,
        );

        // Assert
        expect(await sut.id, await originalLicense.id);
        expect(await sut.appId, 'com.test.fromtoken');
        expect((await sut.type).name, 'pro');
        expect(await sut.isTrial, false);
        expect((await sut.features)['api_access'], true);
        expect((await sut.features)['max_users'], 50);
        expect((await sut.metadata)!['customer'], 'Test Customer');
        expect((await sut.metadata)!['order_id'], 'ORD-123');

        // Verify the token strings are identical
        expect(sut.token, originalLicense.token);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('fromTokenWithKeyBytes_creates_valid_license_from_token_string',
        () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      final originalLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.fromtokenbytes',
        expirationDate: DateTime.now().add(Duration(days: 15)),
        type: LicenseType('enterprise'),
        features: {'unlimited_users': true, 'priority_support': true},
      );

      final publicKeyBytes = keys.publicKey.keyBytes;

      try {
        // Act - Create license from token using key bytes
        final sut = await Licensify.fromTokenWithKeyBytes(
          token: originalLicense.token,
          publicKeyBytes: publicKeyBytes,
        );

        // Assert
        expect(await sut.id, await originalLicense.id);
        expect(await sut.appId, 'com.test.fromtokenbytes');
        expect((await sut.type).name, 'enterprise');
        expect((await sut.features)['unlimited_users'], true);
        expect((await sut.features)['priority_support'], true);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('fromToken_preserves_expiration_dates_correctly', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();
      final expirationDate = DateTime.now().add(Duration(days: 90));

      final originalLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.expiration',
        expirationDate: expirationDate,
        type: LicenseType.standard,
      );

      try {
        // Act
        final sut = await Licensify.fromToken(
          token: originalLicense.token,
          publicKey: keys.publicKey,
        );

        // Assert - Dates should match within reasonable precision (1 second)
        final originalExp = await originalLicense.expirationDate;
        final restoredExp = await sut.expirationDate;
        final difference = originalExp.difference(restoredExp).abs();

        expect(difference.inSeconds, lessThan(1));
        expect(await sut.isExpired, false);
        expect(await sut.remainingDays, greaterThan(85));
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('fromToken_handles_trial_licenses_correctly', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      final trialLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.trial',
        expirationDate: DateTime.now().add(Duration(days: 7)),
        type: LicenseType('trial'),
        isTrial: true,
        features: {'limited_features': true},
      );

      try {
        // Act
        final sut = await Licensify.fromToken(
          token: trialLicense.token,
          publicKey: keys.publicKey,
        );

        // Assert
        expect(await sut.isTrial, true);
        expect((await sut.type).name, 'trial');
        expect((await sut.features)['limited_features'], true);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });
  });

  group('❌ License Creation from Token Error Handling', () {
    test('fromToken_throws_for_invalid_token_format', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();
      const invalidToken = 'invalid.token.format';

      try {
        // Act & Assert
        expect(
          () => Licensify.fromToken(
            token: invalidToken,
            publicKey: keys.publicKey,
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('fromToken_throws_for_expired_token', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      final expiredLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.expired',
        expirationDate: DateTime.now().subtract(Duration(days: 1)),
        type: LicenseType.standard,
      );

      try {
        // Act & Assert
        expect(
          () => Licensify.fromToken(
            token: expiredLicense.token,
            publicKey: keys.publicKey,
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('fromToken_throws_for_wrong_public_key', () async {
      // Arrange
      final validKeys = await Licensify.generateSigningKeys();
      final wrongKeys = await Licensify.generateSigningKeys();

      final license = await Licensify.createLicense(
        privateKey: validKeys.privateKey,
        appId: 'com.test.wrongkey',
        expirationDate: DateTime.now().add(Duration(days: 1)),
        type: LicenseType.standard,
      );

      try {
        // Act & Assert
        expect(
          () => Licensify.fromToken(
            token: license.token,
            publicKey: wrongKeys.publicKey, // Wrong key!
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        validKeys.privateKey.dispose();
        validKeys.publicKey.dispose();
        wrongKeys.privateKey.dispose();
        wrongKeys.publicKey.dispose();
      }
    });

    test('fromTokenWithKeyBytes_throws_for_invalid_key_bytes', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      final license = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.invalidbytes',
        expirationDate: DateTime.now().add(Duration(days: 1)),
        type: LicenseType.standard,
      );

      final invalidKeyBytes = List.generate(32, (index) => 0xFF); // Invalid key

      try {
        // Act & Assert
        expect(
          () => Licensify.fromTokenWithKeyBytes(
            token: license.token,
            publicKeyBytes: invalidKeyBytes,
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('fromToken_throws_for_corrupted_token', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      final validLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.corrupted',
        expirationDate: DateTime.now().add(Duration(days: 1)),
        type: LicenseType.standard,
      );

      // Corrupt the token by changing a character
      final corruptedToken =
          validLicense.token.replaceFirst('v4.public.', 'v4.public.X');

      try {
        // Act & Assert
        expect(
          () => Licensify.fromToken(
            token: corruptedToken,
            publicKey: keys.publicKey,
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });
  });

  group('🔄 License Roundtrip Consistency', () {
    test('create_license_and_restore_from_token_produces_identical_data',
        () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();
      final expirationDate = DateTime.now().add(Duration(days: 365));

      final features = {
        'max_users': 1000,
        'api_access': true,
        'custom_branding': true,
        'advanced_analytics': false,
      };

      final metadata = {
        'customer': 'Enterprise Customer',
        'contract_id': 'ENT-2025-001',
        'sales_rep': 'john.doe@company.com',
        'tier': 'platinum',
      };

      try {
        // Act - Create original license
        final originalLicense = await Licensify.createLicense(
          privateKey: keys.privateKey,
          appId: 'com.enterprise.app',
          expirationDate: expirationDate,
          type: LicenseType('enterprise'),
          features: features,
          metadata: metadata,
          isTrial: false,
        );

        // Act - Restore from token
        final restoredLicense = await Licensify.fromToken(
          token: originalLicense.token,
          publicKey: keys.publicKey,
        );

        // Assert - All data should be identical
        expect(await restoredLicense.id, await originalLicense.id);
        expect(await restoredLicense.appId, await originalLicense.appId);
        expect(await restoredLicense.isTrial, await originalLicense.isTrial);
        expect((await restoredLicense.type).name,
            (await originalLicense.type).name);

        // Check features
        final originalFeatures = await originalLicense.features;
        final restoredFeatures = await restoredLicense.features;
        expect(restoredFeatures, equals(originalFeatures));

        // Check metadata
        final originalMetadata = await originalLicense.metadata;
        final restoredMetadata = await restoredLicense.metadata;
        expect(restoredMetadata, equals(originalMetadata));

        // Check dates (within 1 second precision)
        final originalExp = await originalLicense.expirationDate;
        final restoredExp = await restoredLicense.expirationDate;
        expect(
            originalExp.difference(restoredExp).abs().inSeconds, lessThan(1));

        final originalCreated = await originalLicense.createdAt;
        final restoredCreated = await restoredLicense.createdAt;
        expect(originalCreated.difference(restoredCreated).abs().inSeconds,
            lessThan(1));

        // Check tokens are identical
        expect(restoredLicense.token, originalLicense.token);
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });

    test('multiple_fromToken_calls_produce_identical_licenses', () async {
      // Arrange
      final keys = await Licensify.generateSigningKeys();

      final originalLicense = await Licensify.createLicense(
        privateKey: keys.privateKey,
        appId: 'com.test.multiple',
        expirationDate: DateTime.now().add(Duration(days: 30)),
        type: LicenseType.pro,
        features: {'feature1': true, 'feature2': 'value'},
      );

      try {
        // Act - Create multiple licenses from same token
        final license1 = await Licensify.fromToken(
          token: originalLicense.token,
          publicKey: keys.publicKey,
        );

        final license2 = await Licensify.fromToken(
          token: originalLicense.token,
          publicKey: keys.publicKey,
        );

        final license3 = await Licensify.fromTokenWithKeyBytes(
          token: originalLicense.token,
          publicKeyBytes: keys.publicKey.keyBytes,
        );

        // Assert - All should be identical
        expect(await license1.id, await license2.id);
        expect(await license1.id, await license3.id);
        expect(await license1.appId, await license2.appId);
        expect(await license1.appId, await license3.appId);
        expect(license1.token, license2.token);
        expect(license1.token, license3.token);

        final features1 = await license1.features;
        final features2 = await license2.features;
        final features3 = await license3.features;
        expect(features1, equals(features2));
        expect(features1, equals(features3));
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });
  });
}
