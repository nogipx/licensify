// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:licensify/licensify.dart';

/// Comprehensive example of Licensify PASETO package usage
///
/// This file demonstrates the core functionalities of the modern Licensify package
/// using PASETO v4 for secure license generation and validation.
void main() async {
  print('🔐 LICENSIFY - MODERN PASETO LICENSE MANAGEMENT');
  print('================================================\n');

  final examples = LicensifyPasetoExamples();
  await examples.runAllExamples();
}

/// Main class containing all PASETO examples
class LicensifyPasetoExamples {
  late final LicensifyKeyPair keyPair;
  late final List<int> privateKeyBytes;
  late final List<int> publicKeyBytes;
  late final License license;

  /// Run all examples in sequence
  Future<void> runAllExamples() async {
    // 1. Key generation examples
    await keyGenerationExamples();

    // 2. License creation examples
    await licenseCreationExamples();

    // 3. License validation examples
    await licenseValidationExamples();

    // 4. Advanced features examples
    await advancedFeaturesExamples();

    // 5. Performance testing
    await performanceExamples();

    print('\n🎉 All PASETO examples completed successfully!');
    print('\n💡 Key benefits of PASETO over traditional JWT:');
    print('   • No algorithm confusion attacks');
    print('   • Modern cryptography (Ed25519 + XChaCha20)');
    print('   • Built-in expiration handling');
    print('   • Self-contained tokens');
    print('   • Tamper-proof design');
    print('   • Better security than JWT/JOSE');
  }

  /// Examples of generating PASETO keys
  Future<void> keyGenerationExamples() async {
    print('🔑 KEY GENERATION EXAMPLES');
    print('==========================\n');

    print('1. Generating Ed25519 key pair for PASETO v4.public:');
    final startTime = DateTime.now();

    keyPair = await LicensifyKey.generatePublicKeyPair();

    // Сохраняем байты ключей для повторного использования
    privateKeyBytes = List<int>.from(keyPair.privateKey.keyBytes);
    publicKeyBytes = List<int>.from(keyPair.publicKey.keyBytes);

    final endTime = DateTime.now();

    print('✅ Generated Ed25519 key pair');
    print('   Private key: ${keyPair.privateKey.keyBytes.length} bytes');
    print('   Public key:  ${keyPair.publicKey.keyBytes.length} bytes');
    print(
        '   Generation time: ${endTime.difference(startTime).inMilliseconds}ms');
    print('   Key type: ${keyPair.keyType}');
    print('   Is consistent: ${keyPair.isConsistent}');

    print('\n2. Generating XChaCha20 key for PASETO v4.local:');
    final symmetricKey = LicensifyKey.generateLocalKey();
    print('✅ Generated XChaCha20 symmetric key');
    print('   Key size: ${symmetricKey.keyBytes.length} bytes');
    print('   Key type: ${symmetricKey.keyType}');

    // Очищаем временный ключ
    symmetricKey.dispose();
  }

  /// Examples of creating PASETO licenses
  Future<void> licenseCreationExamples() async {
    print('\n\n📝 LICENSE CREATION EXAMPLES');
    print('============================\n');

    print('1. Creating standard PASETO license:');
    license = await Licensify.createLicense(
      privateKey: keyPair.privateKey,
      appId: 'com.example.myapp',
      expirationDate: DateTime.now().add(const Duration(days: 365)),
      type: LicenseType.pro,
      features: {
        'max_users': 100,
        'api_access': true,
        'advanced_reports': true,
        'custom_themes': true,
        'real_crypto': true,
      },
      metadata: {
        'customer_id': 'CUST-12345',
        'order_number': 'ORD-67890',
        'purchased_by': 'john.doe@example.com',
        'purchase_date': DateTime.now().toIso8601String(),
        'crypto_provider': 'paseto_dart',
      },
      isTrial: false,
    );

    print('✅ License created successfully!');
    _printLicenseDetails(license, 'Standard PASETO');

    print('\n2. Creating trial license:');
    // Создаем новый приватный ключ из байтов для этой операции
    final privateKey2 =
        LicensifyPrivateKey.ed25519(Uint8List.fromList(privateKeyBytes));
    try {
      final trialLicense = await Licensify.createLicense(
        privateKey: privateKey2,
        appId: 'com.example.trial',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        type: LicenseType.standard,
        features: {
          'max_users': 5,
          'api_access': false,
          'trial_limitations': true,
        },
        isTrial: true,
      );

      print('✅ Trial license created successfully!');
      _printLicenseDetails(trialLicense, 'Trial PASETO');
    } finally {
      privateKey2.dispose();
    }

    print('\n3. Creating custom license type:');
    // Создаем еще один новый приватный ключ из байтов
    final privateKey3 =
        LicensifyPrivateKey.ed25519(Uint8List.fromList(privateKeyBytes));
    try {
      final customLicense = await Licensify.createLicense(
        privateKey: privateKey3,
        appId: 'com.example.enterprise',
        expirationDate: DateTime.now().add(const Duration(days: 730)),
        type: LicenseType('enterprise'),
        features: {
          'max_users': 1000,
          'api_access': true,
          'advanced_reports': true,
          'custom_themes': true,
          'white_label': true,
          'sso_support': true,
          'priority_support': true,
        },
        metadata: {
          'customer_tier': 'enterprise',
          'dedicated_support': true,
          'sla_level': 'premium',
        },
      );

      print('✅ Enterprise license created successfully!');
      _printLicenseDetails(customLicense, 'Enterprise PASETO');
    } finally {
      privateKey3.dispose();
    }
  }

  /// Examples of validating PASETO licenses
  Future<void> licenseValidationExamples() async {
    print('\n\n🔍 LICENSE VALIDATION EXAMPLES');
    print('===============================\n');

    print('1. Complete license validation:');
    // Используем байты публичного ключа для валидации
    final result = await Licensify.validateLicenseWithKeyBytes(
      license: license,
      publicKeyBytes: publicKeyBytes,
    );

    if (result.isValid) {
      print('✅ License is completely valid');
      print('   Message: ${result.message}');

      print('\n   📋 License Details After Validation:');
      print('   ID: ${license.id}');
      print('   App ID: ${license.appId}');
      print('   Type: ${license.type.name}');
      print('   Expires: ${license.expirationDate}');
      print('   Created: ${license.createdAt}');
      print('   Trial: ${license.isTrial}');
      print('   Expired: ${license.isExpired}');
      print('   Days remaining: ${license.remainingDays}');
    } else {
      print('❌ License validation failed: ${result.message}');
    }

    print('\n2. Separate validation checks:');

    // Test signature validation - создаем новый публичный ключ
    final publicKey =
        LicensifyPublicKey.ed25519(Uint8List.fromList(publicKeyBytes));
    try {
      final signatureResult = await Licensify.validateSignature(
        license: license,
        publicKey: publicKey,
      );
      print(
          '   Signature: ${signatureResult.isValid ? "✅ Valid" : "❌ Invalid"}');
      if (!signatureResult.isValid) {
        print('   Error: ${signatureResult.message}');
      }
    } finally {
      publicKey.dispose();
    }

    // Test expiration validation - используем байты ключа для повторной валидации
    await Licensify.validateLicenseWithKeyBytes(
      license: license,
      publicKeyBytes: publicKeyBytes,
    );
    // Note: Expiration validation is included in full validation, checking manually here
    final expirationResult = license.isExpired
        ? const LicenseValidationResult(
            isValid: false, message: 'License expired')
        : const LicenseValidationResult(
            isValid: true, message: 'License not expired');
    print(
        '   Expiration: ${expirationResult.isValid ? "✅ Not expired" : "❌ Expired"}');
    if (!expirationResult.isValid) {
      print('   Error: ${expirationResult.message}');
    }

    print('\n3. Testing tamper protection:');

    // Create a fake token by modifying the existing one
    final tokenParts = license.token.split('.');
    if (tokenParts.length >= 3) {
      final tamperedToken =
          '${tokenParts[0]}.${tokenParts[1]}.fake_signature_data';
      final fakeToken = License.fromToken(tamperedToken);

      final fakeResult = await Licensify.validateLicenseWithKeyBytes(
        license: fakeToken,
        publicKeyBytes: publicKeyBytes,
      );
      print(
          '   Tampered token: ${!fakeResult.isValid ? "✅ Rejected" : "❌ Accepted"}');
      if (!fakeResult.isValid) {
        print('   Security working: ${fakeResult.message}');
      }
    }

    print('\n4. Testing expired license:');

    // Создаем новый приватный ключ для создания просроченной лицензии
    final privateKey4 =
        LicensifyPrivateKey.ed25519(Uint8List.fromList(privateKeyBytes));
    try {
      final expiredLicense = await Licensify.createLicense(
        privateKey: privateKey4,
        appId: 'com.example.expired',
        expirationDate: DateTime.now().subtract(const Duration(days: 1)),
        type: LicenseType.standard,
      );

      // Validate signature first to populate payload
      await Licensify.validateLicenseWithKeyBytes(
        license: expiredLicense,
        publicKeyBytes: publicKeyBytes,
      );
      // Check expiration manually since it's included in full validation
      final expiredResult = expiredLicense.isExpired
          ? const LicenseValidationResult(
              isValid: false, message: 'License expired')
          : const LicenseValidationResult(
              isValid: true, message: 'License not expired');
      print(
          '   Expired license: ${!expiredResult.isValid ? "✅ Rejected" : "❌ Accepted"}');
      if (!expiredResult.isValid) {
        print('   Expiration check working: ${expiredResult.message}');
      }
    } finally {
      privateKey4.dispose();
    }
  }

  /// Examples of advanced PASETO features
  Future<void> advancedFeaturesExamples() async {
    print('\n\n🚀 ADVANCED FEATURES EXAMPLES');
    print('==============================\n');

    print('1. PASETO v4.local encryption (symmetric):');

    // Generate symmetric key and save bytes for reuse
    final symmetricKey = LicensifyKey.generateLocalKey();
    final symmetricKeyBytes = List<int>.from(symmetricKey.keyBytes);
    symmetricKey.dispose(); // Dispose original key immediately

    // Encrypt sensitive data
    final sensitiveData = {
      'license_key': 'ultra-secret-license-key-abc123',
      'activation_token': 'ACTIVATE-TOKEN-XYZ789',
      'customer_secret': 'customer-internal-data-456',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // Create fresh key for encryption
      final encryptKey = LicensifySymmetricKey.xchacha20(
          Uint8List.fromList(symmetricKeyBytes));

      final encryptedToken = await Licensify.encryptData(
        data: sensitiveData,
        encryptionKey: encryptKey,
        footer: jsonEncode({'purpose': 'sensitive_data', 'version': '2.0'}),
      );

      print('✅ Data encrypted with PASETO v4.local');
      print('   Token: ${encryptedToken.substring(0, 40)}...');

      // Create fresh key for decryption
      final decryptKey = LicensifySymmetricKey.xchacha20(
          Uint8List.fromList(symmetricKeyBytes));

      try {
        final decryptedResult = await Licensify.decryptData(
          encryptedToken: encryptedToken,
          encryptionKey: decryptKey,
        );

        print('✅ Data decrypted successfully');
        print('   Original keys: ${sensitiveData.keys.join(", ")}');
        print('   Decrypted keys: ${decryptedResult.keys.join(", ")}');

        final dataMatches = _comparePayloads(sensitiveData, decryptedResult);
        print('   Data integrity: ${dataMatches ? "✅ Verified" : "❌ Failed"}');
      } finally {
        decryptKey.dispose();
      }
    } catch (e) {
      print('❌ v4.local encryption error: $e');
    }

    print('\n2. Automatic key generation with cleanup:');

    // Demonstrate automatic key generation
    final autoResult = await Licensify.createLicenseWithKeys(
      appId: 'com.example.auto',
      expirationDate: DateTime.now().add(const Duration(days: 90)),
      type: LicenseType('startup'),
      features: {'api_calls': 10000, 'storage_gb': 50},
    );

    print('✅ License with auto-generated keys created');
    print('   Public key: ${autoResult.publicKeyBytes.length} bytes');
    print('   🔒 Private key automatically disposed');

    // Validate with the returned public key bytes
    final validationResult = await Licensify.validateLicenseWithKeyBytes(
      license: autoResult.license,
      publicKeyBytes: autoResult.publicKeyBytes,
    );
    print(
        '   Auto validation: ${validationResult.isValid ? "✅ Working" : "❌ Failed"}');

    print('\n3. Encryption with auto-generated key:');

    final configData = {
      'endpoint': 'https://api.example.com/licenses',
      'feature_flags': {
        'advanced_analytics': true,
        'multi_tenant': true,
        'custom_themes': true,
      },
    };

    final encryptResult = await Licensify.encryptDataWithKey(
      data: configData,
    );

    print('✅ Config encrypted with auto-generated key');
    print('   Token: ${encryptResult.encryptedToken.substring(0, 40)}...');
    print('   Key: ${encryptResult.keyBytes.length} bytes');

    // Decrypt with the returned key bytes
    final tempKey = LicensifySymmetricKey.xchacha20(encryptResult.keyBytes);
    late Map<String, dynamic> decryptedConfig;
    try {
      decryptedConfig = await Licensify.decryptData(
        encryptedToken: encryptResult.encryptedToken,
        encryptionKey: tempKey,
      );
    } finally {
      tempKey.dispose();
    }

    print('✅ Config decrypted successfully');
    print('   Endpoint: ${decryptedConfig['endpoint']}');
    print('   Feature flags: ${decryptedConfig['feature_flags']}');
  }

  /// Performance testing examples
  Future<void> performanceExamples() async {
    print('\n\n⚡ PERFORMANCE EXAMPLES');
    print('=======================\n');

    print('1. Bulk license generation and validation:');

    const testCount = 50;
    final stopwatch = Stopwatch()..start();

    final licenses = <License>[];

    // Создаем приватный ключ для генерации лицензий
    final perfPrivateKey =
        LicensifyPrivateKey.ed25519(Uint8List.fromList(privateKeyBytes));

    try {
      for (int i = 0; i < testCount; i++) {
        final testLicense = await Licensify.createLicense(
          privateKey: perfPrivateKey,
          appId: 'com.example.perf$i',
          expirationDate: DateTime.now().add(const Duration(days: 365)),
          type: i % 2 == 0 ? LicenseType.pro : LicenseType.standard,
          features: {'test_id': i, 'batch': 'performance_test'},
        );
        licenses.add(testLicense);
      }
    } finally {
      perfPrivateKey.dispose();
    }

    final generationTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    int validCount = 0;
    for (final testLicense in licenses) {
      final result = await Licensify.validateLicenseWithKeyBytes(
        license: testLicense,
        publicKeyBytes: publicKeyBytes,
      );
      if (result.isValid) validCount++;
    }

    final validationTime = stopwatch.elapsedMilliseconds;
    stopwatch.stop();

    print('✅ Generated $testCount licenses in ${generationTime}ms');
    print(
        '   Average generation time: ${(generationTime / testCount).toStringAsFixed(2)}ms per license');
    print('✅ Validated $validCount/$testCount licenses in ${validationTime}ms');
    print(
        '   Average validation time: ${(validationTime / testCount).toStringAsFixed(2)}ms per license');
    print('   Total time: ${generationTime + validationTime}ms');
    print(
        '   Throughput: ${(testCount * 1000 / (generationTime + validationTime)).toStringAsFixed(1)} licenses/second');

    print('\n2. Token size analysis:');

    final sampleLicense = licenses.first;
    print('   Token length: ${sampleLicense.token.length} characters');
    print('   Token format: v4.public.[payload].[signature]');
    print(
        '   Payload size estimate: ~${(sampleLicense.token.length * 0.6).round()} chars');
    print(
        '   Signature size estimate: ~${(sampleLicense.token.length * 0.4).round()} chars');

    // Очищаем основные ключи в конце
    keyPair.privateKey.dispose();
    keyPair.publicKey.dispose();
  }

  /// Helper method to print license details
  void _printLicenseDetails(License license, String type) {
    print('   Type: $type');
    print('   Token starts with: ${license.token.substring(0, 30)}...');
    print('   Token length: ${license.token.length} characters');
    print('   License ID: ${license.id}');
    print('   App ID: ${license.appId}');
    print('   License Type: ${license.type.name}');
    print('   Trial: ${license.isTrial}');
    print('   Created: ${license.createdAt}');
    print('   Expires: ${license.expirationDate}');
    print('   Days remaining: ${license.remainingDays}');

    if (license.features.isNotEmpty) {
      print('   Features: ${license.features.keys.join(", ")}');
    }

    if (license.metadata != null && license.metadata!.isNotEmpty) {
      print('   Metadata keys: ${license.metadata!.keys.join(", ")}');
    }
  }

  /// Helper method to compare payloads
  bool _comparePayloads(
      Map<String, dynamic> original, Map<String, dynamic> decrypted) {
    // Filter out PASETO internal fields that start with underscore
    final filteredDecrypted = Map<String, dynamic>.from(decrypted);
    filteredDecrypted.removeWhere((key, value) => key.startsWith('_'));

    if (original.length != filteredDecrypted.length) return false;

    for (final key in original.keys) {
      if (!filteredDecrypted.containsKey(key) ||
          original[key] != filteredDecrypted[key]) {
        return false;
      }
    }

    return true;
  }
}
