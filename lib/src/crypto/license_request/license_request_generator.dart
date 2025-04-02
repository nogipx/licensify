// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// License request generator
///
/// Class responsible for creating, encrypting and preparing
/// license request for sending to the server.
class LicenseRequestGenerator implements ILicenseRequestGenerator {
  /// Public key for encrypting data
  final LicensifyPublicKey _publicKey;

  /// Encryption key type
  final LicensifyKeyType _keyType;

  /// Magic header for identifying the request file
  final String _magicHeader;

  /// Request format version
  final int _formatVersion;

  /// AES key size in bits
  final int _aesKeySize;

  /// Digest algorithm for HKDF
  final Digest _hkdfDigest;

  /// Salt for HKDF key derivation
  final String _hkdfSalt;

  /// Info string for HKDF key derivation
  final String _hkdfInfo;

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
  }) : _publicKey = publicKey,
       _keyType = publicKey.keyType,
       _magicHeader = magicHeader,
       _formatVersion = formatVersion,
       _aesKeySize = aesKeySize,
       _hkdfDigest = hkdfDigest ?? SHA256Digest(),
       _hkdfSalt = hkdfSalt ?? 'LICENSIFY-ECDH-Salt',
       _hkdfInfo = hkdfInfo ?? 'LICENSIFY-ECDH-AES';

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

    // Encrypting the request
    final encryptedData = _encryptRequest(request);

    // Preparing binary format
    return _formatRequestData(encryptedData);
  }

  /// Encrypts the license request with the public key
  Uint8List _encryptRequest(LicenseRequest request) {
    // Getting JSON string of the request
    final jsonData = request.toJsonString();
    final dataToEncrypt = utf8.encode(jsonData);

    if (_keyType == LicensifyKeyType.rsa) {
      return _encryptWithRsa(dataToEncrypt);
    } else {
      // For ECDSA we cannot encrypt directly, so we use a hybrid approach
      // AES + ECDH
      return _encryptWithEcdh(dataToEncrypt);
    }
  }

  /// Encrypts data with RSA
  Uint8List _encryptWithRsa(Uint8List data) {
    final publicKey = CryptoUtils.rsaPublicKeyFromPem(_publicKey.content);

    // For RSA there are size limitations, so we use OAEP padding
    final encrypter = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    // If the data is too large for one RSA block, we split it into parts
    final blockSize =
        (publicKey.modulus!.bitLength ~/ 8) - 42; // with OAEP padding

    if (data.length <= blockSize) {
      // The data fits into one block
      return encrypter.process(data);
    } else {
      // Generate a random AES key and encrypt the data
      final secureRandom = FortunaRandom();
      final seedSource = Random.secure();
      final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
      secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

      // Generating an AES key
      final aesKeyBytes = secureRandom.nextBytes(32); // 256 bits
      final aesIvBytes = secureRandom.nextBytes(16); // 128 bits

      // Encrypting the data with AES
      // Инициализируем AES шифрование и используем его напрямую
      final aesKey = KeyParameter(aesKeyBytes);
      final params = ParametersWithIV(aesKey, aesIvBytes);
      final aesCipher = CBCBlockCipher(AESEngine())..init(true, params);

      // Добавляем PKCS7 padding
      final paddingSize =
          aesCipher.blockSize - (data.length % aesCipher.blockSize);
      final paddedData = Uint8List(data.length + paddingSize);
      paddedData.setRange(0, data.length, data);
      paddedData.fillRange(data.length, paddedData.length, paddingSize);

      // Выполняем шифрование
      final encryptedData = Uint8List(paddedData.length);
      for (
        var offset = 0;
        offset < paddedData.length;
        offset += aesCipher.blockSize
      ) {
        aesCipher.processBlock(paddedData, offset, encryptedData, offset);
      }

      // Encrypting the AES key with RSA
      final encryptedAesKey = encrypter.process(
        Uint8List.fromList([...aesKeyBytes, ...aesIvBytes]),
      );

      // Combining the encrypted key and encrypted data
      final result =
          BytesBuilder()
            ..add([
              encryptedAesKey.length ~/ 256,
              encryptedAesKey.length % 256,
            ]) // 2 bytes for the key length
            ..add(encryptedAesKey)
            ..add(encryptedData);

      return result.toBytes();
    }
  }

  /// Encrypts data with ECDH + AES
  Uint8List _encryptWithEcdh(Uint8List data) {
    // Используем новый класс ECCipher для шифрования данных
    // Он объединяет в себе генерацию эфемерного ключа, вычисление общего секрета,
    // вывод AES ключа и шифрование данных
    return ECCipher.encryptWithLicensifyKey(
      data: data,
      publicKey: _publicKey,
      aesKeySize: _aesKeySize,
      hkdfDigest: _hkdfDigest,
      hkdfSalt: _hkdfSalt,
      hkdfInfo: _hkdfInfo,
    );
  }

  /// Formats the encrypted data in binary format
  Uint8List _formatRequestData(Uint8List encryptedData) {
    final result = BytesBuilder();

    // Adding the magic header
    result.add(utf8.encode(_magicHeader));

    // Adding the format version (4 bytes, little-endian)
    final versionBytes = Uint8List(4);
    final versionData = ByteData.view(versionBytes.buffer);
    versionData.setUint32(0, _formatVersion, Endian.little);
    result.add(versionBytes);

    // Adding the key type (1 byte)
    result.add([_keyType == LicensifyKeyType.rsa ? 0 : 1]);

    // Adding the encrypted data
    result.add(encryptedData);

    return result.toBytes();
  }
}
