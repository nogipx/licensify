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
    ..addOption('decryptKey', help: 'Key for decryption')
    ..addOption(
      'output-json',
      abbr: 'o',
      help: 'Save output to JSON file at specified path',
    );

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
    )
    ..addOption(
      'output-json',
      abbr: 'o',
      help: 'Save output to JSON file at specified path',
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
      if (results.command != null) {
        // Справка по конкретной команде
        printCommandHelp(results.command!.name!, parser);
      } else {
        // Общая справка
        printUsage(parser);
      }
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

    // Проверяем, запрошена ли справка для конкретной команды
    if (command['help'] == true) {
      printCommandHelp(command.name!, parser);
      exit(0);
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
  print('Licensify CLI - License Management Tool v1.0.0');
  print('=====================================================');
  print('\nKey and license management for the Licensify library.');
  print('\nBasic usage:');
  print('  licensify <command> [options]');
  print(parser.usage);

  print('\nAvailable commands:');
  print('  keygen          Generate a new ECDSA key pair (private and public)');
  print('  generate        Create and sign a new license');
  print('  verify          Verify an existing license');
  print('  request         Create a license request (client-side)');
  print('  decrypt-request Decrypt and view a license request (server-side)');
  print(
    '  respond         Process a license request and generate a license (server-side)',
  );

  print('\nTo get help for a specific command:');
  print('  licensify <command> --help');

  print('\nUsage examples:');

  print('\n1. Generating keys:');
  print('  licensify keygen --output ./keys --name customer1');
  print(
    '  Creates a key pair: customer1.private.pem and customer1.public.pem in the ./keys directory',
  );

  print('\n2. Creating a license (direct method):');
  print('  licensify generate --privateKey ./keys/customer1.private.pem \\');
  print('                    --appId com.example.app \\');
  print('                    --expiration 2025-01-01 \\');
  print(
    '                    --features maxUsers=10 --features premium=true \\',
  );
  print('                    --metadata customer=ACME \\');
  print('                    --output license.licensify');

  print('\n3. Verifying a license:');
  print(
    '  licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem',
  );
  print('  You can save results to JSON:');
  print(
    '  licensify verify --license license.licensify --publicKey ./keys/customer1.public.pem --output-json results.json',
  );

  print('\n4. License request workflow:');
  print('  # Client: creating a request');
  print(
    '  licensify request --appId com.example.app --publicKey ./keys/customer1.public.pem --output request.bin',
  );
  print('  # Server: decrypting the request');
  print(
    '  licensify decrypt-request --requestFile request.bin --privateKey ./keys/customer1.private.pem',
  );
  print('  # Server: creating a license based on the request');
  print(
    '  licensify respond --requestFile request.bin --privateKey ./keys/customer1.private.pem \\',
  );
  print(
    '                   --expiration 2025-01-01 --type pro --features maxUsers=100',
  );
}

void printCommandHelp(String command, ArgParser parser) {
  switch (command) {
    case 'keygen':
      print('Command: keygen - generate ECDSA key pair');
      print(
        '\nCreates a new ECDSA cryptographic key pair for creating and verifying licenses.',
      );
      print(
        'The private key is used for creating licenses, the public key - for verification.',
      );
      print('\nUsage:');
      print('  licensify keygen [options]');
      print('\nOptions:');
      print('  --output, -o      Directory to save keys (default: ./keys)');
      print('  --name, -n        Base name for key files (default: ecdsa)');
      print(
        '  --curve           ECDSA curve: p256, p384, p521 (default: p256)',
      );
      print('\nExamples:');
      print('  licensify keygen');
      print(
        '  licensify keygen --output ./customers/keys --name client1 --curve p384',
      );
      break;

    case 'generate':
      print('Command: generate - create and sign a license');
      print(
        '\nCreates a new license by signing it with a private key. The license will contain',
      );
      print(
        'the specified application ID, expiration date, type, and additional parameters.',
      );
      print('\nUsage:');
      print('  licensify generate [options]');
      print('\nRequired options:');
      print('  --privateKey, -k  Path to the private key file');
      print('  --appId           Application identifier');
      print('  --expiration      License expiration date (YYYY-MM-DD)');
      print('\nAdditional options:');
      print(
        '  --output, -o      Path to save the license file (default: license.licensify)',
      );
      print(
        '  --id              License ID (UUID). If not specified, it will be generated automatically',
      );
      print(
        '  --type            License type: trial, standard, pro (default: standard)',
      );
      print(
        '  --features, -f    License features in key=value format (can specify multiple)',
      );
      print(
        '  --metadata, -m    License metadata in key=value format (can specify multiple)',
      );
      print('\nExamples:');
      print(
        '  licensify generate --privateKey ./keys/app.private.pem --appId com.example --expiration 2025-12-31',
      );
      print(
        '  licensify generate --privateKey ./keys/app.private.pem --appId com.example --expiration 2025-12-31 \\',
      );
      print(
        '                    --type pro --features maxUsers=50 --features modules=analytics,reports \\',
      );
      print(
        '                    --metadata customer="ACME Corp" --metadata orderId=12345',
      );
      break;

    case 'verify':
      print('Command: verify - verify a license');
      print(
        '\nVerifies the signature and validity of an existing license using a public key.',
      );
      print('Displays information about the license and its status.');
      print('\nUsage:');
      print('  licensify verify [options]');
      print('\nRequired options:');
      print('  --license, -l     Path to the license file');
      print('  --publicKey, -k   Path to the public key file');
      print('\nAdditional options:');
      print(
        '  --output-json, -o Save verification results to a JSON file at the specified path',
      );
      print('\nExamples:');
      print(
        '  licensify verify --license license.licensify --publicKey ./keys/app.public.pem',
      );
      print(
        '  licensify verify --license license.licensify --publicKey ./keys/app.public.pem --output-json results.json',
      );
      break;

    case 'request':
      print('Command: request - create a license request');
      print(
        '\nCreates an encrypted license request containing information about the device',
      );
      print(
        'and application. The request is encrypted with a public key so that only the owner',
      );
      print('of the corresponding private key can decrypt it.');
      print('\nUsage:');
      print('  licensify request [options]');
      print('\nRequired options:');
      print('  --appId           Application identifier');
      print(
        '  --publicKey, -k   Path to the public key file (from the license issuer)',
      );
      print('\nAdditional options:');
      print(
        '  --output, -o      Path to save the request file (default: license_request.bin)',
      );
      print(
        '  --deviceId        Device identifier (will be hashed, random if not specified)',
      );
      print(
        '  --validHours      Request validity period in hours (default: 48)',
      );
      print('\nExamples:');
      print(
        '  licensify request --appId com.example --publicKey ./keys/app.public.pem',
      );
      print(
        '  licensify request --appId com.example --publicKey ./keys/app.public.pem \\',
      );
      print(
        '                   --deviceId "unique-device-id-123" --validHours 72',
      );
      break;

    case 'decrypt-request':
      print('Command: decrypt-request - decrypt a license request');
      print('\nDecrypts and displays the contents of a license request,');
      print(
        'using a private key. Shows information about the request and its status.',
      );
      print('\nUsage:');
      print('  licensify decrypt-request [options]');
      print('\nRequired options:');
      print('  --requestFile, -r Path to the license request file');
      print('  --privateKey, -k  Path to the private key file');
      print('\nAdditional options:');
      print(
        '  --output-json, -o Save request details to a JSON file at the specified path',
      );
      print('\nExamples:');
      print(
        '  licensify decrypt-request --requestFile request.bin --privateKey ./keys/app.private.pem',
      );
      print(
        '  licensify decrypt-request --requestFile request.bin --privateKey ./keys/app.private.pem \\',
      );
      print('                          --output-json request-info.json');
      break;

    case 'respond':
      print('Command: respond - process a request and create a license');
      print(
        '\nDecrypts a license request and creates a corresponding license,',
      );
      print(
        'bound to the device from the request. This is the primary method for creating',
      );
      print('licenses tied to specific devices.');
      print('\nUsage:');
      print('  licensify respond [options]');
      print('\nRequired options:');
      print('  --requestFile, -r Path to the license request file');
      print('  --privateKey, -k  Path to the private key file');
      print('  --expiration      License expiration date (YYYY-MM-DD)');
      print('\nAdditional options:');
      print(
        '  --output, -o      Path to save the license file (default: license.licensify)',
      );
      print(
        '  --type            License type: trial, standard, pro (default: standard)',
      );
      print(
        '  --features, -f    License features in key=value format (can specify multiple)',
      );
      print(
        '  --metadata, -m    License metadata in key=value format (can specify multiple)',
      );
      print('\nExamples:');
      print(
        '  licensify respond --requestFile request.bin --privateKey ./keys/app.private.pem --expiration 2025-12-31',
      );
      print(
        '  licensify respond --requestFile request.bin --privateKey ./keys/app.private.pem \\',
      );
      print(
        '                   --expiration 2025-12-31 --type pro --features maxUsers=100',
      );
      break;

    default:
      print('Unknown command: $command');
      printUsage(parser);
  }
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
  final outputJsonPath = args['output-json'] as String?;

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
      // Prepare JSON output data
      final outputData = {
        'validationResult': {'isValid': true, 'message': ''},
        'licenseDetails': {
          'id': license.id,
          'appId': license.appId,
          'type': license.type.name,
          'createdAt': license.createdAt.toIso8601String(),
          'expirationDate': license.expirationDate.toIso8601String(),
          'isExpired': license.isExpired,
          'remainingDays': license.remainingDays,
          'features': license.features,
          'metadata': license.metadata,
        },
      };

      // Save to JSON if output path is specified
      if (outputJsonPath != null) {
        final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
        final outputFile = File(outputJsonPath);
        await outputFile.writeAsString(jsonOutput);
        print('License validation information saved to: $outputJsonPath');
      }

      // Normal console output
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
      // Prepare JSON output data for invalid license
      final outputData = {
        'validationResult': {
          'isValid': false,
          'message': validationResult.message,
        },
      };

      // Save to JSON if output path is specified
      if (outputJsonPath != null) {
        final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
        final outputFile = File(outputJsonPath);
        await outputFile.writeAsString(jsonOutput);
        print('License validation information saved to: $outputJsonPath');
      }

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
  final outputJsonPath = args['output-json'] as String?;

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

    // Prepare JSON output data
    final outputData = {
      'requestDetails': {
        'appId': request.appId,
        'deviceHash': request.deviceHash,
        'createdAt': request.createdAt.toIso8601String(),
        'expiresAt': request.expiresAt.toIso8601String(),
        'isExpired': request.isExpired,
      },
    };

    // Save to JSON if output path is specified
    if (outputJsonPath != null) {
      final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
      final outputFile = File(outputJsonPath);
      await outputFile.writeAsString(jsonOutput);
      print('License request information saved to: $outputJsonPath');
    }

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
