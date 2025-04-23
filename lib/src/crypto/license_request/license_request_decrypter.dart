// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Decrypter for license requests
///
/// Class that decrypts license requests using a private key.
/// Used on the server side (or license issuer).
class LicenseRequestDecrypter implements ILicenseRequestDecrypter {
  /// Decrypt data use case
  final DecryptDataUseCase _decryptDataUseCase;

  /// Creates a new license request decrypter
  ///
  /// [privateKey] - Private key in PEM format for decryption
  /// [aesKeySize] - Size of AES key in bits (128, 192, or 256)
  /// [hkdfDigest] - Digest algorithm for HKDF (default: SHA256)
  /// [hkdfSalt] - Salt for HKDF key derivation
  /// [hkdfInfo] - Info string for HKDF key derivation
  LicenseRequestDecrypter({
    required LicensifyPrivateKey privateKey,
    int aesKeySize = 256,
    Digest? hkdfDigest,
    String? hkdfSalt,
    String? hkdfInfo,
  }) : _decryptDataUseCase = DecryptDataUseCase(
         privateKey: privateKey,
         aesKeySize: aesKeySize,
         hkdfDigest: hkdfDigest,
         hkdfSalt: hkdfSalt,
         hkdfInfo: hkdfInfo,
       );

  /// Decrypts a license request and returns an object
  ///
  /// [requestBytes] - Encrypted bytes of the license request
  ///
  /// Returns an object [LicenseRequest] with decrypted data.
  /// Throws an exception if the request is in the wrong format or cannot be decrypted.
  @override
  LicenseRequest call(Uint8List requestBytes) {
    // Decrypt with expected magic header
    final jsonString = _decryptDataUseCase.decryptToString(
      encryptedData: requestBytes,
      expectedMagicHeader: LicenseRequest.magicHeader,
    );

    // Convert JSON to license request object
    return LicenseRequest.fromJsonString(jsonString);
  }
}
