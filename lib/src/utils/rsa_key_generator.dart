// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

/// Utility for generating RSA key pairs
class RsaKeyGenerator {
  /// Generates an RSA key pair with the specified bit length
  ///
  /// [bitLength] - The length of the key in bits (default: 2048)
  ///
  /// Returns an asymmetric key pair containing RSA public and private keys
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateKeyPair({
    int bitLength = 2048,
  }) {
    final keyGen = KeyGenerator('RSA');
    final secureRandom = SecureRandom('Fortuna');

    // Initialize random number generator
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Parameters for key generation
    final rsaParams = RSAKeyGeneratorParameters(
      BigInt.from(65537),
      bitLength,
      64,
    );
    final params = ParametersWithRandom(rsaParams, secureRandom);

    // Generate keys
    keyGen.init(params);
    final keyPair = keyGen.generateKeyPair();

    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      publicKey,
      privateKey,
    );
  }

  /// Returns a pair of keys in PEM format
  ///
  /// [bitLength] - The length of the key in bits (default: 2048)
  ///
  /// Returns a record containing public and private keys as PEM strings
  static ({String publicKey, String privateKey}) generateKeyPairAsPem({
    int bitLength = 2048,
  }) {
    final keyPair = generateKeyPair(bitLength: bitLength);

    // Convert keys to PEM format
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(keyPair.publicKey);
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
      keyPair.privateKey,
    );

    return (publicKey: publicKeyPem, privateKey: privateKeyPem);
  }
}
