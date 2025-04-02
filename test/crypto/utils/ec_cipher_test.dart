// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';
import 'package:test/test.dart';

void main() {
  group('ECCipher', () {
    late LicensifyKeyPair keyPair;
    late Uint8List testData;

    setUp(() {
      // Generate a key pair for testing
      keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);

      // Create test data
      testData = Uint8List.fromList(
        utf8.encode(
          'Это тестовое сообщение для шифрования и дешифрования с помощью EC ключей',
        ),
      );
    });

    test('encrypt and decrypt with PEM keys', () {
      // Encrypt data using public key
      final encrypted = ECCipher.encrypt(
        data: testData,
        publicKeyPem: keyPair.publicKey.content,
      );

      // Check that encrypted data is different from original
      expect(encrypted, isNot(equals(testData)));

      // Decrypt data using private key
      final decrypted = ECCipher.decrypt(
        encryptedData: encrypted,
        privateKeyPem: keyPair.privateKey.content,
      );

      // Check that decrypted data matches original
      expect(decrypted, equals(testData));
      expect(utf8.decode(decrypted), equals(utf8.decode(testData)));
    });

    test('encrypt and decrypt with LicensifyKey objects', () {
      // Encrypt data using LicensifyPublicKey
      final encrypted = ECCipher.encryptWithLicensifyKey(
        data: testData,
        publicKey: keyPair.publicKey,
      );

      // Check that encrypted data is different from original
      expect(encrypted, isNot(equals(testData)));

      // Decrypt data using LicensifyPrivateKey
      final decrypted = ECCipher.decryptWithLicensifyKey(
        encryptedData: encrypted,
        privateKey: keyPair.privateKey,
      );

      // Check that decrypted data matches original
      expect(decrypted, equals(testData));
    });

    test('encrypt and decrypt with custom AES key size', () {
      // Encrypt data with 128-bit AES key
      final encrypted = ECCipher.encryptWithLicensifyKey(
        data: testData,
        publicKey: keyPair.publicKey,
        aesKeySize: 128,
      );

      // Decrypt data with same parameters
      final decrypted = ECCipher.decryptWithLicensifyKey(
        encryptedData: encrypted,
        privateKey: keyPair.privateKey,
        aesKeySize: 128,
      );

      // Check that decrypted data matches original
      expect(decrypted, equals(testData));
    });

    test('encrypt and decrypt with custom HKDF parameters', () {
      // Custom parameters
      const customSalt = 'CustomSaltForTest';
      const customInfo = 'CustomInfoForTest';

      // Encrypt data with custom parameters
      final encrypted = ECCipher.encryptWithLicensifyKey(
        data: testData,
        publicKey: keyPair.publicKey,
        hkdfSalt: customSalt,
        hkdfInfo: customInfo,
      );

      // Trying to decrypt with wrong salt should fail
      expect(
        () => ECCipher.decryptWithLicensifyKey(
          encryptedData: encrypted,
          privateKey: keyPair.privateKey,
          hkdfSalt: 'WrongSalt',
        ),
        throwsA(isA<FormatException>()),
      );

      // Trying to decrypt with wrong info should fail
      expect(
        () => ECCipher.decryptWithLicensifyKey(
          encryptedData: encrypted,
          privateKey: keyPair.privateKey,
          hkdfInfo: 'WrongInfo',
        ),
        throwsA(isA<FormatException>()),
      );

      // Decrypt with correct custom parameters
      final decrypted = ECCipher.decryptWithLicensifyKey(
        encryptedData: encrypted,
        privateKey: keyPair.privateKey,
        hkdfSalt: customSalt,
        hkdfInfo: customInfo,
      );

      // Check that decrypted data matches original
      expect(decrypted, equals(testData));
    });

    test('encrypt with one curve and decrypt with another should fail', () {
      // Generate a key pair with a different curve
      final anotherKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem(
        curve: EcCurve.p384, // Different curve
      );

      // Encrypt data with the original public key
      final encrypted = ECCipher.encryptWithLicensifyKey(
        data: testData,
        publicKey: keyPair.publicKey,
      );

      // Try to decrypt with a private key from a different pair/curve
      expect(
        () => ECCipher.decryptWithLicensifyKey(
          encryptedData: encrypted,
          privateKey: anotherKeyPair.privateKey,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('encrypt large data', () {
      // Create large test data (100 KB)
      final largeData = Uint8List(100 * 1024);
      for (var i = 0; i < largeData.length; i++) {
        largeData[i] = i % 256;
      }

      // Encrypt large data
      final encrypted = ECCipher.encryptWithLicensifyKey(
        data: largeData,
        publicKey: keyPair.publicKey,
      );

      // Decrypt large data
      final decrypted = ECCipher.decryptWithLicensifyKey(
        encryptedData: encrypted,
        privateKey: keyPair.privateKey,
      );

      // Check that decrypted data matches original
      expect(decrypted, equals(largeData));
    });
  });
}
