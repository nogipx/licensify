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

  /// Creates a new license request generator
  ///
  /// [publicKey] - Public key in PEM format for encrypting the request
  /// [magicHeader] - Magic header for identifying the request file
  /// [formatVersion] - Request format version
  LicenseRequestGenerator({
    required LicensifyPublicKey publicKey,
    String magicHeader = 'MLRQ',
    int formatVersion = 1,
  }) : _publicKey = publicKey,
       _keyType = publicKey.keyType,
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
      final aesKey = KeyParameter(aesKeyBytes);
      final params = ParametersWithIV(aesKey, aesIvBytes);
      final aesCipher = CBCBlockCipher(AESEngine())..init(true, params);

      // Padding the data to the block size
      final paddedData = _padData(data, aesCipher.blockSize);
      final encryptedData = _processBlocks(aesCipher, paddedData);

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
    // Creating an ephemeral key pair for exchange
    final ephemeralKeyPair = _generateEphemeralKeyPair();

    // Getting the ECDSA public key from PEM
    final ecdsaPublicKey = CryptoUtils.ecPublicKeyFromPem(_publicKey.content);

    // Calculating the shared secret using ECDH
    final sharedSecret = _computeSharedSecret(
      ephemeralKeyPair.privateKey,
      ecdsaPublicKey,
    );

    // Generating a symmetric key from the shared secret
    final aesKey = _deriveAesKey(sharedSecret);
    final aesIv = _generateRandomIv();

    // Encrypting the data with AES
    final encryptedData = _encryptWithAes(data, aesKey, aesIv);

    // Serializing the ephemeral public key
    final ephemeralPublicKeyBytes = _serializeEcPublicKey(
      ephemeralKeyPair.publicKey,
    );

    // Collecting everything together: ephemeral public key + IV + encrypted data
    final result =
        BytesBuilder()
          ..add([
            ephemeralPublicKeyBytes.length ~/ 256,
            ephemeralPublicKeyBytes.length % 256,
          ]) // 2 bytes for the key length
          ..add(ephemeralPublicKeyBytes)
          ..add(aesIv)
          ..add(encryptedData);

    return result.toBytes();
  }

  /// Generates an ephemeral ECDH key pair for one-time use
  AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _generateEphemeralKeyPair() {
    final keyGen = KeyGenerator('EC');
    final random = FortunaRandom();

    // Initializing the random generator
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Defining the curve parameters (using the same as in the public key)
    final domainParams = ECDomainParameters('secp256r1'); // P-256

    // Parameters for key generation
    final ecParams = ECKeyGeneratorParameters(domainParams);
    final params = ParametersWithRandom(ecParams, random);

    // Generating the key pair
    keyGen.init(params);
    final keyPair = keyGen.generateKeyPair();

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
      keyPair.publicKey as ECPublicKey,
      keyPair.privateKey as ECPrivateKey,
    );
  }

  /// Calculates the shared secret using ECDH
  Uint8List _computeSharedSecret(
    ECPrivateKey privateKey,
    ECPublicKey publicKey,
  ) {
    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey);
    final sharedSecret = agreement.calculateAgreement(publicKey);

    // Converting BigInt to bytes
    return _bigIntToBytes(sharedSecret);
  }

  /// Converts BigInt to Uint8List
  Uint8List _bigIntToBytes(BigInt number) {
    final hexString = number.toRadixString(16).padLeft(64, '0');
    final bytes = <int>[];

    for (var i = 0; i < hexString.length; i += 2) {
      final byte = int.parse(hexString.substring(i, i + 2), radix: 16);
      bytes.add(byte);
    }

    return Uint8List.fromList(bytes);
  }

  /// Derives an AES key from the shared secret using HKDF
  Uint8List _deriveAesKey(Uint8List sharedSecret) {
    // Own implementation of HKDF (RFC 5869)
    // Step 1: Extraction
    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(
      KeyParameter(Uint8List.fromList(utf8.encode('LICENSIFY-ECDH-Salt'))),
    );
    final prk = hmac.process(sharedSecret); // PRK = HMAC-Hash(salt, IKM)

    // Step 2: Extension
    hmac.init(KeyParameter(prk));
    final info = Uint8List.fromList(utf8.encode('LICENSIFY-ECDH-AES'));
    final t = hmac.process(Uint8List.fromList([...info, 1]));

    // Returning the first 32 bytes (256 bits for AES-256)
    return t.sublist(0, 32);
  }

  /// Generates a random initialization vector for AES
  Uint8List _generateRandomIv() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom.nextBytes(16); // 128 бит
  }

  /// Encrypts data with AES in CBC mode
  Uint8List _encryptWithAes(Uint8List data, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final params = ParametersWithIV(aesKey, iv);
    final aesCipher = CBCBlockCipher(AESEngine())..init(true, params);

    // Padding the data to the block size
    final paddedData = _padData(data, aesCipher.blockSize);

    return _processBlocks(aesCipher, paddedData);
  }

  /// Pads the data to the block size (PKCS7 padding)
  Uint8List _padData(Uint8List data, int blockSize) {
    final padLength = blockSize - (data.length % blockSize);
    final paddedData = Uint8List(data.length + padLength);

    // Copying the original data
    paddedData.setAll(0, data);

    // Adding padding
    paddedData.fillRange(data.length, paddedData.length, padLength);

    return paddedData;
  }

  /// Processes data by blocks using BlockCipher
  Uint8List _processBlocks(BlockCipher cipher, Uint8List data) {
    final result = Uint8List(data.length);

    for (var offset = 0; offset < data.length; offset += cipher.blockSize) {
      cipher.processBlock(data, offset, result, offset);
    }

    return result;
  }

  /// Serializes the ECDSA public key in X9.63 format
  Uint8List _serializeEcPublicKey(ECPublicKey publicKey) {
    final q = publicKey.Q!;
    final xBytes = _bigIntToBytes(q.x!.toBigInteger()!).sublist(32 - 32);
    final yBytes = _bigIntToBytes(q.y!.toBigInteger()!).sublist(32 - 32);

    // X9.63 format: 0x04 | X | Y (uncompressed point)
    return Uint8List.fromList([0x04, ...xBytes, ...yBytes]);
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
