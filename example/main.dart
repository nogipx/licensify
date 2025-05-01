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
  late final LicensifyKeyPair ecdsaKeyPair;

  // Store licenses for reuse across examples
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

    // 6. Low-level cryptographic use cases
    lowLevelCryptoExamples();

    // 7. Import ECDSA keys from parameters
    importEcdsaKeysFromParameters();
  }

  /// Examples of generating cryptographic keys
  void keyGenerationExamples() {
    print('\n===== KEY GENERATION EXAMPLES =====');

    // Generate ECDSA keys (modern, more efficient approach)
    print('\n1. Generating ECDSA keys:');
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
  }

  /// Examples of creating licenses
  void licenseCreationExamples() {
    print('\n\n===== LICENSE CREATION EXAMPLES =====');

    // Create ECDSA license
    print('\n1. Creating license with ECDSA:');
    final ecdsaGenerator = LicenseGenerator(
      privateKey: ecdsaKeyPair.privateKey,
      // Optionally specify hash algorithm (defaults to SHA-512)
      digest: SHA512Digest(),
    );

    ecdsaLicense = ecdsaGenerator(
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
    print('\n2. Creating license with custom type:');
    final customLicense = ecdsaGenerator(
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

    // Validate ECDSA license
    print('\n1. Validating ECDSA license:');
    final ecdsaValidator = LicenseValidator(
      publicKey: ecdsaKeyPair.publicKey,
      digest: SHA512Digest(), // Must match the digest used for signing
    );

    final ecdsaValidationResult = ecdsaValidator(ecdsaLicense);
    if (ecdsaValidationResult.isValid) {
      print('✅ ECDSA license is valid');
    } else {
      print('❌ ECDSA license is invalid: ${ecdsaValidationResult.message}');
    }

    // Comprehensive license validation
    print('\n3. Comprehensive license validation:');

    // First check the license expiration separately
    final license = ecdsaLicense; // Using our sample license

    if (license.isExpired) {
      print(
        '❌ License has expired - expiration date: ${license.expirationDate}',
      );
    } else {
      print(
        '✅ License is not expired - valid until: ${license.expirationDate}',
      );
      print('   Days remaining: ${license.remainingDays}');
    }

    // Then check the signature
    final signatureResult = ecdsaValidator.validateSignature(license);
    if (signatureResult.isValid) {
      print('✅ Signature is valid');
    } else {
      print('❌ Invalid signature: ${signatureResult.message}');
    }

    // Combined validation
    final validationResult = ecdsaValidator(license);
    if (validationResult.isValid) {
      print('✅ License is completely valid (signature and expiration)');
    } else {
      print('❌ License validation failed: ${validationResult.message}');
    }

    // Demonstrate tampered license validation
    print('\n4. Validating tampered license:');
    final tamperedLicense = License(
      id: ecdsaLicense.id,
      appId: ecdsaLicense.appId,
      expirationDate: ecdsaLicense.expirationDate.add(
        Duration(days: 365),
      ), // Tampered expiration
      createdAt: ecdsaLicense.createdAt,
      signature:
          ecdsaLicense.signature, // Signature doesn't match the modified data
      type: ecdsaLicense.type,
      features: ecdsaLicense.features,
      metadata: ecdsaLicense.metadata,
    );

    final tamperedResult = ecdsaValidator(tamperedLicense);
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
    final ecdsaValidator = LicenseValidator(publicKey: ecdsaKeyPair.publicKey);

    final schemaResult = ecdsaValidator.validateSchema(ecdsaLicense, schema);
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
    final completeResult = ecdsaValidator(ecdsaLicense, schema: schema);
    print('License valid: $completeResult');

    // Create invalid license to demonstrate schema validation failure
    print('\n4. Validating license with invalid schema:');
    final invalidLicense = LicenseGenerator(
      privateKey: ecdsaKeyPair.privateKey,
    )(
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

    final invalidSchemaResult = ecdsaValidator.validateSchema(
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
    repository.saveLicense(ecdsaLicense);

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

  /// Examples of low-level cryptographic use cases
  void lowLevelCryptoExamples() {
    print('\n\n===== LOW-LEVEL CRYPTOGRAPHIC USE CASES =====');

    // Create instances of the use cases
    final signDataUseCase = SignDataUseCase();
    final verifySignatureUseCase = VerifySignatureUseCase();
    final encryptDataUseCase = EncryptDataUseCase(
      publicKey: ecdsaKeyPair.publicKey,
      aesKeySize: 256,
      hkdfSalt: 'example-salt',
      hkdfInfo: 'example-info',
    );
    final decryptDataUseCase = DecryptDataUseCase(
      privateKey: ecdsaKeyPair.privateKey,
      aesKeySize: 256,
      hkdfSalt: 'example-salt',
      hkdfInfo: 'example-info',
    );

    // Example 1: Signing and verifying data
    print('\n1. Signing and verifying data:');
    final dataToSign = 'This is a sensitive message that needs to be signed';

    print('Original data: $dataToSign');

    final signature = signDataUseCase(
      data: dataToSign,
      privateKey: ecdsaKeyPair.privateKey,
    );

    print('Signature (Base64): $signature');

    final isValid = verifySignatureUseCase(
      data: dataToSign,
      signature: signature,
      publicKey: ecdsaKeyPair.publicKey,
    );

    print(
      'Signature verification result: ${isValid ? '✅ Valid' : '❌ Invalid'}',
    );

    // Example with tampered data
    final tamperedData = '$dataToSign (tampered)';
    final tamperedResult = verifySignatureUseCase(
      data: tamperedData,
      signature: signature,
      publicKey: ecdsaKeyPair.publicKey,
    );

    print(
      'Tampered data verification result: ${tamperedResult ? '❌ SECURITY ISSUE!' : '✅ Correctly detected as invalid'}',
    );

    // Example 2: Encrypting and decrypting string data
    print('\n2. Encrypting and decrypting string data:');
    final dataToEncrypt = 'Confidential information that needs to be encrypted';

    print('Original text: $dataToEncrypt');

    final encryptedData = encryptDataUseCase.encryptString(
      data: dataToEncrypt,
      magicHeader: 'TEXT',
    );

    print('Encrypted data size: ${encryptedData.length} bytes');

    final decryptedText = decryptDataUseCase.decryptToString(
      encryptedData: encryptedData,
      expectedMagicHeader: 'TEXT',
    );

    print('Decrypted text: $decryptedText');
    print(
      'Decryption successful: ${decryptedText == dataToEncrypt ? '✅ Yes' : '❌ No'}',
    );

    // Example 3: Advanced use case - Signed JSON message
    print('\n3. Advanced use case - Signed JSON message:');
    final message = {
      'action': 'purchase',
      'productId': 'pro_license',
      'amount': 99.99,
      'currency': 'USD',
      'timestamp': DateTime.now().toIso8601String(),
    };

    final jsonData = jsonEncode(message);
    print('Original message: $jsonData');

    // Sign the message
    final messageSignature = signDataUseCase(
      data: jsonData,
      privateKey: ecdsaKeyPair.privateKey,
    );

    // Create the complete signed message
    final signedMessage = {'data': message, 'signature': messageSignature};

    print(
      'Signed message created (with ${messageSignature.length} bytes signature)',
    );

    // Later, verify the signature
    final receivedMessage = signedMessage['data'] as Map<String, dynamic>;
    final receivedSignature = signedMessage['signature'] as String;
    final receivedJsonData = jsonEncode(receivedMessage);

    final isValidMessage = verifySignatureUseCase(
      data: receivedJsonData,
      signature: receivedSignature,
      publicKey: ecdsaKeyPair.publicKey,
    );

    print(
      'Message signature verification: ${isValidMessage ? '✅ Valid' : '❌ Invalid'}',
    );
  }

  /// Пример импорта ECDSA ключей из параметров (координат и скаляра)
  void importEcdsaKeysFromParameters() {
    print('\n\n===== IMPORT ECDSA KEYS FROM PARAMETERS =====\n');

    // Параметры ключей (обычно получаемые из внешних источников)
    final privateScalar =
        'd1b71758e219652b8c4ff3edd77a337d536c65a4278c93a41887d132b1cb8673';
    final curveName =
        'prime256v1'; // также можно использовать 'secp256r1' или 'p-256'

    // Создание пары ключей из приватного скаляра
    // Публичный ключ автоматически вычисляется из приватного
    final keyPair = LicensifyKeyImporter.importEcdsaKeyPairFromPrivateScalar(
      d: privateScalar,
      curveName: curveName,
    );
    print('Импортирована пара ECDSA ключей: ${keyPair.keyType}');

    // Теперь получаем координаты публичного ключа
    final coordinates = EcdsaParamsConverter.derivePublicKeyCoordinates(
      d: privateScalar,
      curveName: curveName,
    );
    print('Вычисленные координаты публичного ключа:');
    print('x: ${coordinates['x']}');
    print('y: ${coordinates['y']}');

    // Импорт публичного ключа из координат x, y и названия кривой
    final publicKey = LicensifyKeyImporter.importEcdsaPublicKeyFromCoordinates(
      x: coordinates['x']!,
      y: coordinates['y']!,
      curveName: curveName,
    );
    print('Импортирован публичный ECDSA ключ: ${publicKey.keyType}');

    // Импорт приватного ключа из скаляра d и названия кривой
    final privateKey = LicensifyKeyImporter.importEcdsaPrivateKeyFromScalar(
      d: privateScalar,
      curveName: curveName,
    );
    print('Импортирован приватный ECDSA ключ: ${privateKey.keyType}');

    // Пример подписи данных с импортированным ключом
    final data = 'Test data for signing';
    final signDataUseCase = SignDataUseCase();
    final verifySignatureUseCase = VerifySignatureUseCase();

    // Подписываем данные приватным ключом
    final signature = signDataUseCase(data: data, privateKey: privateKey);
    print('Создана подпись: ${signature.substring(0, 20)}...');

    // Проверяем подпись публичным ключом
    final isValid = verifySignatureUseCase(
      data: data,
      signature: signature,
      publicKey: publicKey,
    );
    print('Проверка подписи: ${isValid ? "верна" : "неверна"}');

    // Для проверки используем пару, созданную вместе
    print('\nПроверка подписи с ключами из одной пары:');

    final pairSignature = signDataUseCase(
      data: data,
      privateKey: keyPair.privateKey,
    );

    final pairIsValid = verifySignatureUseCase(
      data: data,
      signature: pairSignature,
      publicKey: keyPair.publicKey,
    );

    print('Проверка подписи: ${pairIsValid ? "верна" : "неверна"}');

    // Пример использования разных кривых
    final supportedCurves = [
      'prime256v1', // также известна как 'secp256r1' или 'P-256'
      'secp256k1', // популярная в блокчейне
      'secp384r1', // также известна как 'P-384'
      'secp521r1', // также известна как 'P-521'
    ];

    print('\nПоддерживаемые кривые:');
    for (final curve in supportedCurves) {
      print('- $curve');
    }
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
