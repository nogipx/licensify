// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'dart:convert';

import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

/// Utility for converting ECDSA parameters to PEM format
///
/// Provides methods to create PEM-formatted key strings from
/// raw ECDSA parameters like coordinates and curve information
abstract class EcdsaParamsConverter {
  /// Creates PEM-formatted public key from x and y coordinates and curve name
  ///
  /// [x] - X coordinate as hexadecimal string
  /// [y] - Y coordinate as hexadecimal string
  /// [curveName] - Name of the curve (e.g., 'prime256v1', 'secp256k1')
  ///
  /// Returns PEM string with the public key
  static String publicKeyFromCoordinates({
    required String x,
    required String y,
    required String curveName,
  }) {
    // Convert hex coordinates to BigInt
    final xBigInt = BigInt.parse(_cleanHex(x), radix: 16);
    final yBigInt = BigInt.parse(_cleanHex(y), radix: 16);

    // Create ASN.1 structure
    final asn1Sequence = ASN1Sequence();

    // Add algorithm identifier
    final algorithmSequence = ASN1Sequence();

    // Algorithm ID (1.2.840.10045.2.1 - EC Public Key)
    algorithmSequence.add(ASN1ObjectIdentifier(_ecPublicKeyOid));

    // Curve identifier OID
    algorithmSequence.add(ASN1ObjectIdentifier(_getCurveOid(curveName)));

    asn1Sequence.add(algorithmSequence);

    // Add EC point as bit string
    final point = _encodePoint(xBigInt, yBigInt);
    asn1Sequence.add(ASN1BitString(point));

    // Encode and convert to base64
    final derBytes = asn1Sequence.encodedBytes;
    final base64String = base64.encode(derBytes);

    // Format as PEM
    return _formatPem(base64String, isPrivate: false);
  }

  /// Creates PEM-formatted private key from private scalar and curve name
  ///
  /// [d] - Private key as hexadecimal string
  /// [curveName] - Name of the curve (e.g., 'prime256v1', 'secp256k1')
  ///
  /// Returns PEM string with the private key
  static String privateKeyFromScalar({
    required String d,
    required String curveName,
  }) {
    final dBigInt = BigInt.parse(_cleanHex(d), radix: 16);

    // Create ASN.1 structure for EC private key (RFC 5915)
    final asn1Sequence = ASN1Sequence();

    // Version
    asn1Sequence.add(ASN1Integer(BigInt.one));

    // Private key value
    final privateKeyBytes = _bigIntToBytes(dBigInt);
    asn1Sequence.add(ASN1OctetString(privateKeyBytes));

    // Add curve information (optional)
    final curveOid = _getCurveOid(curveName);

    // Explicit tagging - create a constructed context-specific tag (0)
    final curveOidValue = ASN1ObjectIdentifier(curveOid);
    final params = ASN1Sequence()..add(curveOidValue);
    asn1Sequence.add(params);

    // Encode and convert to base64
    final derBytes = asn1Sequence.encodedBytes;
    final base64String = base64.encode(derBytes);

    // Format as PEM
    return _formatPem(base64String, isPrivate: true);
  }

  /// Calculates public key coordinates from private key and curve
  ///
  /// [d] - Private key as hexadecimal string
  /// [curveName] - Name of the curve
  ///
  /// Returns map with 'x' and 'y' coordinates as hex strings
  static Map<String, String> derivePublicKeyCoordinates({
    required String d,
    required String curveName,
  }) {
    final dBigInt = BigInt.parse(_cleanHex(d), radix: 16);
    final domainParams = _getCurve(curveName);

    // Calculate public key point - safely handle null
    final point = domainParams.G;

    // Явное приведение типа, чтобы убедиться, что у нас ECPoint, а не ECPoint?
    final ECPoint pubPoint = (point * dBigInt) as ECPoint;
    if (pubPoint.x == null || pubPoint.y == null) {
      throw StateError('Invalid point calculation result');
    }

    // Extract coordinates as hex strings
    final bigX = pubPoint.x!.toBigInteger();
    final bigY = pubPoint.y!.toBigInteger();

    if (bigX == null || bigY == null) {
      throw StateError('Could not extract coordinates from point');
    }

    final x = bigX.toRadixString(16);
    final y = bigY.toRadixString(16);

    return {'x': x, 'y': y};
  }

  /// Formats base64 encoded content as PEM
  static String _formatPem(String base64Content, {required bool isPrivate}) {
    final lines = <String>[];
    final headerLine =
        isPrivate
            ? '-----BEGIN EC PRIVATE KEY-----'
            : '-----BEGIN PUBLIC KEY-----';
    final footerLine =
        isPrivate ? '-----END EC PRIVATE KEY-----' : '-----END PUBLIC KEY-----';

    lines.add(headerLine);

    // Split base64 into lines of 64 characters
    for (int i = 0; i < base64Content.length; i += 64) {
      final end = i + 64 < base64Content.length ? i + 64 : base64Content.length;
      lines.add(base64Content.substring(i, end));
    }

    lines.add(footerLine);

    return lines.join('\n');
  }

  /// Encodes EC point in uncompressed format
  static Uint8List _encodePoint(BigInt x, BigInt y) {
    final xBytes = _bigIntToBytes(x);
    final yBytes = _bigIntToBytes(y);

    // Ensure both x and y have the same length
    final fieldSize =
        (xBytes.length > yBytes.length) ? xBytes.length : yBytes.length;
    final paddedX = _padBytes(xBytes, fieldSize);
    final paddedY = _padBytes(yBytes, fieldSize);

    // Create uncompressed point format (04 || x || y)
    final result = Uint8List(1 + fieldSize * 2);
    result[0] = 0x04; // Uncompressed point indicator

    // Copy coordinates
    result.setRange(1, 1 + fieldSize, paddedX);
    result.setRange(1 + fieldSize, 1 + fieldSize * 2, paddedY);

    return result;
  }

  /// Adds leading zeros to ensure the byte array has the desired length
  static Uint8List _padBytes(Uint8List bytes, int length) {
    if (bytes.length >= length) return bytes;

    final result = Uint8List(length);
    result.setRange(length - bytes.length, length, bytes);
    return result;
  }

  /// Converts BigInt to byte array
  static Uint8List _bigIntToBytes(BigInt value) {
    var hex = value.toRadixString(16);
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }

    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }

    return result;
  }

  /// Removes 0x prefix from hex string if present
  static String _cleanHex(String hex) {
    return hex.startsWith('0x') ? hex.substring(2) : hex;
  }

  /// Gets elliptic curve by name
  static ECDomainParameters _getCurve(String curveName) {
    switch (curveName.toLowerCase()) {
      case 'prime256v1':
      case 'p-256':
      case 'secp256r1':
        return ECCurve_prime256v1();
      case 'secp256k1':
        return ECCurve_secp256k1();
      case 'secp384r1':
      case 'p-384':
        return ECCurve_secp384r1();
      case 'secp521r1':
      case 'p-521':
        return ECCurve_secp521r1();
      default:
        throw ArgumentError('Unsupported curve: $curveName');
    }
  }

  // OID for EC Public Key (1.2.840.10045.2.1)
  static final _ecPublicKeyOid = [1, 2, 840, 10045, 2, 1];

  /// Gets OID for a named curve
  static List<int> _getCurveOid(String curveName) {
    switch (curveName.toLowerCase()) {
      case 'prime256v1':
      case 'secp256r1':
      case 'p-256':
        return [1, 2, 840, 10045, 3, 1, 7]; // prime256v1/secp256r1
      case 'secp256k1':
        return [1, 3, 132, 0, 10]; // secp256k1
      case 'secp384r1':
      case 'p-384':
        return [1, 3, 132, 0, 34]; // secp384r1
      case 'secp521r1':
      case 'p-521':
        return [1, 3, 132, 0, 35]; // secp521r1
      default:
        throw ArgumentError('Unsupported curve: $curveName');
    }
  }
}
