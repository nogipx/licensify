// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

void main() async {
  // Generate RSA key pair
  print('Generating RSA keys...');
  final keys = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

  print('Public key:');
  print(keys.publicKey);
  print('\nPrivate key:');
  print(keys.privateKey);

  // Create a license generator
  final generator = GenerateLicenseUseCase(privateKey: keys.privateKey);

  // Generate a license with a standard type
  print('\nGenerating standard license...');
  final license = generator.generateLicense(
    appId: 'com.example.app',
    expirationDate: DateTime.now().add(Duration(days: 30)),
    type: LicenseType.trial,
  );

  print('Generated license:');
  print('ID: ${license.id}');
  print('Type: ${license.type.name}');
  print('Expiration date: ${license.expirationDate}');
  print('Signature: ${license.signature}');

  // Generate a license with a custom type
  print('\nGenerating custom license type...');
  final enterpriseType = LicenseType('enterprise');
  final enterpriseLicense = generator.generateLicense(
    appId: 'com.example.app',
    expirationDate: DateTime.now().add(Duration(days: 365)),
    type: enterpriseType,
    features: {
      'maxUsers': 100,
      'supportLevel': 'premium',
      'modules': ['admin', 'analytics', 'reporting'],
    },
  );

  print('Generated enterprise license:');
  print('ID: ${enterpriseLicense.id}');
  print('Type: ${enterpriseLicense.type.name}');
  print('Features: ${enterpriseLicense.features}');
  print('Expiration date: ${enterpriseLicense.expirationDate}');

  // Verify license with public key
  print('\nVerifying licenses...');
  final validator = LicenseValidator(publicKey: keys.publicKey);

  final isStandardValid = validator.validateLicense(license);
  print('Standard license valid: $isStandardValid');

  final isEnterpriseValid = validator.validateLicense(enterpriseLicense);
  print('Enterprise license valid: $isEnterpriseValid');

  // Create an invalid license for demonstration
  print('\nVerifying tampered license...');
  final invalidLicense = License(
    id: license.id,
    appId: license.appId,
    // Change expiration date, which makes the signature invalid
    expirationDate: license.expirationDate.add(Duration(days: 1)),
    createdAt: license.createdAt,
    signature: license.signature,
    type: license.type,
    features: license.features,
    metadata: license.metadata,
  );

  final isInvalidSignatureValid = validator.validateSignature(invalidLicense);
  print('Tampered license signature valid: $isInvalidSignatureValid');
}
