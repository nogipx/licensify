// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

/// Утилита для генерации пары RSA ключей
class RsaKeyGenerator {
  /// Генерирует пару RSA ключей с заданным размером
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateKeyPair({int bitLength = 2048}) {
    final keyGen = KeyGenerator('RSA');
    final secureRandom = SecureRandom('Fortuna');

    // Инициализируем генератор случайных чисел
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (var i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Параметры для генерации ключей
    final rsaParams = RSAKeyGeneratorParameters(BigInt.from(65537), bitLength, 64);
    final params = ParametersWithRandom(rsaParams, secureRandom);

    // Генерируем ключи
    keyGen.init(params);
    final keyPair = keyGen.generateKeyPair();

    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
  }

  /// Возвращает пару ключей в формате PEM
  static ({String publicKey, String privateKey}) generateKeyPairAsPem({int bitLength = 2048}) {
    final keyPair = generateKeyPair(bitLength: bitLength);

    // Конвертируем ключи в формат PEM
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(keyPair.publicKey);
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(keyPair.privateKey);

    return (publicKey: publicKeyPem, privateKey: privateKeyPem);
  }
}
