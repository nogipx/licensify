// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import '../paseto_key.dart';
import 'real_ed25519_key_generator.dart';

/// Utility for generating Ed25519 key pairs for PASETO v4
///
/// Ed25519 is the recommended signature algorithm for PASETO v4.public
abstract interface class Ed25519KeyGenerator {
  /// Generates Ed25519 key pair for PASETO v4.public
  ///
  /// Uses real cryptographic algorithms from paseto_dart library
  static Future<LicensifyPasetoKeyPair> generateKeyPair() async {
    return await RealEd25519KeyGenerator.generateKeyPair();
  }

  /// Generates Ed25519 key pair as raw bytes
  ///
  /// Returns map with 'privateKey' and 'publicKey' as Uint8List
  /// This is useful when you need raw key material for custom storage.
  static Future<Map<String, Uint8List>> generateKeyPairAsBytes() async {
    return await RealEd25519KeyGenerator.generateKeyPairAsBytes();
  }

  /// Creates a key pair from existing private key seed
  static Future<LicensifyPasetoKeyPair> fromPrivateKeySeed(
    Uint8List seed,
  ) async {
    return await RealEd25519KeyGenerator.fromPrivateKeySeed(seed);
  }

  /// Creates public key from bytes
  static LicensifyPasetoPublicKey publicKeyFromBytes(Uint8List bytes) {
    return RealEd25519KeyGenerator.publicKeyFromBytes(bytes);
  }

  /// Creates private key from bytes
  static LicensifyPasetoPrivateKey privateKeyFromBytes(Uint8List bytes) {
    return RealEd25519KeyGenerator.privateKeyFromBytes(bytes);
  }
}
