// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:licensify/licensify.dart';
import 'package:paseto_dart/paseto_dart.dart';

ArgParser _parserWithHelp() => ArgParser()
  ..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show usage information.',
  );

const Map<String, String> _rootCommandDescriptions = <String, String>{
  'keypair': 'Manage Ed25519 signing key material',
  'symmetric': 'Manage XChaCha20 encryption keys',
  'salt': 'Generate Argon2id salts',
};

const Map<String, String> _keypairCommandDescriptions = <String, String>{
  'generate': 'Mint a new Ed25519 signing key pair',
  'info': 'Inspect or convert existing key material',
};

const Map<String, String> _symmetricCommandDescriptions = <String, String>{
  'generate': 'Create a new symmetric key with PASERK exports',
  'info': 'Decode or convert existing symmetric keys',
  'derive': 'Derive a key from a password and salt',
};

const Map<String, String> _saltCommandDescriptions = <String, String>{
  'generate': 'Produce base64url salts for Argon2id',
};

final ArgParser _keypairGenerateParser = _parserWithHelp()
  ..addOption(
    'password',
    help:
        'Additionally emit k4.secret-pw using the provided password (Argon2id defaults).',
  )
  ..addOption(
    'wrap',
    help: 'Additionally emit k4.secret-wrap.pie using the provided k4.local key.',
  );

final ArgParser _keypairInfoParser = _parserWithHelp()
  ..addOption(
    'paserk',
    help: 'PASERK string to inspect (k4.secret*, k4.public).',
  )
  ..addOption(
    'password',
    help: 'Password required to open k4.secret-pw inputs.',
  )
  ..addOption(
    'wrap',
    help: 'Wrapping key (k4.local) required to open k4.secret-wrap.pie inputs.',
  );

final ArgParser _keypairParser = _parserWithHelp()
  ..addCommand('generate', _keypairGenerateParser)
  ..addCommand('info', _keypairInfoParser);

final ArgParser _symmetricGenerateParser = _parserWithHelp()
  ..addOption(
    'password',
    help:
        'Additionally emit k4.local-pw using the provided password (Argon2id defaults).',
  )
  ..addOption(
    'wrap',
    help: 'Additionally emit k4.local-wrap.pie using the provided k4.local key.',
  )
  ..addOption(
    'seal-with',
    help: 'Additionally emit k4.seal using the provided k4.public key.',
  );

final ArgParser _symmetricInfoParser = _parserWithHelp()
  ..addOption(
    'paserk',
    help:
        'PASERK string to inspect (k4.local*, k4.seal). Use --keypair when unsealing.',
  )
  ..addOption(
    'password',
    help: 'Password required to open k4.local-pw inputs.',
  )
  ..addOption(
    'wrap',
    help: 'Wrapping key (k4.local) required to open k4.local-wrap.pie inputs.',
  )
  ..addOption(
    'keypair',
    help: 'PASERK key pair (k4.secret*) required to unseal k4.seal inputs.',
  )
  ..addOption(
    'keypair-password',
    help: 'Password for the key pair if --keypair is k4.secret-pw.',
  )
  ..addOption(
    'keypair-wrap',
    help:
        'Wrapping key (k4.local) for the key pair if --keypair is k4.secret-wrap.pie.',
  );

final ArgParser _symmetricDeriveParser = _parserWithHelp()
  ..addOption(
    'password',
    help: 'Password to derive the symmetric key from.',
  )
  ..addOption(
    'salt',
    help:
        'Base64url salt for Argon2id (see "licensify salt generate").',
  )
  ..addOption(
    'memory-cost',
    defaultsTo: K4LocalPw.defaultMemoryCost.toString(),
    help: 'Argon2 memory cost in bytes (must be a positive multiple of 1024).',
  )
  ..addOption(
    'time-cost',
    defaultsTo: K4LocalPw.defaultTimeCost.toString(),
    help: 'Argon2 iterations (positive integer).',
  )
  ..addOption(
    'parallelism',
    defaultsTo: K4LocalPw.defaultParallelism.toString(),
    help: 'Argon2 lanes/parallelism (positive integer).',
  )
  ..addOption(
    'seal-with',
    help: 'Additionally emit k4.seal using the provided k4.public key.',
  );

final ArgParser _symmetricParser = _parserWithHelp()
  ..addCommand('generate', _symmetricGenerateParser)
  ..addCommand('info', _symmetricInfoParser)
  ..addCommand('derive', _symmetricDeriveParser);

final ArgParser _saltGenerateParser = _parserWithHelp()
  ..addOption(
    'length',
    help:
        'Length of the generated salt in bytes (defaults to PASERK minimum).',
  );

final ArgParser _saltParser = _parserWithHelp()
  ..addCommand('generate', _saltGenerateParser);

final ArgParser _rootParser = _parserWithHelp()
  ..addFlag(
    'pretty',
    defaultsTo: true,
    help: 'Pretty-print JSON output (disable with --no-pretty).',
  )
  ..addOption(
    'input',
    abbr: 'i',
    help: 'Read primary input (PASERK, salt, etc.) from a file.',
  )
  ..addOption(
    'output',
    abbr: 'o',
    help: 'Write JSON output to a file instead of stdout.',
  )
  ..addCommand('keypair', _keypairParser)
  ..addCommand('symmetric', _symmetricParser)
  ..addCommand('salt', _saltParser);

Future<void> main(List<String> arguments) async {
  ArgResults rootResults;
  try {
    rootResults = _rootParser.parse(arguments);
  } on FormatException catch (e) {
    _printUsage([], error: e.message);
    exitCode = 64;
    return;
  }

  if (rootResults['help'] as bool) {
    _printUsage([]);
    return;
  }

  final bool pretty = rootResults['pretty'] as bool;
  final String? inputPath = _trimmedValue(rootResults['input']);
  final String? outputPath = _trimmedValue(rootResults['output']);
  final ArgResults? command = rootResults.command;
  if (command == null) {
    _printUsage([], error: 'Missing command.');
    exitCode = 64;
    return;
  }

  try {
    final _CliInput? fileInput = await _loadInput(
      inputPath,
      _commandPathFrom(command),
    );
    switch (command.name) {
      case 'keypair':
        await _handleKeypair(command, pretty, fileInput, outputPath);
        break;
      case 'symmetric':
        await _handleSymmetric(command, pretty, fileInput, outputPath);
        break;
      case 'salt':
        await _handleSalt(command, pretty, outputPath);
        break;
      default:
        throw _CliUsageException('Unknown command "${command.name}".', []);
    }
  } on _CliUsageException catch (e) {
    _printUsage(e.commandPath, error: e.message);
    exitCode = 64;
  } catch (e, stackTrace) {
    stderr.writeln('Unexpected error: $e');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

Future<void> _handleKeypair(
  ArgResults command,
  bool pretty,
  _CliInput? fileInput,
  String? outputPath,
) async {
  if (command['help'] == true) {
    _printUsage(['keypair']);
    return;
  }

  final ArgResults? subcommand = command.command;
  if (subcommand == null) {
    throw _CliUsageException('Missing keypair subcommand.', ['keypair']);
  }

  switch (subcommand.name) {
    case 'generate':
      await _handleKeypairGenerate(subcommand, pretty, outputPath);
      break;
    case 'info':
      await _handleKeypairInfo(subcommand, pretty, fileInput, outputPath);
      break;
    default:
      throw _CliUsageException(
        'Unknown keypair subcommand "${subcommand.name}".',
        ['keypair'],
      );
  }
}

Future<void> _handleSymmetric(
  ArgResults command,
  bool pretty,
  _CliInput? fileInput,
  String? outputPath,
) async {
  if (command['help'] == true) {
    _printUsage(['symmetric']);
    return;
  }

  final ArgResults? subcommand = command.command;
  if (subcommand == null) {
    throw _CliUsageException('Missing symmetric subcommand.', ['symmetric']);
  }

  switch (subcommand.name) {
    case 'generate':
      await _handleSymmetricGenerate(subcommand, pretty, outputPath);
      break;
    case 'info':
      await _handleSymmetricInfo(subcommand, pretty, fileInput, outputPath);
      break;
    case 'derive':
      await _handleSymmetricDerive(subcommand, pretty, outputPath);
      break;
    default:
      throw _CliUsageException(
        'Unknown symmetric subcommand "${subcommand.name}".',
        ['symmetric'],
      );
  }
}

Future<void> _handleSalt(
  ArgResults command,
  bool pretty,
  String? outputPath,
) async {
  if (command['help'] == true) {
    _printUsage(['salt']);
    return;
  }

  final ArgResults? subcommand = command.command;
  if (subcommand == null) {
    throw _CliUsageException('Missing salt subcommand.', ['salt']);
  }

  switch (subcommand.name) {
    case 'generate':
      await _handleSaltGenerate(subcommand, pretty, outputPath);
      break;
    default:
      throw _CliUsageException(
        'Unknown salt subcommand "${subcommand.name}".',
        ['salt'],
      );
  }
}

Future<void> _handleKeypairGenerate(
  ArgResults args,
  bool pretty,
  String? outputPath,
) async {
  if (args['help'] == true) {
    _printUsage(['keypair', 'generate']);
    return;
  }

  final String? password = _trimmedValue(args['password']);
  final String? wrapPaserk = _trimmedValue(args['wrap']);

  LicensifySymmetricKey? wrappingKey;
  if (wrapPaserk != null) {
    wrappingKey = _parseSymmetricKey(wrapPaserk, ['keypair', 'generate']);
  }

  final LicensifyKeyPair pair = await LicensifyKey.generatePublicKeyPair();

  try {
    final Map<String, Object?> output = {
      'type': 'ed25519-keypair',
      'publicKeyPaserk': pair.publicKey.toPaserk(),
      'publicKeyId': pair.publicKey.toPaserkIdentifier(),
      'paserkSecret': pair.toPaserkSecret(),
      'secretId': pair.toPaserkSecretIdentifier(),
    };

    if (password != null && password.isNotEmpty) {
      final String paserkSecretPw = await pair.toPaserkSecretPassword(
        password: password,
      );
      output['paserkSecretPw'] = paserkSecretPw;
      _applyPasswordMetadata(
        output,
        _parsePaserkPasswordMetadata(
          paserkSecretPw,
          ['keypair', 'generate'],
        ),
      );
    }

    if (wrappingKey != null) {
      output['paserkSecretWrap'] = pair.toPaserkSecretWrap(
        wrappingKey: wrappingKey,
      );
    }

    await _printJson(output, pretty: pretty, outputPath: outputPath);
  } finally {
    pair.privateKey.dispose();
    pair.publicKey.dispose();
    wrappingKey?.dispose();
  }
}

Future<void> _handleKeypairInfo(
  ArgResults args,
  bool pretty,
  _CliInput? fileInput,
  String? outputPath,
) async {
  if (args['help'] == true) {
    _printUsage(['keypair', 'info']);
    return;
  }

  final String? paserkInput = _trimmedValue(args['paserk']) ??
      _paserkFromInput(fileInput, const [
        'paserkSecret',
        'paserkSecretPw',
        'paserkSecretWrap',
        'publicKeyPaserk',
      ]);
  if (paserkInput == null || paserkInput.isEmpty) {
    throw _CliUsageException('Provide --paserk with a PASERK string.', ['keypair', 'info']);
  }

  final String paserk = paserkInput;
  final String? password = _trimmedValue(args['password']);
  final String? wrapPaserk = _trimmedValue(args['wrap']);

  if (paserk.startsWith('k4.public')) {
    final LicensifyPublicKey publicKey =
        _parsePublicKey(paserk, ['keypair', 'info']);
    try {
      final Map<String, Object?> output = {
        'type': 'ed25519-public-key',
        'sourceFormat': 'k4.public',
        'publicKeyPaserk': publicKey.toPaserk(),
        'publicKeyId': publicKey.toPaserkIdentifier(),
      };
      await _printJson(output, pretty: pretty, outputPath: outputPath);
    } finally {
      publicKey.dispose();
    }
    return;
  }

  LicensifyKeyPair? pair;
  LicensifySymmetricKey? wrappingKey;

  try {
    if (paserk.startsWith('k4.secret-pw')) {
      if (password == null || password.isEmpty) {
        throw _CliUsageException(
          'Provide --password to open k4.secret-pw inputs.',
          ['keypair', 'info'],
        );
      }
      pair = await LicensifyKeyPair.fromPaserkSecretPassword(
        paserk: paserk,
        password: password,
      );
    } else if (paserk.startsWith('k4.secret-wrap')) {
      if (wrapPaserk == null || wrapPaserk.isEmpty) {
        throw _CliUsageException(
          'Provide --wrap with the wrapping k4.local key to open k4.secret-wrap.pie inputs.',
          ['keypair', 'info'],
        );
      }
      wrappingKey = _parseSymmetricKey(wrapPaserk, ['keypair', 'info']);
      pair = LicensifyKeyPair.fromPaserkSecretWrap(
        paserk: paserk,
        wrappingKey: wrappingKey,
      );
    } else if (paserk.startsWith('k4.secret')) {
      pair = LicensifyKeyPair.fromPaserkSecret(paserk: paserk);
    } else {
      throw _CliUsageException(
        'Unsupported PASERK format for key pairs: $paserk',
        ['keypair', 'info'],
      );
    }

    final Map<String, Object?> output = {
      'type': 'ed25519-keypair',
      'sourceFormat': _detectKeyPairFormat(paserk),
      'publicKeyPaserk': pair.publicKey.toPaserk(),
      'publicKeyId': pair.publicKey.toPaserkIdentifier(),
      'paserkSecret': pair.toPaserkSecret(),
      'secretId': pair.toPaserkSecretIdentifier(),
    };

    if (password != null && password.isNotEmpty) {
      final String paserkSecretPw = await pair.toPaserkSecretPassword(
        password: password,
      );
      output['paserkSecretPw'] = paserkSecretPw;
      _applyPasswordMetadata(
        output,
        _parsePaserkPasswordMetadata(
          paserkSecretPw,
          ['keypair', 'info'],
        ),
      );
    } else if (paserk.startsWith('k4.secret-pw')) {
      output['paserkSecretPw'] = paserk;
      _applyPasswordMetadata(
        output,
        _parsePaserkPasswordMetadata(paserk, ['keypair', 'info']),
      );
    }

    if (wrappingKey != null) {
      output['paserkSecretWrap'] = pair.toPaserkSecretWrap(
        wrappingKey: wrappingKey,
      );
    } else if (paserk.startsWith('k4.secret-wrap')) {
      output['paserkSecretWrap'] = paserk;
    }

    await _printJson(output, pretty: pretty, outputPath: outputPath);
  } finally {
    pair?.privateKey.dispose();
    pair?.publicKey.dispose();
    wrappingKey?.dispose();
  }
}

Future<void> _handleSymmetricGenerate(
  ArgResults args,
  bool pretty,
  String? outputPath,
) async {
  if (args['help'] == true) {
    _printUsage(['symmetric', 'generate']);
    return;
  }

  final String? password = _trimmedValue(args['password']);
  final String? wrapPaserk = _trimmedValue(args['wrap']);
  final String? sealWith = _trimmedValue(args['seal-with']);

  LicensifySymmetricKey? wrappingKey;
  LicensifyPublicKey? sealingKey;

  if (wrapPaserk != null) {
    wrappingKey = _parseSymmetricKey(wrapPaserk, ['symmetric', 'generate']);
  }

  if (sealWith != null) {
    sealingKey = _parsePublicKey(sealWith, ['symmetric', 'generate']);
  }

  final LicensifySymmetricKey key = LicensifyKey.generateLocalKey();

  try {
    final Map<String, Object?> output = {
      'type': 'xchacha20-key',
      'paserkLocal': key.toPaserk(),
      'localId': key.toPaserkIdentifier(),
    };

    if (password != null && password.isNotEmpty) {
      final String paserkLocalPw =
          await key.toPaserkPassword(password: password);
      output['paserkLocalPw'] = paserkLocalPw;
      _applyPasswordMetadata(
        output,
        _parsePaserkPasswordMetadata(
          paserkLocalPw,
          ['symmetric', 'generate'],
        ),
      );
    }

    if (wrappingKey != null) {
      output['paserkLocalWrap'] = key.toPaserkWrap(wrappingKey: wrappingKey);
    }

    if (sealingKey != null) {
      output['paserkSeal'] = await key.toPaserkSeal(publicKey: sealingKey);
    }

    await _printJson(output, pretty: pretty, outputPath: outputPath);
  } finally {
    key.dispose();
    wrappingKey?.dispose();
    sealingKey?.dispose();
  }
}

Future<void> _handleSymmetricInfo(
  ArgResults args,
  bool pretty,
  _CliInput? fileInput,
  String? outputPath,
) async {
  if (args['help'] == true) {
    _printUsage(['symmetric', 'info']);
    return;
  }

  final String? paserkInput = _trimmedValue(args['paserk']) ??
      _paserkFromInput(fileInput, const [
        'paserkLocal',
        'paserkLocalPw',
        'paserkLocalWrap',
        'paserkSeal',
      ]);
  if (paserkInput == null || paserkInput.isEmpty) {
    throw _CliUsageException('Provide --paserk with a PASERK string.', ['symmetric', 'info']);
  }

  final String paserk = paserkInput;
  final String? password = _trimmedValue(args['password']);
  final String? wrapPaserk = _trimmedValue(args['wrap']);

  LicensifySymmetricKey? key;
  LicensifySymmetricKey? wrappingKey;
  LicensifyKeyPair? keyPair;
  LicensifyPublicKey? publicKey;

  try {
    if (paserk.startsWith('k4.local-pw')) {
      if (password == null || password.isEmpty) {
        throw _CliUsageException(
          'Provide --password to open k4.local-pw inputs.',
          ['symmetric', 'info'],
        );
      }
      key = await LicensifySymmetricKey.fromPaserkPassword(
        paserk: paserk,
        password: password,
      );
    } else if (paserk.startsWith('k4.local-wrap')) {
      if (wrapPaserk == null || wrapPaserk.isEmpty) {
        throw _CliUsageException(
          'Provide --wrap with the wrapping k4.local key to open k4.local-wrap.pie inputs.',
          ['symmetric', 'info'],
        );
      }
      wrappingKey = _parseSymmetricKey(wrapPaserk, ['symmetric', 'info']);
      key = LicensifySymmetricKey.fromPaserkWrap(
        paserk: paserk,
        wrappingKey: wrappingKey,
      );
    } else if (paserk.startsWith('k4.seal')) {
      final String? keyPairPaserk = _trimmedValue(args['keypair']);
      if (keyPairPaserk == null || keyPairPaserk.isEmpty) {
        throw _CliUsageException(
          'Provide --keypair with a k4.secret* value to unseal k4.seal inputs.',
          ['symmetric', 'info'],
        );
      }
      final String? keyPairPassword = _trimmedValue(args['keypair-password']);
      final String? keyPairWrap = _trimmedValue(args['keypair-wrap']);
      keyPair = await _loadKeyPair(
        paserk: keyPairPaserk,
        password: keyPairPassword,
        wrappingKeyPaserk: keyPairWrap,
        commandPath: ['symmetric', 'info'],
      );
      key = await LicensifySymmetricKey.fromPaserkSeal(
        paserk: paserk,
        keyPair: keyPair,
      );
      publicKey = keyPair.publicKey;
    } else if (paserk.startsWith('k4.local')) {
      key = LicensifySymmetricKey.fromPaserk(paserk: paserk);
    } else {
      throw _CliUsageException(
        'Unsupported PASERK format for symmetric keys: $paserk',
        ['symmetric', 'info'],
      );
    }

    final Map<String, Object?> output = {
      'type': 'xchacha20-key',
      'sourceFormat': _detectSymmetricFormat(paserk),
      'paserkLocal': key.toPaserk(),
      'localId': key.toPaserkIdentifier(),
    };

    if (password != null && password.isNotEmpty) {
      final String paserkLocalPw =
          await key.toPaserkPassword(password: password);
      output['paserkLocalPw'] = paserkLocalPw;
      _applyPasswordMetadata(
        output,
        _parsePaserkPasswordMetadata(
          paserkLocalPw,
          ['symmetric', 'info'],
        ),
      );
    } else if (paserk.startsWith('k4.local-pw')) {
      output['paserkLocalPw'] = paserk;
      _applyPasswordMetadata(
        output,
        _parsePaserkPasswordMetadata(paserk, ['symmetric', 'info']),
      );
    }

    if (wrappingKey != null) {
      output['paserkLocalWrap'] = key.toPaserkWrap(wrappingKey: wrappingKey);
    } else if (paserk.startsWith('k4.local-wrap')) {
      output['paserkLocalWrap'] = paserk;
    }

    if (publicKey != null) {
      output['paserkSeal'] = await key.toPaserkSeal(publicKey: publicKey);
    } else if (paserk.startsWith('k4.seal')) {
      output['paserkSeal'] = paserk;
    }

    await _printJson(output, pretty: pretty, outputPath: outputPath);
  } finally {
    key?.dispose();
    wrappingKey?.dispose();
    if (keyPair != null) {
      keyPair.privateKey.dispose();
      if (!keyPair.publicKey.isDisposed) {
        keyPair.publicKey.dispose();
      }
    }
    publicKey?.dispose();
  }
}

Future<void> _handleSymmetricDerive(
  ArgResults args,
  bool pretty,
  String? outputPath,
) async {
  if (args['help'] == true) {
    _printUsage(['symmetric', 'derive']);
    return;
  }

  final String? password = _trimmedValue(args['password']);
  if (password == null || password.isEmpty) {
    throw _CliUsageException(
      'Provide --password with the secret used for key derivation.',
      ['symmetric', 'derive'],
    );
  }

  final String? saltInput = _trimmedValue(args['salt']);
  if (saltInput == null || saltInput.isEmpty) {
    throw _CliUsageException(
      'Provide --salt with a base64url encoded salt.',
      ['symmetric', 'derive'],
    );
  }

  final int memoryCost = _parsePositiveInt(
    args['memory-cost'],
    'memory-cost',
    ['symmetric', 'derive'],
  );
  final int timeCost = _parsePositiveInt(
    args['time-cost'],
    'time-cost',
    ['symmetric', 'derive'],
  );
  final int parallelism = _parsePositiveInt(
    args['parallelism'],
    'parallelism',
    ['symmetric', 'derive'],
  );

  if (memoryCost % 1024 != 0) {
    throw _CliUsageException(
      '--memory-cost must be a positive multiple of 1024.',
      ['symmetric', 'derive'],
    );
  }

  final LicensifySalt salt;
  try {
    salt = LicensifySalt.fromString(value: saltInput);
  } on FormatException catch (e) {
    throw _CliUsageException(e.message, ['symmetric', 'derive']);
  }

  LicensifyPublicKey? sealKey;
  final String? sealWith = _trimmedValue(args['seal-with']);
  if (sealWith != null) {
    sealKey = _parsePublicKey(sealWith, ['symmetric', 'derive']);
  }

  final LicensifySymmetricKey key = await LicensifySymmetricKey.fromPassword(
    password: password,
    salt: salt,
    memoryCost: memoryCost,
    timeCost: timeCost,
    parallelism: parallelism,
  );

  try {
    final Map<String, Object?> output = {
      'type': 'xchacha20-key',
      'salt': salt.asString(),
      'memoryCost': memoryCost,
      'timeCost': timeCost,
      'parallelism': parallelism,
      'paserkLocal': key.toPaserk(),
      'localId': key.toPaserkIdentifier(),
      'paserkLocalPw': await key.toPaserkPassword(password: password),
    };

    _applyPasswordMetadata(
      output,
      _parsePaserkPasswordMetadata(
        output['paserkLocalPw']! as String,
        ['symmetric', 'derive'],
      ),
      preferTopLevelSalt: false,
    );

    if (sealKey != null) {
      output['paserkSeal'] = await key.toPaserkSeal(publicKey: sealKey);
    }

    await _printJson(output, pretty: pretty, outputPath: outputPath);
  } finally {
    key.dispose();
    sealKey?.dispose();
  }
}

Future<void> _handleSaltGenerate(
  ArgResults args,
  bool pretty,
  String? outputPath,
) async {
  if (args['help'] == true) {
    _printUsage(['salt', 'generate']);
    return;
  }

  final String? lengthRaw = _trimmedValue(args['length']);
  LicensifySalt salt;

  if (lengthRaw == null || lengthRaw.isEmpty) {
    salt = LicensifySymmetricKey.generatePasswordSalt();
  } else {
    final int length = _parsePositiveInt(lengthRaw, 'length', ['salt', 'generate']);
    salt = LicensifySalt.random(length: length);
  }

  final Map<String, Object?> output = {
    'type': 'argon2-salt',
    'salt': salt.asString(),
    'length': salt.length,
  };
  await _printJson(output, pretty: pretty, outputPath: outputPath);
}

Future<_CliInput?> _loadInput(
  String? path,
  List<String> commandPath,
) async {
  if (path == null || path.isEmpty) {
    return null;
  }

  final File file = File(path);
  if (!await file.exists()) {
    throw _CliUsageException('Input file not found: $path', commandPath);
  }

  try {
    final String raw = await file.readAsString();
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const _CliInput(content: '');
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _CliInput(
          content: trimmed,
          json: Map<String, Object?>.from(decoded),
        );
      }
    } catch (_) {
      // Treat as plain text if JSON parsing fails.
    }

    return _CliInput(content: trimmed);
  } catch (e) {
    throw _CliUsageException('Failed to read input file "$path": $e', commandPath);
  }
}

class _CliInput {
  const _CliInput({required this.content, this.json});

  final String content;
  final Map<String, Object?>? json;
}

String? _paserkFromInput(_CliInput? input, List<String> preferredKeys) {
  if (input == null) {
    return null;
  }

  final Map<String, Object?>? json = input.json;
  if (json != null) {
    for (final String key in preferredKeys) {
      final Object? value = json[key];
      if (value is String) {
        final String trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    for (final Object? value in json.values) {
      if (value is String) {
        final String trimmed = value.trim();
        if (trimmed.startsWith('k4.')) {
          return trimmed;
        }
      }
    }

    return null;
  }

  final String trimmed = input.content.trim();
  return trimmed.isEmpty ? null : trimmed;
}

LicensifySymmetricKey _parseSymmetricKey(String paserk, List<String> commandPath) {
  try {
    return LicensifySymmetricKey.fromPaserk(paserk: paserk);
  } catch (e) {
    throw _CliUsageException('Failed to parse k4.local key: $e', commandPath);
  }
}

LicensifyPublicKey _parsePublicKey(String paserk, List<String> commandPath) {
  try {
    return LicensifyPublicKey.fromPaserk(paserk: paserk);
  } catch (e) {
    throw _CliUsageException('Failed to parse k4.public key: $e', commandPath);
  }
}

Future<LicensifyKeyPair> _loadKeyPair({
  required String paserk,
  required List<String> commandPath,
  String? password,
  String? wrappingKeyPaserk,
}) async {
  if (paserk.startsWith('k4.secret-pw')) {
    if (password == null || password.isEmpty) {
      throw _CliUsageException(
        'Provide --keypair-password to open the supplied key pair.',
        commandPath,
      );
    }
    return LicensifyKeyPair.fromPaserkSecretPassword(
      paserk: paserk,
      password: password,
    );
  }

  if (paserk.startsWith('k4.secret-wrap')) {
    if (wrappingKeyPaserk == null || wrappingKeyPaserk.isEmpty) {
      throw _CliUsageException(
        'Provide --keypair-wrap with the wrapping k4.local key.',
        commandPath,
      );
    }
    final LicensifySymmetricKey wrappingKey =
        _parseSymmetricKey(wrappingKeyPaserk, commandPath);
    try {
      return LicensifyKeyPair.fromPaserkSecretWrap(
        paserk: paserk,
        wrappingKey: wrappingKey,
      );
    } finally {
      wrappingKey.dispose();
    }
  }

  if (paserk.startsWith('k4.secret')) {
    return LicensifyKeyPair.fromPaserkSecret(paserk: paserk);
  }

  throw _CliUsageException(
    'Unsupported PASERK format for key pair: $paserk',
    commandPath,
  );
}

int _parsePositiveInt(Object? value, String name, List<String> commandPath) {
  final String? raw = _trimmedValue(value);
  if (raw == null || raw.isEmpty) {
    throw _CliUsageException('Provide --$name with a positive integer.', commandPath);
  }

  final int? parsed = int.tryParse(raw);
  if (parsed == null || parsed <= 0) {
    throw _CliUsageException('Provide --$name with a positive integer.', commandPath);
  }
  return parsed;
}

String? _trimmedValue(Object? value) {
  if (value == null) {
    return null;
  }
  return value.toString().trim();
}

String _detectKeyPairFormat(String paserk) {
  if (paserk.startsWith('k4.secret-pw')) {
    return 'k4.secret-pw';
  }
  if (paserk.startsWith('k4.secret-wrap')) {
    return 'k4.secret-wrap.pie';
  }
  if (paserk.startsWith('k4.secret')) {
    return 'k4.secret';
  }
  if (paserk.startsWith('k4.public')) {
    return 'k4.public';
  }
  return 'unknown';
}

void _applyPasswordMetadata(
  Map<String, Object?> output,
  _PaserkPasswordMetadata? metadata, {
  bool preferTopLevelSalt = true,
}) {
  if (metadata == null) {
    return;
  }

  output['passwordSalt'] = metadata.salt;
  output['passwordMemoryCost'] = metadata.memoryCost;
  output['passwordTimeCost'] = metadata.timeCost;
  output['passwordParallelism'] = metadata.parallelism;
  if (preferTopLevelSalt) {
    output['salt'] = metadata.salt;
  } else {
    output.putIfAbsent('salt', () => metadata.salt);
  }
}

_PaserkPasswordMetadata? _parsePaserkPasswordMetadata(
  String paserk,
  List<String> commandPath,
) {
  const int parameterSectionLength = 8 + 4 + 4; // memory + time + parallelism

  final _PaserkPasswordLayout? layout = _detectPasswordLayout(paserk);
  if (layout == null) {
    return null;
  }

  final String payload = paserk.substring(layout.prefix.length);
  final String padded = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');

  final Uint8List decoded;
  try {
    decoded = Uint8List.fromList(base64Url.decode(padded));
  } on FormatException catch (e) {
    throw _CliUsageException(
      'Failed to decode password-protected PASERK payload: ${e.message}',
      commandPath,
    );
  }

  if (decoded.length < layout.saltLength + parameterSectionLength) {
    throw _CliUsageException(
      'Password-protected PASERK payload is truncated.',
      commandPath,
    );
  }

  var offset = 0;
  final Uint8List saltBytes =
      decoded.sublist(offset, offset + layout.saltLength);
  offset += layout.saltLength;
  final int memoryCost = _readUint64(decoded, offset);
  offset += 8;
  final int timeCost = _readUint32(decoded, offset);
  offset += 4;
  final int parallelism = _readUint32(decoded, offset);

  final LicensifySalt salt = LicensifySalt.fromBytes(bytes: saltBytes);

  return _PaserkPasswordMetadata(
    salt: salt.asString(),
    memoryCost: memoryCost,
    timeCost: timeCost,
    parallelism: parallelism,
  );
}

_PaserkPasswordLayout? _detectPasswordLayout(String paserk) {
  if (paserk.startsWith(PaserkKey.k4LocalPwPrefix)) {
    return const _PaserkPasswordLayout(
      prefix: PaserkKey.k4LocalPwPrefix,
      saltLength: K4LocalPw.saltLength,
    );
  }
  if (paserk.startsWith(PaserkKey.k4SecretPwPrefix)) {
    return const _PaserkPasswordLayout(
      prefix: PaserkKey.k4SecretPwPrefix,
      saltLength: K4SecretPw.saltLength,
    );
  }
  return null;
}

int _readUint32(Uint8List data, int offset) {
  int value = 0;
  for (var i = 0; i < 4; i++) {
    value = (value << 8) | data[offset + i];
  }
  return value;
}

int _readUint64(Uint8List data, int offset) {
  int value = 0;
  for (var i = 0; i < 8; i++) {
    value = (value << 8) | data[offset + i];
  }
  return value;
}

class _PaserkPasswordMetadata {
  const _PaserkPasswordMetadata({
    required this.salt,
    required this.memoryCost,
    required this.timeCost,
    required this.parallelism,
  });

  final String salt;
  final int memoryCost;
  final int timeCost;
  final int parallelism;
}

class _PaserkPasswordLayout {
  const _PaserkPasswordLayout({
    required this.prefix,
    required this.saltLength,
  });

  final String prefix;
  final int saltLength;
}

String _detectSymmetricFormat(String paserk) {
  if (paserk.startsWith('k4.local-pw')) {
    return 'k4.local-pw';
  }
  if (paserk.startsWith('k4.local-wrap')) {
    return 'k4.local-wrap.pie';
  }
  if (paserk.startsWith('k4.seal')) {
    return 'k4.seal';
  }
  if (paserk.startsWith('k4.local')) {
    return 'k4.local';
  }
  return 'unknown';
}

Future<void> _printJson(
  Map<String, Object?> data, {
  required bool pretty,
  String? outputPath,
}) async {
  final JsonEncoder encoder = pretty
      ? const JsonEncoder.withIndent('  ')
      : const JsonEncoder();
  final String json = encoder.convert(data);
  final String payload = '$json\n';
  if (outputPath == null || outputPath.isEmpty) {
    stdout.write(payload);
    return;
  }

  final File file = File(outputPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(payload);
}

List<String> _commandPathFrom(ArgResults command) {
  final List<String> path = <String>[];
  ArgResults? current = command;
  while (current != null) {
    final String? name = current.name;
    if (name != null) {
      path.add(name);
    }
    current = current.command;
  }
  return path;
}

void _writeCommandTable(
  Map<String, String> commands, {
  required String heading,
}) {
  if (commands.isEmpty) {
    return;
  }

  stderr.writeln(heading);
  int maxNameLength = 0;
  for (final String name in commands.keys) {
    if (name.length > maxNameLength) {
      maxNameLength = name.length;
    }
  }

  for (final MapEntry<String, String> entry in commands.entries) {
    final String name = entry.key;
    final String description = entry.value;
    final String padding = ' ' * (maxNameLength - name.length + 2);
    stderr.writeln('  $name$padding$description');
  }
}

void _printUsage(List<String> commandPath, {String? error}) {
  if (error != null) {
    stderr.writeln('Error: $error');
    stderr.writeln('');
  }

  if (commandPath.isEmpty) {
    stderr.writeln('Usage: licensify <command> [arguments]');
    stderr.writeln('');
    stderr.writeln(_rootParser.usage);
    stderr.writeln('');
    _writeCommandTable(_rootCommandDescriptions, heading: 'Commands:');
    return;
  }

  final String command = commandPath.first;
  switch (command) {
    case 'keypair':
      stderr.writeln('Usage: licensify keypair <subcommand> [arguments]');
      stderr.writeln('');
      stderr.writeln(_keypairParser.usage);
      stderr.writeln('');
      _writeCommandTable(
        _keypairCommandDescriptions,
        heading: 'Subcommands:',
      );
      if (commandPath.length > 1) {
        final String sub = commandPath[1];
        final ArgParser? subParser = _keypairParser.commands[sub];
        if (subParser != null) {
          stderr.writeln('');
          stderr.writeln(subParser.usage);
        }
      }
      return;
    case 'symmetric':
      stderr.writeln('Usage: licensify symmetric <subcommand> [arguments]');
      stderr.writeln('');
      stderr.writeln(_symmetricParser.usage);
      stderr.writeln('');
      _writeCommandTable(
        _symmetricCommandDescriptions,
        heading: 'Subcommands:',
      );
      if (commandPath.length > 1) {
        final String sub = commandPath[1];
        final ArgParser? subParser = _symmetricParser.commands[sub];
        if (subParser != null) {
          stderr.writeln('');
          stderr.writeln(subParser.usage);
        }
      }
      return;
    case 'salt':
      stderr.writeln('Usage: licensify salt <subcommand> [arguments]');
      stderr.writeln('');
      stderr.writeln(_saltParser.usage);
      stderr.writeln('');
      _writeCommandTable(
        _saltCommandDescriptions,
        heading: 'Subcommands:',
      );
      if (commandPath.length > 1) {
        final String sub = commandPath[1];
        final ArgParser? subParser = _saltParser.commands[sub];
        if (subParser != null) {
          stderr.writeln('');
          stderr.writeln(subParser.usage);
        }
      }
      return;
    default:
      stderr.writeln('Usage: licensify <command> [arguments]');
      stderr.writeln('');
      stderr.writeln(_rootParser.usage);
      return;
  }
}

class _CliUsageException implements Exception {
  _CliUsageException(this.message, this.commandPath);

  final String message;
  final List<String> commandPath;

  @override
  String toString() => message;
}
