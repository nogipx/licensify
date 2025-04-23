// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Interface for the sign data use case
abstract class ISignDataUseCase {
  /// Signs data with a private key
  ///
  /// [data] - The string data to sign
  /// [privateKey] - The private key used for signing
  /// [digest] - Optional digest algorithm (defaults to SHA-512)
  ///
  /// Returns the signature encoded as Base64 string
  String call({
    required String data,
    required LicensifyPrivateKey privateKey,
    Digest? digest,
  });
}

/// Implementation of the sign data use case
///
/// This class handles the cryptographic signature generation
/// for any data using ECDSA signatures.
class SignDataUseCase implements ISignDataUseCase {
  @override
  String call({
    required String data,
    required LicensifyPrivateKey privateKey,
    Digest? digest,
  }) {
    if (privateKey.keyType != LicensifyKeyType.ecdsa) {
      throw UnsupportedError('Only ECDSA keys are supported');
    }

    final actualDigest = digest ?? SHA512Digest();
    try {
      // Parse ECDSA private key from PEM
      final ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(privateKey.content);

      // Create a secure random number generator
      final secureRandom = FortunaRandom();
      final seedSource = Random.secure();
      final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
      secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

      // Hash the data
      final dataBytes = Uint8List.fromList(utf8.encode(data));
      final hashedData = actualDigest.process(dataBytes);

      // Create ECDSA signer
      final signer = ECDSASigner(actualDigest);

      // Initialize with private key and randomizer
      final params = PrivateKeyParameter<ECPrivateKey>(ecPrivateKey);
      final signerParams = ParametersWithRandom(params, secureRandom);
      signer.init(true, signerParams);

      // Generate signature
      final signature = signer.generateSignature(hashedData) as ECSignature;

      // Encode r and s components in DER format
      final rBytes = _encodeBigInt(signature.r);
      final sBytes = _encodeBigInt(signature.s);
      final derBytes = _createDerSequence(rBytes, sBytes);

      return base64Encode(derBytes);
    } catch (e) {
      throw Exception('Failed to generate signature: $e');
    }
  }

  /// Helper for encoding BigInt to byte array
  Uint8List _encodeBigInt(BigInt value) {
    // Convert to unsigned hexadecimal format
    var hex = value.toRadixString(16);
    if (hex.length % 2 == 1) {
      hex = '0$hex';
    }

    // Create byte array
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }

    // If the first bit is set (byte >= 128), add 0 at the beginning
    // to ensure the number is interpreted as positive
    if (bytes.isNotEmpty && (bytes[0] & 0x80) != 0) {
      final result = Uint8List(bytes.length + 1);
      result[0] = 0;
      result.setRange(1, result.length, bytes);
      return result;
    }

    return bytes;
  }

  /// Creates DER sequence for signature
  Uint8List _createDerSequence(Uint8List r, Uint8List s) {
    final rBytes = _ensurePositive(r);
    final sBytes = _ensurePositive(s);

    // Calculate total sequence length
    final totalLength = 2 + rBytes.length + 2 + sBytes.length;

    // Create buffer for DER sequence
    final result = BytesBuilder();

    // Add SEQUENCE tag and length
    result.addByte(0x30); // SEQUENCE tag
    result.addByte(totalLength);

    // Add r component
    result.addByte(0x02); // INTEGER tag
    result.addByte(rBytes.length);
    result.add(rBytes);

    // Add s component
    result.addByte(0x02); // INTEGER tag
    result.addByte(sBytes.length);
    result.add(sBytes);

    return result.toBytes();
  }

  /// Ensures that the first bit is not set (positive number in DER)
  Uint8List _ensurePositive(Uint8List bytes) {
    if (bytes.isEmpty) {
      return Uint8List.fromList([0]);
    }

    // If the highest bit of the first byte is set (negative number in DER),
    // add a leading zero
    if (bytes[0] & 0x80 != 0) {
      final result = Uint8List(bytes.length + 1);
      result[0] = 0;
      result.setRange(1, result.length, bytes);
      return result;
    }

    return bytes;
  }
}
