// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
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

    final endTime = DateTime.now();

    print('✅ Generated Ed25519 key pair');
    print('   Private key: ${keyPair.privateKey.keyBytes.length} bytes');
    print('   Public key:  ${keyPair.publicKey!.keyBytes.length} bytes');
    print(
        '   Generation time: ${endTime.difference(startTime).inMilliseconds}ms');
    print('   Key type: ${keyPair.keyType}');
    print('   Is consistent: ${keyPair.isConsistent}');

    print('\n2. Generating XChaCha20 key for PASETO v4.local:');
    final symmetricKey = LicensifyKey.generateLocalKey();
    print('✅ Generated XChaCha20 symmetric key');
    print('   Key size: ${symmetricKey.keyBytes.length} bytes');
    print('   Key type: ${symmetricKey.keyType}');
  }

  /// Examples of creating PASETO licenses
  Future<void> licenseCreationExamples() async {
    print('\n\n📝 LICENSE CREATION EXAMPLES');
    print('============================\n');

    final generator = LicenseGenerator(privateKey: keyPair.privateKey);

    print('1. Creating standard PASETO license:');
    license = await generator.call(
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
    final trialLicense = await generator.call(
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

    print('\n3. Creating custom license type:');
    final customLicense = await generator.call(
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
  }

  /// Examples of validating PASETO licenses
  Future<void> licenseValidationExamples() async {
    print('\n\n🔍 LICENSE VALIDATION EXAMPLES');
    print('===============================\n');

    final validator = LicenseValidator(publicKey: keyPair.publicKey!);

    print('1. Complete license validation:');
    final result = await validator.validate(license);

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

    // Test signature validation
    final signatureResult = await validator.validateSignature(license);
    print('   Signature: ${signatureResult.isValid ? "✅ Valid" : "❌ Invalid"}');
    if (!signatureResult.isValid) {
      print('   Error: ${signatureResult.message}');
    }

    // Test expiration validation
    final expirationResult = validator.validateExpiration(license);
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

      final fakeResult = await validator.validate(fakeToken);
      print(
          '   Tampered token: ${!fakeResult.isValid ? "✅ Rejected" : "❌ Accepted"}');
      if (!fakeResult.isValid) {
        print('   Security working: ${fakeResult.message}');
      }
    }

    print('\n4. Testing expired license:');

    final generator = LicenseGenerator(privateKey: keyPair.privateKey);
    final expiredLicense = await generator.call(
      appId: 'com.example.expired',
      expirationDate: DateTime.now().subtract(const Duration(days: 1)),
      type: LicenseType.standard,
    );

    // Validate signature first to populate payload
    await validator.validateSignature(expiredLicense);
    final expiredResult = validator.validateExpiration(expiredLicense);
    print(
        '   Expired license: ${!expiredResult.isValid ? "✅ Rejected" : "❌ Accepted"}');
    if (!expiredResult.isValid) {
      print('   Expiration check working: ${expiredResult.message}');
    }
  }

  /// Examples of advanced PASETO features
  Future<void> advancedFeaturesExamples() async {
    print('\n\n🚀 ADVANCED FEATURES EXAMPLES');
    print('==============================\n');

    print('1. PASETO v4.local encryption (symmetric):');

    // Generate symmetric key
    final symmetricKey = LicensifyKey.generateLocalKey();

    // Encrypt sensitive data
    final sensitiveData = {
      'license_key': 'ultra-secret-license-key-abc123',
      'activation_token': 'ACTIVATE-TOKEN-XYZ789',
      'customer_secret': 'customer-internal-data-456',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final encryptedToken = await symmetricKey.crypto.encrypt(
        sensitiveData,
        footer: jsonEncode({'purpose': 'sensitive_data', 'version': '2.0'}),
      );

      print('✅ Data encrypted with PASETO v4.local');
      print('   Token: ${encryptedToken.substring(0, 40)}...');

      // Decrypt the data
      final decryptedResult = await symmetricKey.crypto.decrypt(encryptedToken);

      print('✅ Data decrypted successfully');
      print('   Original keys: ${sensitiveData.keys.join(", ")}');
      print('   Decrypted keys: ${decryptedResult.keys.join(", ")}');
      print('   Footer: $decryptedResult');

      final dataMatches = _comparePayloads(sensitiveData, decryptedResult);
      print('   Data integrity: ${dataMatches ? "✅ Verified" : "❌ Failed"}');
    } catch (e) {
      print('❌ v4.local encryption error: $e');
    }

    print('\n2. Fluent API usage:');

    // Demonstrate fluent API through key objects
    final fluentGenerator = keyPair.privateKey.licenseGenerator;
    final fluentValidator = keyPair.publicKey!.licenseValidator;

    final fluentLicense = await fluentGenerator.call(
      appId: 'com.example.fluent',
      expirationDate: DateTime.now().add(const Duration(days: 90)),
      type: LicenseType('startup'),
      features: {'api_calls': 10000, 'storage_gb': 50},
    );

    final fluentResult = await fluentValidator.validate(fluentLicense);
    print('   Fluent API: ${fluentResult.isValid ? "✅ Working" : "❌ Failed"}');

    print('\n3. License payload generation from existing data:');

    final customPayload = {
      'sub': 'custom-license-12345',
      'app_id': 'com.example.custom',
      'exp': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
      'iat': DateTime.now().toIso8601String(),
      'type': 'custom',
      'features': {'feature_a': true, 'feature_b': 'premium'},
      'trial': false,
    };

    final generator = LicenseGenerator(privateKey: keyPair.privateKey);
    final customLicense = await generator.fromPayload(payload: customPayload);

    print('✅ License from custom payload created');
    print('   Token starts with: ${customLicense.token.substring(0, 30)}...');

    // Validate the custom license
    final validator = LicenseValidator(publicKey: keyPair.publicKey!);
    final customResult = await validator.validate(customLicense);
    print(
        '   Custom validation: ${customResult.isValid ? "✅ Valid" : "❌ Invalid"}');
  }

  /// Performance testing examples
  Future<void> performanceExamples() async {
    print('\n\n⚡ PERFORMANCE EXAMPLES');
    print('=======================\n');

    final generator = LicenseGenerator(privateKey: keyPair.privateKey);
    final validator = LicenseValidator(publicKey: keyPair.publicKey!);

    print('1. Bulk license generation and validation:');

    const testCount = 50;
    final stopwatch = Stopwatch()..start();

    final licenses = <License>[];
    for (int i = 0; i < testCount; i++) {
      final testLicense = await generator.call(
        appId: 'com.example.perf$i',
        expirationDate: DateTime.now().add(const Duration(days: 365)),
        type: i % 2 == 0 ? LicenseType.pro : LicenseType.standard,
        features: {'test_id': i, 'batch': 'performance_test'},
      );
      licenses.add(testLicense);
    }

    final generationTime = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    int validCount = 0;
    for (final testLicense in licenses) {
      final result = await validator.validate(testLicense);
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
    if (original.length != decrypted.length) return false;

    for (final key in original.keys) {
      if (!decrypted.containsKey(key) || original[key] != decrypted[key]) {
        return false;
      }
    }

    return true;
  }
}
