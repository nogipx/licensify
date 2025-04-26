// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Interface for the verify signature use case
abstract class IVerifySignatureUseCase {
  /// Verifies a signature against data with a public key
  ///
  /// [data] - The original string data that was signed
  /// [signature] - The signature to verify (Base64 encoded)
  /// [publicKey] - The public key for verification
  /// [digest] - Optional digest algorithm (defaults to SHA-512)
  ///
  /// Returns true if the signature is valid for the data
  bool call({
    required String data,
    required String signature,
    required LicensifyPublicKey publicKey,
    Digest? digest,
  });
}

/// Implementation of the verify signature use case
///
/// This class handles the cryptographic signature verification
/// for any data using ECDSA signatures.
class VerifySignatureUseCase implements IVerifySignatureUseCase {
  @override
  bool call({
    required String data,
    required String signature,
    required LicensifyPublicKey publicKey,
    Digest? digest,
  }) {
    if (publicKey.keyType != LicensifyKeyType.ecdsa) {
      throw UnsupportedError('Only ECDSA keys are supported');
    }

    final actualDigest = digest ?? SHA512Digest();
    try {
      // Prepare the ECDSA public key
      final ecPublicKey = CryptoUtils.ecPublicKeyFromPem(publicKey.content);

      // Decode DER-encoded signature from Base64
      final derSignature = base64Decode(signature);

      // Parse DER signature bytes into ECSignature
      final ecSignature = _decodeEcSignature(derSignature);

      // Hash the data
      final dataBytes = Uint8List.fromList(utf8.encode(data));
      final hashedData = actualDigest.process(dataBytes);

      // Create ECDSA verifier
      final verifier = ECDSASigner(actualDigest);
      final params = PublicKeyParameter<ECPublicKey>(ecPublicKey);
      verifier.init(false, params);

      // Verify signature
      return verifier.verifySignature(hashedData, ecSignature);
    } catch (e) {
      print('Signature verification error: $e');
      return false;
    }
  }

  /// Decodes DER-format signature into ECSignature
  ECSignature _decodeEcSignature(Uint8List derBytes) {
    try {
      // Ensure it starts with SEQUENCE
      if (derBytes.length < 2 || derBytes[0] != 0x30) {
        throw Exception('Expected SEQUENCE tag at start of DER');
      }

      int index = 2; // Skip SEQUENCE tag (0x30) and length

      // First INTEGER (r)
      if (derBytes.length <= index || derBytes[index] != 0x02) {
        throw Exception('Expected INTEGER tag for r');
      }
      index++;

      // Get r length
      final rLength = derBytes[index];
      index++;

      if (derBytes.length < index + rLength) {
        throw Exception('DER data too short for r value');
      }

      // Extract r bytes
      final rBytes = derBytes.sublist(index, index + rLength);
      index += rLength;

      // Second INTEGER (s)
      if (derBytes.length <= index || derBytes[index] != 0x02) {
        throw Exception('Expected INTEGER tag for s');
      }
      index++;

      // Get s length
      final sLength = derBytes[index];
      index++;

      if (derBytes.length < index + sLength) {
        throw Exception('DER data too short for s value');
      }

      // Extract s bytes
      final sBytes = derBytes.sublist(index, index + sLength);

      // Convert bytes to BigInt
      final r = _decodeBigInt(rBytes);
      final s = _decodeBigInt(sBytes);

      return ECSignature(r, s);
    } catch (e) {
      throw Exception('Failed to decode signature: $e');
    }
  }

  /// Decodes bytes to BigInt, accounting for DER positive number representation
  BigInt _decodeBigInt(Uint8List bytes) {
    // If first byte is 0, it was added for positive representation in DER
    if (bytes.length > 1 && bytes[0] == 0) {
      bytes = bytes.sublist(1);
    }

    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }
}
