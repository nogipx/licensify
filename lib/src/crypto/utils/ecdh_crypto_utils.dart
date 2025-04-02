// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Utility for working with ECDH encryption
abstract interface class ECDHCryptoUtils {
  /// Checks compatibility of elliptic curve domain parameters
  static bool areDomainsCompatible(
    ECDomainParameters domain1,
    ECDomainParameters domain2,
  ) {
    // For compatibility, the following must match: curve, point G, order n
    return domain1.curve.a == domain2.curve.a &&
        domain1.curve.b == domain2.curve.b &&
        domain1.curve.fieldSize == domain2.curve.fieldSize &&
        domain1.G.x == domain2.G.x &&
        domain1.G.y == domain2.G.y &&
        domain1.n == domain2.n;
  }

  /// Pads or trims an array of bytes to the specified length
  static Uint8List padOrTrimBytes(Uint8List bytes, int length) {
    if (bytes.length == length) {
      return bytes;
    } else if (bytes.length > length) {
      // If the array is too long, trim the extra zeros from the left
      return bytes.sublist(bytes.length - length);
    } else {
      // If the array is too short, pad with zeros from the left
      final result = Uint8List(length);
      result.setRange(length - bytes.length, length, bytes);
      return result;
    }
  }

  /// Derives an AES key from the shared secret using HKDF
  static Uint8List deriveAesKey({
    required Uint8List sharedSecret,
    required int aesKeySize,
    required Digest hkdfDigest,
    required String hkdfSalt,
    required String hkdfInfo,
  }) {
    // Use the ready-made HKDFKeyDerivator from PointyCastle
    final hkdf = HKDFKeyDerivator(hkdfDigest);

    // Key length in bytes
    final keyLength = aesKeySize ~/ 8;

    // Parameters for HKDF
    final salt = Uint8List.fromList(utf8.encode(hkdfSalt));
    final info = Uint8List.fromList(utf8.encode(hkdfInfo));
    final params = HkdfParameters(sharedSecret, keyLength, salt, info);

    hkdf.init(params);

    // Get the output of HKDF
    final output = Uint8List(keyLength);
    hkdf.deriveKey(null, 0, output, 0);

    return output;
  }

  /// Serializes an ECDSA public key in the X9.63 format
  static Uint8List serializeEcPublicKey(ECPublicKey publicKey) {
    final q = publicKey.Q!;

    // Get the curve parameters to determine the byte length
    final curveParameters = publicKey.parameters!;
    final fieldSize = (curveParameters.curve.fieldSize + 7) ~/ 8;

    // Use CryptoUtils to convert BigInt to bytes
    final xBytes = padOrTrimBytes(
      _bigIntToBytes(q.x!.toBigInteger()!),
      fieldSize,
    );
    final yBytes = padOrTrimBytes(
      _bigIntToBytes(q.y!.toBigInteger()!),
      fieldSize,
    );

    // X9.63 format: 0x04 | X | Y (uncompressed point)
    return Uint8List.fromList([0x04, ...xBytes, ...yBytes]);
  }

  /// Deserializes an ECDSA public key from the X9.63 format
  static ECPublicKey deserializeEcPublicKey(
    Uint8List bytes,
    ECDomainParameters domain,
  ) {
    // Check format (uncompressed point)
    if (bytes[0] != 0x04) {
      throw ArgumentError('Unsupported key format: ${bytes[0]}');
    }

    // Length of each coordinate
    final halfLength = (bytes.length - 1) ~/ 2;

    // If the coordinate length does not match the curve field size, this is an incorrect format
    final expectedFieldSize = (domain.curve.fieldSize + 7) ~/ 8;
    if (halfLength != expectedFieldSize) {
      throw ArgumentError(
        'Point coordinates size mismatch: expected $expectedFieldSize bytes, got $halfLength bytes. '
        'This likely indicates that the point was encoded for a different curve.',
      );
    }

    // Extract the coordinates X and Y
    final xBytes = bytes.sublist(1, 1 + halfLength);
    final yBytes = bytes.sublist(1 + halfLength);

    // Convert bytes to BigInt
    final x = _bytesToBigInt(xBytes);
    final y = _bytesToBigInt(yBytes);

    try {
      // Create a point on the curve
      final point = domain.curve.createPoint(x, y);
      return ECPublicKey(point, domain);
    } catch (e) {
      throw ArgumentError(
        'Invalid point or incompatible with the curve parameters: ${e.toString()}',
      );
    }
  }

  /// Computes a shared secret using ECDH
  static Uint8List computeSharedSecret(
    ECPrivateKey privateKey,
    ECPublicKey publicKey,
  ) {
    // Check compatibility of curve parameters
    final privateParams = privateKey.parameters!;
    final publicParams = publicKey.parameters!;

    // First check that the domain names match, if they are available
    final privateDomainName = privateParams.domainName;
    final publicDomainName = publicParams.domainName;

    if (privateDomainName != publicDomainName) {
      throw ArgumentError(
        'Incompatible curves: private key uses $privateDomainName, public key uses $publicDomainName',
      );
    }

    // Then check the curve parameters directly
    if (!areDomainsCompatible(privateParams, publicParams)) {
      throw ArgumentError(
        'Incompatible EC domain parameters between private and public keys',
      );
    }

    // The field sizes must match
    if (privateParams.curve.fieldSize != publicParams.curve.fieldSize) {
      throw ArgumentError(
        'Field size mismatch: private key ${privateParams.curve.fieldSize} bits, '
        'public key ${publicParams.curve.fieldSize} bits',
      );
    }

    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey);
    final sharedSecret = agreement.calculateAgreement(publicKey);

    return _bigIntToBytes(sharedSecret);
  }

  /// Encrypts data using AES in CBC mode
  static Uint8List encryptWithAes(Uint8List data, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final params = ParametersWithIV(aesKey, iv);
    final aesCipher = CBCBlockCipher(AESEngine())..init(true, params);

    // Add PKCS7 padding
    final paddedData = _addPkcs7Padding(data, aesCipher.blockSize);

    final result = Uint8List(paddedData.length);

    // Encrypt blocks
    for (
      var offset = 0;
      offset < paddedData.length;
      offset += aesCipher.blockSize
    ) {
      aesCipher.processBlock(paddedData, offset, result, offset);
    }

    return result;
  }

  /// Decrypts data using AES in CBC mode
  static Uint8List decryptWithAes(Uint8List data, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final params = ParametersWithIV(aesKey, iv);
    final aesCipher = CBCBlockCipher(AESEngine())..init(false, params);

    final result = Uint8List(data.length);

    // Decrypt blocks
    for (var offset = 0; offset < data.length; offset += aesCipher.blockSize) {
      aesCipher.processBlock(data, offset, result, offset);
    }

    // Remove PKCS7 padding
    return _removePkcs7Padding(result, aesCipher.blockSize);
  }

  /// Generates a random initialization vector for AES
  static Uint8List generateRandomIv() {
    final secureRandom = FortunaRandom();

    // Initialize the random number generator
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // IV for AES is always 16 bytes (128 bits)
    return secureRandom.nextBytes(16);
  }

  /// Generates a random ECDH key pair
  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateEphemeralKeyPair(
    ECDomainParameters domainParams,
  ) {
    final keyGen = KeyGenerator('EC');
    final random = FortunaRandom();

    // Initialize the random number generator
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Parameters for key generation
    final ecParams = ECKeyGeneratorParameters(domainParams);
    final params = ParametersWithRandom(ecParams, random);

    // Generate a key pair
    keyGen.init(params);
    final keyPair = keyGen.generateKeyPair();

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
      keyPair.publicKey as ECPublicKey,
      keyPair.privateKey as ECPrivateKey,
    );
  }

  // Helper private methods

  /// Converts BigInt to Uint8List
  static Uint8List _bigIntToBytes(BigInt number) {
    // Get the string in hexadecimal format without extra zeros
    final hexString = number.toRadixString(16);

    // If the length is odd, add 0 to the beginning
    final paddedHexString = hexString.length.isOdd ? '0$hexString' : hexString;

    final bytes = <int>[];

    // Convert each pair of characters to a byte
    for (var i = 0; i < paddedHexString.length; i += 2) {
      final byteStr = paddedHexString.substring(i, i + 2);
      final byte = int.parse(byteStr, radix: 16);
      bytes.add(byte);
    }

    return Uint8List.fromList(bytes);
  }

  /// Converts Uint8List to BigInt
  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Adds PKCS7 padding to data
  static Uint8List _addPkcs7Padding(Uint8List data, int blockSize) {
    final padLength = blockSize - (data.length % blockSize);
    final paddedData = Uint8List(data.length + padLength);

    // Copy the original data
    paddedData.setAll(0, data);

    // Add padding
    paddedData.fillRange(data.length, paddedData.length, padLength);

    return paddedData;
  }

  /// Removes PKCS7 padding from data
  static Uint8List _removePkcs7Padding(Uint8List data, int blockSize) {
    final padLength = data[data.length - 1];

    if (padLength > 0 && padLength <= blockSize) {
      final unpaddedLength = data.length - padLength;
      return data.sublist(0, unpaddedLength);
    }

    return data;
  }
}
