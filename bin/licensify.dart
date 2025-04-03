#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';
import 'package:licensify/licensify.dart';
import 'package:args/args.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main(List<String> arguments) async {
  final parser = ArgParser();

  // Common options
  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'Show help information',
    negatable: false,
  );
  parser.addFlag(
    'version',
    abbr: 'v',
    help: 'Show version information',
    negatable: false,
  );

  // Commands
  parser.addCommand('generate')
    ..addOption('output', abbr: 'o', help: 'Output file path')
    ..addOption('privateKey', abbr: 'k', help: 'Private key file path')
    ..addOption('appId', help: 'Application ID for this license')
    ..addOption(
      'id',
      help: 'License ID (UUID). Will be generated if not provided',
    )
    ..addOption('expiration', help: 'License expiration date (YYYY-MM-DD)')
    ..addOption(
      'type',
      help: 'License type (trial, standard, pro)',
      defaultsTo: 'standard',
    )
    ..addMultiOption(
      'features',
      abbr: 'f',
      help: 'License features in format key=value',
    )
    ..addMultiOption(
      'metadata',
      abbr: 'm',
      help: 'License metadata in format key=value',
    )
    ..addFlag('encrypt', help: 'Encrypt the license file', defaultsTo: false)
    ..addOption('encryptKey', help: 'Key for encryption');

  parser.addCommand('verify')
    ..addOption(
      'license',
      abbr: 'l',
      help: 'License file path',
      mandatory: true,
    )
    ..addOption(
      'publicKey',
      abbr: 'k',
      help: 'Public key file path',
      mandatory: true,
    )
    ..addOption('decryptKey', help: 'Key for decryption');

  parser.addCommand('keygen')
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output directory path',
      defaultsTo: './keys',
    )
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Base name for key files',
      defaultsTo: 'ecdsa',
    )
    ..addOption(
      'curve',
      help: 'ECDSA curve to use (p256, p384, p521)',
      defaultsTo: 'p256',
    );

  // Add license request commands
  parser.addCommand('request')
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output file path for the license request',
      defaultsTo: 'license_request.bin',
    )
    ..addOption(
      'appId',
      help: 'Application ID for this license request',
      mandatory: true,
    )
    ..addOption(
      'deviceId',
      help: 'Device identifier (optional, will be hashed)',
    )
    ..addOption(
      'publicKey',
      abbr: 'k',
      help: 'Path to the public key file (from license issuer)',
      mandatory: true,
    )
    ..addOption(
      'validHours',
      help: 'Request validity period in hours',
      defaultsTo: '48',
    );

  parser.addCommand('decrypt-request')
    ..addOption(
      'requestFile',
      abbr: 'r',
      help: 'Path to the license request file',
      mandatory: true,
    )
    ..addOption(
      'privateKey',
      abbr: 'k',
      help: 'Private key file path',
      mandatory: true,
    );

  parser.addCommand('respond')
    ..addOption(
      'requestFile',
      abbr: 'r',
      help: 'Path to the license request file',
      mandatory: true,
    )
    ..addOption(
      'privateKey',
      abbr: 'k',
      help: 'Private key file path',
      mandatory: true,
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output license file path',
      defaultsTo: 'license.licensify',
    )
    ..addOption(
      'expiration',
      help: 'License expiration date (YYYY-MM-DD)',
      mandatory: true,
    )
    ..addOption(
      'type',
      help: 'License type (trial, standard, pro)',
      defaultsTo: 'standard',
    )
    ..addMultiOption(
      'features',
      abbr: 'f',
      help: 'License features in format key=value',
    )
    ..addMultiOption(
      'metadata',
      abbr: 'm',
      help: 'License metadata in format key=value',
    )
    ..addFlag('encrypt', help: 'Encrypt the license file', defaultsTo: false)
    ..addOption('encryptKey', help: 'Key for encryption');

  try {
    final results = parser.parse(arguments);

    if (results['help'] == true) {
      printUsage(parser);
      exit(0);
    }

    if (results['version'] == true) {
      print('Licensify CLI v1.0.0');
      exit(0);
    }

    final command = results.command;
    if (command == null) {
      printUsage(parser);
      exit(1);
    }

    switch (command.name) {
      case 'generate':
        await generateLicense(command);
        break;
      case 'verify':
        await verifyLicense(command);
        break;
      case 'keygen':
        await generateKeyPair(command);
        break;
      case 'request':
        await createLicenseRequest(command);
        break;
      case 'decrypt-request':
        await decryptLicenseRequest(command);
        break;
      case 'respond':
        await respondToLicenseRequest(command);
        break;
      default:
        printUsage(parser);
        exit(1);
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    printUsage(parser);
    exit(1);
  }
}

void printUsage(ArgParser parser) {
  print('Usage: licensify <command> [options]');
  print(parser.usage);

  print('\nCommands:');
  print('  generate        Generate a new license file');
  print('  verify          Verify an existing license file');
  print('  keygen          Generate a new ECDSA key pair');
  print('  request         Create a license request (client-side)');
  print('  decrypt-request Decrypt a license request (server-side)');
  print(
    '  respond         Process a license request and generate a license (server-side)',
  );

  print('\nExamples:');
  print('  licensify keygen --output ./keys --name customer1');
  print(
    '  licensify generate --privateKey ./keys/customer1.private.pem --appId com.example.app --expiration 2025-01-01 --output license.licensify',
  );
  print(
    '  licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem',
  );
  print(
    '  licensify request --appId com.example.app --publicKey ./keys/customer1.public.pem --output request.bin',
  );
  print(
    '  licensify decrypt-request --requestFile request.bin --privateKey ./keys/customer1.private.pem',
  );
  print(
    '  licensify respond --requestFile request.bin --privateKey ./keys/customer1.private.pem --expiration 2025-01-01',
  );
}

Future<void> generateLicense(ArgResults args) async {
  final outputPath = args['output'] as String? ?? 'license.licensify';
  final privateKeyPath = args['privateKey'] as String?;
  final appId = args['appId'] as String?;
  final expirationStr = args['expiration'] as String?;
  final licenseType = args['type'] as String? ?? 'standard';
  final featuresList = args['features'] as List<String>? ?? [];
  final metadataList = args['metadata'] as List<String>? ?? [];
  final shouldEncrypt = args['encrypt'] as bool;
  final encryptKey = args['encryptKey'] as String?;

  if (privateKeyPath == null) {
    stderr.writeln('Error: --privateKey is required');
    exit(1);
  }

  if (appId == null) {
    stderr.writeln('Error: --appId is required');
    exit(1);
  }

  if (expirationStr == null) {
    stderr.writeln('Error: --expiration is required (format: YYYY-MM-DD)');
    exit(1);
  }

  try {
    final expirationDate = DateTime.parse(expirationStr);

    final privateKeyFile = File(privateKeyPath);
    final privateKeyPem = await privateKeyFile.readAsString();
    final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPem);

    final features = _parseKeyValues(featuresList);
    final metadata = _parseKeyValues(metadataList);

    LicenseType type;
    switch (licenseType.toLowerCase()) {
      case 'trial':
        type = LicenseType.trial;
        break;
      case 'pro':
        type = LicenseType.pro;
        break;
      case 'standard':
      default:
        type = LicenseType.standard;
        break;
    }

    final licenseGenerator = LicenseGenerator(privateKey: privateKey);
    final license = licenseGenerator(
      appId: appId,
      expirationDate: expirationDate,
      type: type,
      features: features,
      metadata: metadata,
    );

    final licenseBytes = LicenseEncoder.encode(license);

    if (shouldEncrypt && encryptKey != null) {
      stderr.writeln('Warning: Encryption is not implemented in this version');
    }

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(licenseBytes);

    print('License generated successfully: $outputPath');
  } catch (e) {
    stderr.writeln('Error generating license: $e');
    exit(1);
  }
}

Future<void> verifyLicense(ArgResults args) async {
  final licensePath = args['license'] as String;
  final publicKeyPath = args['publicKey'] as String;
  final decryptKey = args['decryptKey'] as String?;

  try {
    // Reading public key from file
    final publicKeyFile = File(publicKeyPath);
    final publicKeyPem = await publicKeyFile.readAsString();
    final publicKey = LicensifyPublicKey.ecdsa(publicKeyPem);

    // Reading license from file
    final licenseFile = File(licensePath);
    final licenseBytes = await licenseFile.readAsBytes();

    // Optional: license decryption
    Uint8List decodedBytes = Uint8List.fromList(licenseBytes);
    if (decryptKey != null) {
      // Code for license decryption would go here
      stderr.writeln('Warning: Decryption is not implemented in this version');
    }

    // License decoding
    final license = LicenseEncoder.decode(decodedBytes);

    // Signature verification
    final validator = LicenseValidator(publicKey: publicKey);
    final validationResult = validator(license);

    if (validationResult.isValid) {
      print('License is valid!');

      // Expiration check
      if (license.isExpired) {
        print('Warning: License has expired on ${license.expirationDate}');
      } else {
        print('License is valid until ${license.expirationDate}');
        print('Remaining days: ${license.remainingDays}');
      }

      // License information output
      print('\nLicense details:');
      print('  ID: ${license.id}');
      print('  App ID: ${license.appId}');
      print('  Type: ${license.type}');
      print('  Created: ${license.createdAt}');

      if (license.features.isNotEmpty) {
        print('\nFeatures:');
        license.features.forEach((key, value) {
          print('  $key: $value');
        });
      }

      if (license.metadata != null && license.metadata!.isNotEmpty) {
        print('\nMetadata:');
        license.metadata!.forEach((key, value) {
          print('  $key: $value');
        });
      }
    } else {
      print('License verification failed: ${validationResult.message}');
      exit(1);
    }
  } catch (e) {
    stderr.writeln('Error verifying license: $e');
    exit(1);
  }
}

Future<void> generateKeyPair(ArgResults args) async {
  final outputDir = args['output'] as String;
  final baseName = args['name'] as String;
  final curveStr = args['curve'] as String? ?? 'p256';

  EcCurve curve;
  switch (curveStr.toLowerCase()) {
    case 'p384':
      curve = EcCurve.p384;
      break;
    case 'p521':
      curve = EcCurve.p521;
      break;
    case 'p256':
    default:
      curve = EcCurve.p256;
      break;
  }

  try {
    final directory = Directory(outputDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: curve);

    final privateKeyFile = File('$outputDir/$baseName.private.pem');
    await privateKeyFile.writeAsString(keyPair.privateKey.content);

    final publicKeyFile = File('$outputDir/$baseName.public.pem');
    await publicKeyFile.writeAsString(keyPair.publicKey.content);

    print('ECDSA key pair generated:');
    print('  Private key: ${privateKeyFile.path}');
    print('  Public key: ${publicKeyFile.path}');
  } catch (e) {
    stderr.writeln('Error generating key pair: $e');
    exit(1);
  }
}

/// Generates device hash from device ID or creates a random one
String generateDeviceHash(String? deviceId) {
  if (deviceId == null || deviceId.isEmpty) {
    // Generate a random device hash if none provided
    final random = const Uuid().v4();
    final bytes = utf8.encode(random);
    final hash = sha256.convert(bytes);
    return hash.toString();
  } else {
    // Hash the provided device ID
    final bytes = utf8.encode(deviceId);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

Future<void> createLicenseRequest(ArgResults args) async {
  final outputPath = args['output'] as String;
  final appId = args['appId'] as String;
  final deviceId = args['deviceId'] as String?;
  final publicKeyPath = args['publicKey'] as String;
  final validHoursStr = args['validHours'] as String;

  try {
    // Read the public key
    final publicKeyFile = File(publicKeyPath);
    final publicKeyPem = await publicKeyFile.readAsString();
    final publicKey = LicensifyPublicKey.ecdsa(publicKeyPem);

    // Generate device hash
    final deviceHash = generateDeviceHash(deviceId);

    // Parse validity hours
    final validHours = int.parse(validHoursStr);

    // Create license request generator
    final requestGenerator = publicKey.licenseRequestGenerator();

    // Generate license request
    final requestBytes = requestGenerator(
      deviceHash: deviceHash,
      appId: appId,
      expirationHours: validHours,
    );

    // Save to file
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(requestBytes);

    print('License request created successfully: $outputPath');
    print('\nRequest details:');
    print('  App ID: $appId');
    print(
      '  Device hash: $deviceHash (${deviceId != null ? 'from provided device ID' : 'randomly generated'})',
    );
    print('  Valid for: $validHours hours');
  } catch (e) {
    stderr.writeln('Error creating license request: $e');
    exit(1);
  }
}

Future<void> decryptLicenseRequest(ArgResults args) async {
  final requestPath = args['requestFile'] as String;
  final privateKeyPath = args['privateKey'] as String;

  try {
    // Read the license request
    final requestFile = File(requestPath);
    final requestBytes = await requestFile.readAsBytes();

    // Read the private key
    final privateKeyFile = File(privateKeyPath);
    final privateKeyPem = await privateKeyFile.readAsString();
    final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPem);

    // Create license request decrypter
    final requestDecrypter = LicenseRequestDecrypter(privateKey: privateKey);

    // Decrypt the request
    final request = requestDecrypter(requestBytes);

    // Print request information
    print('License request successfully decrypted:');
    print('\nRequest details:');
    print('  App ID: ${request.appId}');
    print('  Device hash: ${request.deviceHash}');
    print('  Created: ${request.createdAt}');
    print('  Expires: ${request.expiresAt}');

    if (request.isExpired) {
      print('\nWARNING: This request has already expired!');
    }
  } catch (e) {
    stderr.writeln('Error decrypting license request: $e');
    exit(1);
  }
}

Future<void> respondToLicenseRequest(ArgResults args) async {
  final requestPath = args['requestFile'] as String;
  final privateKeyPath = args['privateKey'] as String;
  final outputPath = args['output'] as String;
  final expirationStr = args['expiration'] as String;
  final licenseType = args['type'] as String? ?? 'standard';
  final featuresList = args['features'] as List<String>? ?? [];
  final metadataList = args['metadata'] as List<String>? ?? [];
  final shouldEncrypt = args['encrypt'] as bool;
  final encryptKey = args['encryptKey'] as String?;

  try {
    // Read the license request
    final requestFile = File(requestPath);
    final requestBytes = await requestFile.readAsBytes();

    // Read the private key
    final privateKeyFile = File(privateKeyPath);
    final privateKeyPem = await privateKeyFile.readAsString();
    final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPem);

    // Create license request decrypter
    final requestDecrypter = LicenseRequestDecrypter(privateKey: privateKey);

    // Decrypt the request
    final request = requestDecrypter(requestBytes);

    // Check if request is expired
    if (request.isExpired) {
      print('WARNING: The license request has expired. Continuing anyway...');
    }

    // Parse expiration date
    final expirationDate = DateTime.parse(expirationStr);

    // Parse features and metadata
    final features = _parseKeyValues(featuresList);
    final additionalMetadata = _parseKeyValues(metadataList);

    // Add device hash to metadata
    final metadata = {'deviceHash': request.deviceHash, ...additionalMetadata};

    // Determine license type
    LicenseType type;
    switch (licenseType.toLowerCase()) {
      case 'trial':
        type = LicenseType.trial;
        break;
      case 'pro':
        type = LicenseType.pro;
        break;
      case 'standard':
      default:
        type = LicenseType.standard;
        break;
    }

    // Create license generator
    final licenseGenerator = LicenseGenerator(privateKey: privateKey);

    // Generate license from request
    final license = licenseGenerator(
      appId: request.appId,
      expirationDate: expirationDate,
      type: type,
      features: features,
      metadata: metadata,
    );

    // Encode license
    final licenseBytes = LicenseEncoder.encode(license);

    // Optional encryption
    if (shouldEncrypt && encryptKey != null) {
      stderr.writeln('Warning: Encryption is not implemented in this version');
    }

    // Save license to file
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(licenseBytes);

    print('License generated from request: $outputPath');
    print('\nLicense details:');
    print('  ID: ${license.id}');
    print('  App ID: ${license.appId}');
    print('  Type: ${license.type}');
    print('  Expiration: ${license.expirationDate}');
    print('  Device hash: ${metadata['deviceHash']}');

    if (features.isNotEmpty) {
      print('\nFeatures:');
      features.forEach((key, value) {
        print('  $key: $value');
      });
    }

    if (additionalMetadata.isNotEmpty) {
      print('\nMetadata:');
      additionalMetadata.forEach((key, value) {
        print('  $key: $value');
      });
    }
  } catch (e) {
    stderr.writeln('Error processing license request: $e');
    exit(1);
  }
}

/// Parses a list of strings in key=value format into a Map
Map<String, dynamic> _parseKeyValues(List<String> items) {
  final result = <String, dynamic>{};
  for (final item in items) {
    final parts = item.split('=');
    if (parts.length != 2) {
      stderr.writeln('Warning: Invalid format for "$item". Expected key=value');
      continue;
    }
    result[parts[0]] = parts[1];
  }
  return result;
}
