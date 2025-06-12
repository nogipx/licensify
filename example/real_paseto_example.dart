// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:licensify/licensify.dart';

/// Example demonstrating real PASETO v4 implementation with paseto_dart
///
/// This example shows the modern, secure approach to license management
/// using actual PASETO v4.public and v4.local tokens with real cryptography.
void main() async {
  print('🔐 Real PASETO v4 License Management Example');
  print('============================================\n');

  // 1. Generate real Ed25519 key pair for PASETO v4.public
  print('📋 Step 1: Generating real Ed25519 key pair...');
  final keyPair = await LicensifyPasetoKeyPair.generateEd25519();
  print('✅ Generated Ed25519 key pair with real cryptography');
  print('   Private key: ${keyPair.privateKey.keyBytes.length} bytes');
  print('   Public key:  ${keyPair.publicKey!.keyBytes.length} bytes\n');

  // 2. Create license generator (server-side)
  print('📋 Step 2: Creating license generator...');
  final generator = PasetoLicenseGenerator(privateKey: keyPair.privateKey);
  print('✅ License generator ready with real PASETO v4.public\n');

  // 3. Generate a new license with metadata and footer
  print('📋 Step 3: Generating real PASETO license...');
  final expirationDate = DateTime.now().add(const Duration(days: 365));

  final license = await generator.call(
    appId: 'com.example.realapp',
    expirationDate: expirationDate,
    type: LicenseType.pro,
    features: {
      'max_users': 100,
      'api_access': true,
      'advanced_reports': true,
      'custom_themes': true,
      'real_crypto': true, // New feature flag!
    },
    metadata: {
      'customer_id': 'CUST-REAL-12345',
      'order_number': 'ORD-PASETO-67890',
      'purchased_by': 'john.doe@realcrypto.com',
      'purchase_date': DateTime.now().toIso8601String(),
      'crypto_provider': 'paseto_dart',
    },
    isTrial: false,
  );

  print('✅ Real PASETO license generated successfully!');
  print('   Token starts with: ${license.token.substring(0, 30)}...');
  print('   Token length: ${license.token.length} characters');
  print('   This is a REAL cryptographically signed PASETO v4.public token!\n');

  // 4. Create license validator (client-side)
  print('📋 Step 4: Creating license validator...');
  final validator = PasetoLicenseValidator(publicKey: keyPair.publicKey!);
  print('✅ License validator ready with real PASETO v4.public verification\n');

  // 5. Validate the license with real cryptographic verification
  print('📋 Step 5: Validating license with real cryptography...');
  final result = await validator.validate(license);

  print('✅ Validation result: ${result.isValid}');
  print('   Message: ${result.message}');

  if (result.isValid) {
    print('\n📦 License Details (after real verification):');
    print('   🆔 ID: ${license.id}');
    print('   📱 App ID: ${license.appId}');
    print('   🏷️ Type: ${license.type.name}');
    print('   📅 Expires: ${license.expirationDate}');
    print('   ⏰ Created: ${license.createdAt}');
    print('   🧪 Trial: ${license.isTrial}');
    print('   ⚡ Days remaining: ${license.remainingDays}');
    print('   🔒 Real crypto: ${license.features['real_crypto']}');

    if (license.metadata != null) {
      print('\n📋 Metadata:');
      license.metadata!.forEach((key, value) {
        print('   $key: $value');
      });
    }
  }

  // 6. Test with tampering protection
  print('\n📋 Step 6: Testing tamper protection...');

  // Try to create a fake token by modifying the existing one
  final fakeParts = license.token.split('.');
  if (fakeParts.length >= 3) {
    // Tamper with the signature part
    final tamperedToken = '${fakeParts[0]}.${fakeParts[1]}.fake_signature_here';
    final fakeToken = PasetoLicense.fromToken(tamperedToken);

    final fakeResult = await validator.validate(fakeToken);
    print('Tampered token validation: ${fakeResult.isValid}');
    print('Expected: false - ✅ ${!fakeResult.isValid ? "PASSED" : "FAILED"}');
  }

  // 7. Test expired license
  print('\n📋 Step 7: Testing expired license...');
  final expiredLicense = await generator.call(
    appId: 'com.example.expired',
    expirationDate: DateTime.now().subtract(const Duration(days: 1)),
    type: LicenseType.standard,
  );

  await validator.validateSignature(expiredLicense); // Populate payload first
  final expiredResult = validator.validateExpiration(expiredLicense);
  print('Expired license check: ${expiredResult.isValid}');
  print('Expected: false - ✅ ${!expiredResult.isValid ? "PASSED" : "FAILED"}');

  // 8. Demonstrate PASETO v4.local (symmetric encryption) capabilities
  print('\n📋 Step 8: Demonstrating PASETO v4.local encryption...');

  // Create a symmetric key for v4.local - use the same key for encryption and decryption
  final symmetricKey = PasetoV4Implementation.generateSymmetricKey();
  print('✅ Generated XChaCha20 symmetric key for v4.local');

  // Create some sensitive data
  final sensitiveData = {
    'license_key': 'super-secret-key-123',
    'activation_code': 'ACTIVATE-ME-456',
    'internal_id': 'internal-${DateTime.now().millisecondsSinceEpoch}',
    'timestamp': DateTime.now().toIso8601String(),
  };

  try {
    // Encrypt the data with v4.local
    final encryptedToken = await PasetoV4.encryptLocal(
      payload: sensitiveData,
      symmetricKeyBytes: symmetricKey,
      footer: jsonEncode({'purpose': 'license_activation', 'version': '1.0'}),
    );

    print('✅ Encrypted sensitive data with PASETO v4.local');
    print(
      '   Encrypted token starts with: ${encryptedToken.substring(0, 20)}...',
    );

    // Decrypt the data with the SAME key
    final decryptedResult = await PasetoV4.decryptLocal(
      token: encryptedToken,
      symmetricKeyBytes: symmetricKey, // Same key!
    );

    print('✅ Decrypted data successfully');
    print('   Original: $sensitiveData');
    print('   Decrypted: ${decryptedResult.payload}');
    print('   Footer: ${decryptedResult.footer}');

    final dataMatches = _mapsEqual(sensitiveData, decryptedResult.payload);
    print('   Data integrity: ✅ ${dataMatches ? "VERIFIED" : "FAILED"}');
  } catch (e) {
    print('❌ Error with v4.local encryption: $e');
  }

  // 9. Performance test
  print('\n📋 Step 9: Performance testing...');
  final stopwatch = Stopwatch()..start();

  const testCount = 10;
  for (int i = 0; i < testCount; i++) {
    final testLicense = await generator.call(
      appId: 'com.example.perf$i',
      expirationDate: DateTime.now().add(const Duration(days: 30)),
    );
    await validator.validate(testLicense);
  }

  stopwatch.stop();
  final avgTime = stopwatch.elapsedMilliseconds / testCount;
  print('✅ Generated and validated $testCount licenses');
  print('   Average time per license: ${avgTime.toStringAsFixed(2)}ms');

  print('\n🎉 Real PASETO License Example Complete!');
  print('\n💡 Key advantages of real PASETO implementation:');
  print('   • ✅ Real Ed25519 cryptographic signatures');
  print('   • ✅ Tamper-proof token structure');
  print('   • ✅ Built-in expiration handling');
  print('   • ✅ Modern cryptography (Ed25519 + XChaCha20)');
  print('   • ✅ Self-contained tokens');
  print('   • ✅ JSON payload format');
  print('   • ✅ Better security than traditional JWT');
  print('   • ✅ Footer support for metadata');
  print('   • ✅ v4.local symmetric encryption support');
  print('   • ✅ Implicit assertions for additional security');
  print('\n🔒 This implementation provides military-grade security!');
}

/// Utility function to compare maps for equality
bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
  if (map1.length != map2.length) return false;

  for (final key in map1.keys) {
    if (!map2.containsKey(key) || map1[key] != map2[key]) {
      return false;
    }
  }

  return true;
}
