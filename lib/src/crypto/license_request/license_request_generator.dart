// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// License request generator
///
/// Class responsible for creating, encrypting and preparing
/// license request for sending to the server.
class LicenseRequestGenerator implements ILicenseRequestGenerator {
  /// Encrypt data use case
  final EncryptDataUseCase _encryptDataUseCase;

  /// Magic header for identifying the request file
  final String _magicHeader;

  /// Request format version
  final int _formatVersion;

  /// Creates a new license request generator
  ///
  /// [publicKey] - Public key in PEM format for encrypting the request
  /// [magicHeader] - Magic header for identifying the request file
  /// [formatVersion] - Request format version
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  LicenseRequestGenerator({
    required LicensifyPublicKey publicKey,
    String magicHeader = LicenseRequest.magicHeader,
    int formatVersion = 1,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) : _encryptDataUseCase = EncryptDataUseCase(
         publicKey: publicKey,
         aesKeySize: aesKeySize,
         hkdfDigest: hkdfDigest,
         hkdfSalt: hkdfSalt,
         hkdfInfo: hkdfInfo,
       ),
       _magicHeader = magicHeader,
       _formatVersion = formatVersion;

  /// Creates and encrypts a license request
  ///
  /// [deviceHash] - Device hash
  /// [appId] - Application ID
  /// [expirationHours] - Expiration time in hours (default 48 hours)
  ///
  /// Returns encrypted license request bytes.
  @override
  Uint8List call({
    required String deviceHash,
    required String appId,
    int expirationHours = 48,
  }) {
    // Creating the request
    final request = LicenseRequest(
      deviceHash: deviceHash,
      appId: appId,
      createdAt: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(Duration(hours: expirationHours)),
    );

    // Converting to JSON and encrypting
    final jsonData = request.toJsonString();

    // Using the encrypt data use case with magic header
    return _encryptDataUseCase.encryptString(
      data: jsonData,
      magicHeader: _magicHeader,
      formatVersion: _formatVersion,
    );
  }
}
