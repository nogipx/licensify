// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Example demonstrating PASETO-based license generation and validation
///
/// This example shows the modern, secure approach to license management
/// using PASETO v4.public tokens instead of traditional signatures.
void main() async {
  print('🔐 PASETO License Management Example');
  print('====================================\n');

  // 1. Generate Ed25519 key pair for PASETO v4.public
  print('📋 Step 1: Generating Ed25519 key pair...');
  final keyPair = await LicensifyPasetoKeyPair.generateEd25519();
  print('✅ Generated Ed25519 key pair');
  print('   Private key: ${keyPair.privateKey.keyBytes.length} bytes');
  print('   Public key:  ${keyPair.publicKey!.keyBytes.length} bytes\n');

  // 2. Create license generator (server-side)
  print('📋 Step 2: Creating license generator...');
  final generator = PasetoLicenseGenerator(privateKey: keyPair.privateKey);
  print('✅ License generator ready\n');

  // 3. Generate a new license
  print('📋 Step 3: Generating PASETO license...');
  final expirationDate = DateTime.now().add(const Duration(days: 365));

  final license = await generator.call(
    appId: 'com.example.myapp',
    expirationDate: expirationDate,
    type: LicenseType.pro,
    features: {
      'max_users': 100,
      'api_access': true,
      'advanced_reports': true,
      'custom_themes': true,
    },
    metadata: {
      'customer_id': 'CUST-12345',
      'order_number': 'ORD-67890',
      'purchased_by': 'john.doe@example.com',
      'purchase_date': DateTime.now().toIso8601String(),
    },
    isTrial: false,
  );

  print('✅ License generated successfully!');
  print('   Token starts with: ${license.token.substring(0, 20)}...');
  print('   Token length: ${license.token.length} characters\n');

  // 4. Create license validator (client-side)
  print('📋 Step 4: Creating license validator...');
  final validator = PasetoLicenseValidator(publicKey: keyPair.publicKey!);
  print('✅ License validator ready\n');

  // 5. Validate the license
  print('📋 Step 5: Validating license...');
  final validationResult = await validator.validate(license);

  if (validationResult.isValid) {
    print('✅ License validation successful!');
    print('   Message: ${validationResult.message}');

    // Access license information after validation
    print('\n📄 License Information:');
    print('   ID: ${license.id}');
    print('   App ID: ${license.appId}');
    print('   Type: ${license.type}');
    print('   Trial: ${license.isTrial}');
    print('   Created: ${license.createdAt}');
    print('   Expires: ${license.expirationDate}');
    print('   Days remaining: ${license.remainingDays}');
    print('   Is expired: ${license.isExpired}');

    print('\n🎯 Features:');
    license.features.forEach((key, value) {
      print('   $key: $value');
    });

    print('\n📊 Metadata:');
    license.metadata?.forEach((key, value) {
      print('   $key: $value');
    });
  } else {
    print('❌ License validation failed!');
    print('   Error: ${validationResult.message}');
  }

  print('\n====================================');

  // 6. Demonstrate signature vs. expiration validation
  print('\n📋 Step 6: Separate validation checks...');

  final signatureResult = await validator.validateSignature(license);
  print(
    'Signature validation: ${signatureResult.isValid} - ${signatureResult.message}',
  );

  final expirationResult = validator.validateExpiration(license);
  print(
    'Expiration validation: ${expirationResult.isValid} - ${expirationResult.message}',
  );

  // 7. Test with expired license
  print('\n📋 Step 7: Testing expired license...');
  final expiredLicense = await generator.call(
    appId: 'com.example.expired',
    expirationDate: DateTime.now().subtract(const Duration(days: 1)),
    type: LicenseType.standard,
  );

  await validator.validateSignature(expiredLicense); // Populate payload
  final expiredResult = validator.validateExpiration(expiredLicense);
  print(
    'Expired license check: ${expiredResult.isValid} - ${expiredResult.message}',
  );

  // 8. Demonstrate fluent API
  print('\n📋 Step 8: Using fluent API...');
  final newKeyPair = await LicensifyPasetoKeyPair.generateEd25519();

  // Generate license using fluent API
  final fluentLicense = await newKeyPair.privateKey.licenseGenerator.call(
    appId: 'com.example.fluent',
    expirationDate: DateTime.now().add(const Duration(days: 30)),
    type: LicenseType('trial'),
    isTrial: true,
  );

  // Validate using fluent API
  final fluentResult = await newKeyPair.publicKey!.licenseValidator.validate(
    fluentLicense,
  );
  print(
    'Fluent API result: ${fluentResult.isValid} - Trial: ${fluentLicense.isTrial}',
  );

  print('\n🎉 PASETO License Example Complete!');
  print('\n💡 Key advantages of PASETO:');
  print('   • No algorithm confusion attacks');
  print('   • Built-in expiration handling');
  print('   • Modern cryptography (Ed25519)');
  print('   • Self-contained tokens');
  print('   • JSON payload format');
  print('   • Better security than traditional JWT');
}

/// Utility function to demonstrate key serialization
void demonstrateKeySerialization() async {
  print('\n📋 Key Serialization Example:');

  // Generate keys using the utility
  final keyBytes = await Ed25519KeyGenerator.generateKeyPairAsBytes();
  print('Generated key bytes:');
  print('  Private: ${keyBytes['privateKey']!.length} bytes');
  print('  Public:  ${keyBytes['publicKey']!.length} bytes');

  // Create keys from bytes
  final privateKey = LicensifyPasetoPrivateKey.ed25519(keyBytes['privateKey']!);
  final publicKey = LicensifyPasetoPublicKey.ed25519(keyBytes['publicKey']!);

  print('Keys created from bytes successfully!');
  print('  Private key type: ${privateKey.keyType}');
  print('  Public key type:  ${publicKey.keyType}');
}
