// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:paseto_dart/paseto_dart.dart';
import '../paseto_key.dart';

/// Real Ed25519 key generator using paseto_dart library
///
/// This generator creates cryptographically secure Ed25519 keys
/// using the same library and algorithms as PASETO v4.public
class Ed25519KeyGenerator {
  /// Generates a real Ed25519 key pair using paseto_dart
  ///
  /// Returns properly formatted keys that work with PASETO v4.public
  static Future<LicensifyPasetoKeyPair> generateKeyPair() async {
    try {
      // Use paseto_dart's Ed25519 implementation
      final ed25519 = Ed25519();
      final keyPair = await ed25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();

      // Extract raw key bytes
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      final publicKeyBytes = publicKey.bytes;

      // Create our wrapper keys
      final privateKey = LicensifyPasetoPrivateKey.ed25519(
        Uint8List.fromList(privateKeyBytes),
      );
      final publicKeyWrapper = LicensifyPasetoPublicKey.ed25519(
        Uint8List.fromList(publicKeyBytes),
      );

      return LicensifyPasetoKeyPair(
        privateKey: privateKey,
        publicKey: publicKeyWrapper,
      );
    } catch (e) {
      throw Exception('Failed to generate real Ed25519 key pair: $e');
    }
  }

  /// Generates key pair as raw bytes for advanced use cases
  static Future<Map<String, Uint8List>> generateKeyPairAsBytes() async {
    try {
      final ed25519 = Ed25519();
      final keyPair = await ed25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();

      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      final publicKeyBytes = publicKey.bytes;

      return {
        'privateKey': Uint8List.fromList(privateKeyBytes),
        'publicKey': Uint8List.fromList(publicKeyBytes),
      };
    } catch (e) {
      throw Exception('Failed to generate Ed25519 key bytes: $e');
    }
  }

  /// Creates a key pair from existing private key seed
  static Future<LicensifyPasetoKeyPair> fromPrivateKeySeed(
    Uint8List seed,
  ) async {
    try {
      if (seed.length != 32) {
        throw ArgumentError('Ed25519 seed must be exactly 32 bytes');
      }

      final ed25519 = Ed25519();
      final keyPair = await ed25519.newKeyPairFromSeed(seed);
      final publicKey = await keyPair.extractPublicKey();

      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      final publicKeyBytes = publicKey.bytes;

      final privateKey = LicensifyPasetoPrivateKey.ed25519(
        Uint8List.fromList(privateKeyBytes),
      );
      final publicKeyWrapper = LicensifyPasetoPublicKey.ed25519(
        Uint8List.fromList(publicKeyBytes),
      );

      return LicensifyPasetoKeyPair(
        privateKey: privateKey,
        publicKey: publicKeyWrapper,
      );
    } catch (e) {
      throw Exception('Failed to create key pair from seed: $e');
    }
  }

  /// Creates public key from bytes
  static LicensifyPasetoPublicKey publicKeyFromBytes(Uint8List bytes) {
    if (bytes.length != 32) {
      throw ArgumentError('Ed25519 public key must be exactly 32 bytes');
    }
    return LicensifyPasetoPublicKey.ed25519(bytes);
  }

  /// Creates private key from bytes
  static LicensifyPasetoPrivateKey privateKeyFromBytes(Uint8List bytes) {
    if (bytes.length != 32) {
      throw ArgumentError('Ed25519 private key must be exactly 32 bytes');
    }
    return LicensifyPasetoPrivateKey.ed25519(bytes);
  }
}
