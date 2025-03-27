import 'dart:convert';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/digests/sha512.dart';

/// Comprehensive example of Licensify package usage
///
/// This file demonstrates all the core functionalities of the Licensify package
/// including key generation, license creation, validation, storage, and more.
void main() {
  print('====== LICENSIFY EXAMPLES ======\n');

  // First, let's create our main example object
  final examples = LicensifyExamples();

  // Run the comprehensive examples
  examples.runAllExamples();
}

/// Main class containing all examples
class LicensifyExamples {
  // Store key pairs for reuse across examples
  late final LicensifyKeyPair rsaKeyPair;
  late final LicensifyKeyPair ecdsaKeyPair;

  // Store licenses for reuse across examples
  late final License rsaLicense;
  late final License ecdsaLicense;

  /// Run all examples in sequence
  void runAllExamples() {
    // 1. Key generation examples
    keyGenerationExamples();

    // 2. License creation examples
    licenseCreationExamples();

    // 3. License validation examples
    licenseValidationExamples();

    // 4. Schema validation examples
    schemaValidationExamples();

    // 5. License storage examples
    licenseStorageExamples();

    // 6. Performance comparison examples
    performanceComparisonExamples();
  }

  /// Examples of generating cryptographic keys
  void keyGenerationExamples() {
    print('\n===== KEY GENERATION EXAMPLES =====');

    // Generate RSA keys (traditional approach)
    print('\n1. Generating RSA keys:');
    final rsaStartTime = DateTime.now();
    rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);
    final rsaEndTime = DateTime.now();

    print('RSA private key (excerpt):');
    print(rsaKeyPair.privateKey.content);
    print('RSA public key (excerpt):');
    print(rsaKeyPair.publicKey.content);
    print(
      'Generation time: ${rsaEndTime.difference(rsaStartTime).inMilliseconds}ms',
    );
    print('Private key size: ${rsaKeyPair.privateKey.content.length} bytes');
    print('Public key size: ${rsaKeyPair.publicKey.content.length} bytes');

    // Generate ECDSA keys (modern, more efficient approach)
    print('\n2. Generating ECDSA keys:');
    final ecdsaStartTime = DateTime.now();
    ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem(
      curve: EcCurve.p256, // NIST P-256 curve
      randomAlgorithm: SecureRandomAlgorithm.fortuna,
    );
    final ecdsaEndTime = DateTime.now();

    print('ECDSA private key (excerpt):');
    print(ecdsaKeyPair.privateKey.content);
    print('ECDSA public key (excerpt):');
    print(ecdsaKeyPair.publicKey.content);
    print(
      'Generation time: ${ecdsaEndTime.difference(ecdsaStartTime).inMilliseconds}ms',
    );
    print('Private key size: ${ecdsaKeyPair.privateKey.content.length} bytes');
    print('Public key size: ${ecdsaKeyPair.publicKey.content.length} bytes');

    // Show benefits of ECDSA over RSA
    _compareCryptoSystems(
      rsaKeyPair,
      ecdsaKeyPair,
      rsaEndTime.difference(rsaStartTime),
      ecdsaEndTime.difference(ecdsaStartTime),
    );
  }

  /// Examples of creating licenses
  void licenseCreationExamples() {
    print('\n\n===== LICENSE CREATION EXAMPLES =====');

    // Create RSA license
    print('\n1. Creating license with RSA:');
    final rsaGenerator = LicenseGenerateUseCase(
      privateKey: rsaKeyPair.privateKey,
    );

    rsaLicense = rsaGenerator.generateLicense(
      appId: 'com.example.app',
      expirationDate: DateTime.now().add(Duration(days: 365)),
      type: LicenseType.pro,
      features: {
        'maxUsers': 50,
        'modules': ['reporting', 'analytics', 'export'],
        'premium': true,
      },
      metadata: {
        'customerName': 'Acme Corp',
        'contactEmail': 'support@acme.com',
      },
    );

    _printLicenseDetails(rsaLicense, 'RSA');

    // Create ECDSA license
    print('\n2. Creating license with ECDSA:');
    final ecdsaGenerator = LicenseGenerateUseCase(
      privateKey: ecdsaKeyPair.privateKey,
      // Optionally specify hash algorithm (defaults to SHA-512)
      digest: SHA512Digest(),
    );

    ecdsaLicense = ecdsaGenerator.generateLicense(
      appId: 'com.example.app',
      expirationDate: DateTime.now().add(Duration(days: 365)),
      type: LicenseType.pro,
      features: {
        'maxUsers': 50,
        'modules': ['reporting', 'analytics', 'export'],
        'premium': true,
      },
      metadata: {
        'customerName': 'Acme Corp',
        'contactEmail': 'support@acme.com',
      },
    );

    _printLicenseDetails(ecdsaLicense, 'ECDSA');

    // Create a license with custom type
    print('\n3. Creating license with custom type:');
    final customLicense = rsaGenerator.generateLicense(
      appId: 'com.example.app',
      expirationDate: DateTime.now().add(Duration(days: 365)),
      type: LicenseType('enterprise'), // Custom license type
      features: {
        'maxUsers': 500,
        'modules': ['reporting', 'analytics', 'export', 'admin'],
        'premium': true,
        'enterpriseSupport': true,
      },
    );

    _printLicenseDetails(customLicense, 'Custom Type');
  }

  /// Examples of validating licenses
  void licenseValidationExamples() {
    print('\n\n===== LICENSE VALIDATION EXAMPLES =====');

    // Validate RSA license
    print('\n1. Validating RSA license:');
    final rsaValidator = LicenseValidator(publicKey: rsaKeyPair.publicKey);

    final rsaValidationResult = rsaValidator.validateLicense(rsaLicense);
    if (rsaValidationResult.isValid) {
      print('✅ RSA license is valid');
    } else {
      print('❌ RSA license is invalid: ${rsaValidationResult.message}');
    }

    // Validate ECDSA license
    print('\n2. Validating ECDSA license:');
    final ecdsaValidator = LicenseValidator(
      publicKey: ecdsaKeyPair.publicKey,
      digest: SHA512Digest(), // Must match the digest used for signing
    );

    final ecdsaValidationResult = ecdsaValidator.validateLicense(ecdsaLicense);
    if (ecdsaValidationResult.isValid) {
      print('✅ ECDSA license is valid');
    } else {
      print('❌ ECDSA license is invalid: ${ecdsaValidationResult.message}');
    }

    // Using LicenseValidateUseCase for more comprehensive validation
    print('\n3. Using LicenseValidateUseCase (async):');

    print(
      'The LicenseValidateUseCase returns a Future<LicenseValidateUseCaseResult>',
    );
    print('In a real app, you would use await or .then() to handle the result');
    print('Example usage with async/await:');
    print('''
Future<void> validateLicense(License license) async {
  final result = await licenseValidator(license);
  
  if (result.status is ActiveLicenseStatus) {
    final activeLicense = (result.status as ActiveLicenseStatus).license;
    print('License is active: \${activeLicense.type.name}');
  } else if (result.status is ExpiredLicenseStatus) {
    print('License has expired');
  }
}
''');

    // Demonstrate tampered license validation
    print('\n4. Validating tampered license:');
    final tamperedLicense = License(
      id: rsaLicense.id,
      appId: rsaLicense.appId,
      expirationDate: rsaLicense.expirationDate.add(
        Duration(days: 365),
      ), // Tampered expiration
      createdAt: rsaLicense.createdAt,
      signature:
          rsaLicense.signature, // Signature doesn't match the modified data
      type: rsaLicense.type,
      features: rsaLicense.features,
      metadata: rsaLicense.metadata,
    );

    final tamperedResult = rsaValidator.validateLicense(tamperedLicense);
    if (tamperedResult.isValid) {
      print('❌ SECURITY ISSUE: Tampered license validated as valid!');
    } else {
      print('✅ Security works: Tampered license detected');
      print('Error: ${tamperedResult.message}');
    }
  }

  /// Examples of schema validation
  void schemaValidationExamples() {
    print('\n\n===== SCHEMA VALIDATION EXAMPLES =====');

    // Define a schema for enterprise licenses
    print('\n1. Defining license schema:');
    final schema = LicenseSchema(
      featureSchema: {
        'maxUsers': SchemaField(
          type: FieldType.integer,
          required: true,
          validators: [NumberValidator(minimum: 1, maximum: 1000)],
        ),
        'modules': SchemaField(
          type: FieldType.array,
          required: true,
          validators: [
            ArrayValidator(minItems: 1, itemValidator: StringValidator()),
          ],
        ),
        'premium': SchemaField(type: FieldType.boolean, required: true),
      },
      metadataSchema: {
        'customerName': SchemaField(
          type: FieldType.string,
          required: true,
          validators: [StringValidator(minLength: 3)],
        ),
      },
      allowUnknownFeatures: false,
      allowUnknownMetadata: true,
    );

    print('Schema defined with:');
    print(
      '- Required features: maxUsers (int), modules (array), premium (bool)',
    );
    print('- Required metadata: customerName (string)');
    print('- Unknown features: not allowed');
    print('- Unknown metadata: allowed');

    // Validate license against schema
    print('\n2. Validating license against schema:');
    final rsaValidator = LicenseValidator(publicKey: rsaKeyPair.publicKey);

    final schemaResult = rsaValidator.validateSchema(rsaLicense, schema);
    if (schemaResult.isValid) {
      print('✅ License schema is valid');
    } else {
      print('❌ License schema is invalid:');
      final errors = schemaResult.errors;
      if (errors.isNotEmpty) {
        for (final entry in errors.entries) {
          print('  - ${entry.key}: ${entry.value}');
        }
      } else {
        print('  - Unknown validation errors');
      }
    }

    // Comprehensive validation with schema
    print('\n3. Comprehensive validation with schema:');
    final completeResult = rsaValidator.validateLicenseWithSchema(
      rsaLicense,
      schema,
    );
    print('License valid: $completeResult');

    // Create invalid license to demonstrate schema validation failure
    print('\n4. Validating license with invalid schema:');
    final invalidLicense = LicenseGenerateUseCase(
      privateKey: rsaKeyPair.privateKey,
    ).generateLicense(
      appId: 'com.example.app',
      expirationDate: DateTime.now().add(Duration(days: 365)),
      type: LicenseType.pro,
      features: {
        // Missing required 'maxUsers' field
        'modules': [], // Empty array (will fail minItems validation)
        'premium': 'yes', // Wrong type (string instead of boolean)
      },
      // Missing required 'customerName' field
    );

    final invalidSchemaResult = rsaValidator.validateSchema(
      invalidLicense,
      schema,
    );
    if (invalidSchemaResult.isValid) {
      print('❌ ISSUE: Invalid license schema validated as valid!');
    } else {
      print('✅ Schema validation works: Invalid license detected');
      print('Errors:');
      final errors = invalidSchemaResult.errors;
      if (errors.isNotEmpty) {
        for (final entry in errors.entries) {
          print('  - ${entry.key}: ${entry.value}');
        }
      } else {
        print('  - Unknown validation errors');
      }
    }
  }

  /// Examples of license storage
  void licenseStorageExamples() {
    print('\n\n===== LICENSE STORAGE EXAMPLES =====');

    // In-memory storage example
    print('\n1. Using in-memory storage:');
    final storage = InMemoryLicenseStorage();
    final repository = LicenseRepository(storage: storage);

    // Save license
    print('Saving license...');
    repository.saveLicense(rsaLicense);

    // Check if license exists
    storage.hasLicense().then((exists) {
      print('License exists in storage: $exists');
    });

    // Retrieve license
    print('Retrieving license...');
    repository.getCurrentLicense().then((license) {
      if (license != null) {
        print('✅ License retrieved successfully');
        print('License ID: ${license.id}');
      } else {
        print('❌ Failed to retrieve license');
      }
    });

    // Custom storage example
    print('\n2. Implementing custom storage:');
    print('''
// Implement ILicenseStorage to create your own storage mechanism
class FileSystemLicenseStorage implements ILicenseStorage {
  final String filePath;
  
  FileSystemLicenseStorage(this.filePath);
  
  @override
  Future<bool> deleteLicenseData() async {
    // Implementation to delete file
    return true;
  }
  
  @override
  Future<bool> hasLicense() async {
    // Implementation to check if file exists
    return true;
  }
  
  @override
  Future<Uint8List?> loadLicenseData() async {
    // Implementation to read file
    return null;
  }
  
  @override
  Future<bool> saveLicenseData(Uint8List data) async {
    // Implementation to write to file
    return true;
  }
}
''');
  }

  /// Examples comparing performance between RSA and ECDSA
  void performanceComparisonExamples() {
    print('\n\n===== PERFORMANCE COMPARISON EXAMPLES =====');

    // Compare license generation performance
    print('\n1. License generation performance:');
    final rsaGenerator = LicenseGenerateUseCase(
      privateKey: rsaKeyPair.privateKey,
    );
    final ecdsaGenerator = LicenseGenerateUseCase(
      privateKey: ecdsaKeyPair.privateKey,
    );

    // RSA license generation time
    final rsaStartTime = DateTime.now();
    for (var i = 0; i < 10; i++) {
      rsaGenerator.generateLicense(
        appId: 'com.example.app',
        expirationDate: DateTime.now().add(Duration(days: 365)),
        type: LicenseType.standard,
      );
    }
    final rsaDuration = DateTime.now().difference(rsaStartTime);
    print('RSA license generation (10x): ${rsaDuration.inMilliseconds}ms');

    // ECDSA license generation time
    final ecdsaStartTime = DateTime.now();
    for (var i = 0; i < 10; i++) {
      ecdsaGenerator.generateLicense(
        appId: 'com.example.app',
        expirationDate: DateTime.now().add(Duration(days: 365)),
        type: LicenseType.standard,
      );
    }
    final ecdsaDuration = DateTime.now().difference(ecdsaStartTime);
    print('ECDSA license generation (10x): ${ecdsaDuration.inMilliseconds}ms');

    // Calculate performance difference
    final generationSpeedup =
        rsaDuration.inMilliseconds / ecdsaDuration.inMilliseconds;
    print(
      'ECDSA is ${generationSpeedup.toStringAsFixed(1)}x faster for generation',
    );

    // Compare validation performance
    print('\n2. License validation performance:');
    final rsaValidator = LicenseValidator(publicKey: rsaKeyPair.publicKey);
    final ecdsaValidator = LicenseValidator(publicKey: ecdsaKeyPair.publicKey);

    // RSA validation time
    final rsaValidationStart = DateTime.now();
    for (var i = 0; i < 100; i++) {
      rsaValidator.validateLicense(rsaLicense);
    }
    final rsaValidationDuration = DateTime.now().difference(rsaValidationStart);
    print(
      'RSA license validation (100x): ${rsaValidationDuration.inMilliseconds}ms',
    );

    // ECDSA validation time
    final ecdsaValidationStart = DateTime.now();
    for (var i = 0; i < 100; i++) {
      ecdsaValidator.validateLicense(ecdsaLicense);
    }
    final ecdsaValidationDuration = DateTime.now().difference(
      ecdsaValidationStart,
    );
    print(
      'ECDSA license validation (100x): ${ecdsaValidationDuration.inMilliseconds}ms',
    );

    // Calculate performance difference
    final validationSpeedup =
        rsaValidationDuration.inMilliseconds /
        ecdsaValidationDuration.inMilliseconds;
    print(
      'ECDSA is ${validationSpeedup.toStringAsFixed(1)}x faster for validation',
    );

    // Compare signature sizes
    print('\n3. Signature size comparison:');
    print('RSA signature size: ${rsaLicense.signature.length} bytes');
    print('ECDSA signature size: ${ecdsaLicense.signature.length} bytes');
    print(
      'ECDSA signatures are ${((rsaLicense.signature.length - ecdsaLicense.signature.length) / rsaLicense.signature.length * 100).toStringAsFixed(1)}% smaller',
    );
  }

  /// Helper method to compare RSA and ECDSA crypto systems
  void _compareCryptoSystems(
    LicensifyKeyPair rsaKeyPair,
    LicensifyKeyPair ecdsaKeyPair,
    Duration rsaGenerationTime,
    Duration ecdsaGenerationTime,
  ) {
    print('\n3. Comparing RSA vs ECDSA:');

    // Key size comparison
    final rsaPrivateKeySize = rsaKeyPair.privateKey.content.length;
    final rsaPublicKeySize = rsaKeyPair.publicKey.content.length;
    final ecdsaPrivateKeySize = ecdsaKeyPair.privateKey.content.length;
    final ecdsaPublicKeySize = ecdsaKeyPair.publicKey.content.length;

    print('RSA private key: $rsaPrivateKeySize bytes');
    print('RSA public key: $rsaPublicKeySize bytes');
    print(
      'ECDSA private key: $ecdsaPrivateKeySize bytes (${(100 - ecdsaPrivateKeySize * 100 / rsaPrivateKeySize).toStringAsFixed(0)}% smaller)',
    );
    print(
      'ECDSA public key: $ecdsaPublicKeySize bytes (${(100 - ecdsaPublicKeySize * 100 / rsaPublicKeySize).toStringAsFixed(0)}% smaller)',
    );

    // Generation time comparison
    print('RSA generation time: ${rsaGenerationTime.inMilliseconds}ms');
    print('ECDSA generation time: ${ecdsaGenerationTime.inMilliseconds}ms');
    print(
      'ECDSA is ${(rsaGenerationTime.inMilliseconds / ecdsaGenerationTime.inMilliseconds).toStringAsFixed(1)}x faster',
    );

    // Security level comparison
    print('\nSecurity level comparison:');
    print('RSA-2048: ~112-bit security level');
    print('ECDSA P-256: ~128-bit security level');
    print('ECDSA is more secure with smaller keys!');
  }

  /// Helper method to print license details
  void _printLicenseDetails(License license, String type) {
    print('$type License details:');
    print('- ID: ${license.id}');
    print('- App ID: ${license.appId}');
    print('- Type: ${license.type.name}');
    print('- Created: ${license.createdAt}');
    print(
      '- Expires: ${license.expirationDate} (${license.remainingDays} days remaining)',
    );

    // Безопасный вывод features с проверкой
    try {
      final featuresJson = jsonEncode(license.features);
      print('- Features: $featuresJson');
    } catch (e) {
      print('- Features: ${license.features} (not encodable to JSON)');
    }

    // Безопасный вывод metadata с проверкой
    if (license.metadata != null) {
      try {
        final metadataJson = jsonEncode(license.metadata);
        print('- Metadata: $metadataJson');
      } catch (e) {
        print('- Metadata: ${license.metadata} (not encodable to JSON)');
      }
    } else {
      print('- Metadata: none');
    }

    print(
      '- Signature (${license.signature.length} bytes): ${license.signature}',
    );
  }
}
