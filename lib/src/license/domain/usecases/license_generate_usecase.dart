// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

/// Cryptographic key type
enum LicensifyKeyType {
  /// RSA algorithm (traditional)
  rsa,

  /// ECDSA algorithm (elliptic curves)
  ecdsa,
}

/// Use case for generating a new license
///
/// This class is responsible for creating cryptographically signed licenses.
/// It should only be used on the license issuer side, not in the client application.
class LicenseGenerateUseCase {
  /// Private key for signing licenses
  final LicensifyPrivateKey _privateKey;

  /// Type of key being used
  final LicensifyKeyType _keyType;

  /// Hash algorithm used for signing
  final Digest _digest;

  /// Creates a new license generator with the specified private key
  ///
  /// [privateKey] - PEM-encoded private key (RSA or ECDSA)
  /// [digest] - Hash algorithm used for signature (default: SHA-512)
  LicenseGenerateUseCase({
    required LicensifyPrivateKey privateKey,
    Digest? digest,
  }) : _privateKey = privateKey,
       _keyType = privateKey.keyType,
       _digest = digest ?? SHA512Digest();

  /// Generates a new license with cryptographic signature
  ///
  /// [appId] - Unique identifier of the application this license is for
  /// [expirationDate] - Date when the license expires
  /// [type] - License type (trial, standard, pro)
  /// [features] - Custom features map that can contain any application-specific parameters
  /// [metadata] - Optional metadata for the license (e.g., customer info)
  /// [includeSecurityInfo] - Whether to include security algorithm info in metadata (not recommended in production)
  ///
  /// Returns a cryptographically signed License object
  License generateLicense({
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.trial,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
  }) {
    final id = const Uuid().v4();

    // Round creation time to minutes for consistency
    final createdAt = DateTime.now().toUtc().roundToMinutes();

    // Convert expiration date to UTC and round to minutes
    final utcExpirationDate = expirationDate.roundToMinutes();

    // Serialize features and metadata for signing
    final featuresJson = jsonEncode(features);
    final metadataJson = metadata != null ? jsonEncode(metadata) : '';

    // Form data string for signing (including all fields)
    final dataToSign =
        '$id:$appId:${utcExpirationDate.toIso8601String()}:${type.name}:$featuresJson:$metadataJson';

    // Generate the signature based on the key type
    final signature =
        _keyType == LicensifyKeyType.rsa
            ? _generateRsaSignature(dataToSign)
            : _generateEcdsaSignature(dataToSign);

    // Create a copy of metadata without modifying the original
    final extendedMetadata =
        metadata != null
            ? Map<String, dynamic>.from(metadata)
            : <String, dynamic>{};

    // Create the license
    return License(
      id: id,
      appId: appId,
      expirationDate: utcExpirationDate,
      createdAt: createdAt,
      signature: signature,
      type: type,
      features: features,
      metadata: extendedMetadata,
    );
  }

  /// Generates an RSA signature
  String _generateRsaSignature(String dataToSign) {
    // Create RSA signature with the private key
    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(_privateKey.content);
    final signer = RSASigner(_digest, '0609608648016503040203');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signatureBytes = signer.generateSignature(
      Uint8List.fromList(utf8.encode(dataToSign)),
    );
    return base64Encode(signatureBytes.bytes);
  }

  /// Generates an ECDSA signature
  String _generateEcdsaSignature(String dataToSign) {
    try {
      // Parse ECDSA private key from PEM
      final privateKey = CryptoUtils.ecPrivateKeyFromPem(_privateKey.content);

      // Create a secure random number generator
      final secureRandom = FortunaRandom();
      final seedSource = Random.secure();
      final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
      secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

      // Choose the appropriate hashing algorithm for the data
      final digest = _digest;
      final dataBytes = Uint8List.fromList(utf8.encode(dataToSign));
      final hashedData = digest.process(dataBytes);

      // Create ECDSA signer directly - important! Null for Mac algorithm
      final signer = ECDSASigner(digest);

      // Initialize with private key and randomizer
      final params = PrivateKeyParameter<ECPrivateKey>(privateKey);
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
      throw Exception('Failed to generate ECDSA signature: $e');
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

  /// Creates DER sequence for ECDSA signature
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
