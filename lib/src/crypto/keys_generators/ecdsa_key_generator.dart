// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Utility for generating ECDSA key pairs with customizable parameters
abstract interface class EcdsaKeyGenerator {
  /// Generates an ECDSA key pair using the specified parameters
  ///
  /// [curve] - The elliptic curve to use (default: EcCurve.p256 / NIST P-256)
  /// [random] - The secure random algorithm to use
  /// [seedLength] - Length of the random seed in bytes
  /// [blockCipherName] - Name of block cipher to use with BlockCtr (default: 'AES')
  ///
  /// Returns an asymmetric key pair containing ECDSA public and private keys
  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateKeyPair({
    EcCurve curve = EcCurve.p256,
    SecureRandomAlgorithm randomAlgorithm = SecureRandomAlgorithm.fortuna,
    int seedLength = 32,
    bool useFixedSeed = false,
    Uint8List? seed,
    String blockCipherName = 'AES',
  }) {
    // Get curve domain parameters
    final domainParams = ECDomainParameters(curve.name);

    // Initialize key generator
    final keyGen = KeyGenerator('EC');
    final secureRandom = _getSecureRandom(
      randomAlgorithm,
      seedLength: seedLength,
      useFixedSeed: useFixedSeed,
      seed: seed,
      blockCipherName: blockCipherName,
    );

    // Parameters for key generation
    final ecdsaParams = ECKeyGeneratorParameters(domainParams);
    final params = ParametersWithRandom(ecdsaParams, secureRandom);

    // Generate keys
    keyGen.init(params);
    final keyPair = keyGen.generateKeyPair();

    final publicKey = keyPair.publicKey as ECPublicKey;
    final privateKey = keyPair.privateKey as ECPrivateKey;

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(publicKey, privateKey);
  }

  /// Returns a pair of ECDSA keys in PEM format
  ///
  /// [curve] - The elliptic curve to use (default: EcCurve.p256 / NIST P-256)
  /// [randomAlgorithm] - The secure random algorithm to use
  /// [seedLength] - Length of the random seed in bytes
  /// [withPrivateHeader] - Whether to include EC PRIVATE KEY header (true) or just PRIVATE KEY header (false)
  /// [blockCipherName] - Name of block cipher to use with BlockCtr (default: 'AES')
  ///
  /// Returns a CryptoKeyPair object containing public and private keys
  static LicensifyKeyPair generateKeyPairAsPem({
    EcCurve curve = EcCurve.p256,
    SecureRandomAlgorithm randomAlgorithm = SecureRandomAlgorithm.fortuna,
    int seedLength = 32,
    bool withPrivateHeader = true,
    bool useFixedSeed = false,
    Uint8List? seed,
    String blockCipherName = 'AES',
  }) {
    final keyPair = generateKeyPair(
      curve: curve,
      randomAlgorithm: randomAlgorithm,
      seedLength: seedLength,
      useFixedSeed: useFixedSeed,
      seed: seed,
      blockCipherName: blockCipherName,
    );

    // Convert keys to PEM format
    final publicKeyPem = CryptoUtils.encodeEcPublicKeyToPem(keyPair.publicKey);
    final privateKeyPem = CryptoUtils.encodeEcPrivateKeyToPem(
      keyPair.privateKey,
    );

    // Create key objects with proper type
    final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPem);
    final publicKey = LicensifyPublicKey.ecdsa(publicKeyPem);

    return LicensifyKeyPair(privateKey: privateKey, publicKey: publicKey);
  }

  /// Returns a secure random generator based on the specified algorithm
  static SecureRandom _getSecureRandom(
    SecureRandomAlgorithm algorithm, {
    int seedLength = 32,
    bool useFixedSeed = false,
    Uint8List? seed,
    String blockCipherName = 'AES',
  }) {
    // Determine seed bytes
    final seedBytes =
        useFixedSeed && seed != null ? seed : _generateRandomSeed(seedLength);

    // Create appropriate secure random based on algorithm
    switch (algorithm) {
      case SecureRandomAlgorithm.fortuna:
        final secureRandom = FortunaRandom();
        secureRandom.seed(KeyParameter(seedBytes));
        return secureRandom;

      case SecureRandomAlgorithm.blockCtr:
        // Creating a block CTR random, using specified block cipher
        final secureRandom = BlockCtrRandom(BlockCipher(blockCipherName));
        secureRandom.seed(KeyParameter(seedBytes));
        return secureRandom;

      case SecureRandomAlgorithm.autoSeedBlockCtr:
        // Auto-seeded block CTR random (reseeds itself periodically)
        final secureRandom = FortunaRandom();
        secureRandom.seed(KeyParameter(seedBytes));
        return secureRandom;
    }
  }

  /// Generates a random seed of specified length
  static Uint8List _generateRandomSeed(int length) {
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < length; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    return Uint8List.fromList(seeds);
  }
}
