// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('LicensifyKeyImporter', () {
    late LicensifyKeyPair rsaKeyPair;
    late LicensifyKeyPair ecdsaKeyPair;
    late Uint8List rsaPrivateKeyBytes;
    late Uint8List rsaPublicKeyBytes;
    late Uint8List ecdsaPrivateKeyBytes;
    late Uint8List ecdsaPublicKeyBytes;

    setUpAll(() {
      // Генерируем тестовые ключи
      rsaKeyPair = RsaKeyGenerator.generateKeyPairAsPem();
      ecdsaKeyPair = EcdsaKeyGenerator.generateKeyPairAsPem();

      // Конвертируем строки ключей в байты
      rsaPrivateKeyBytes = Uint8List.fromList(
        utf8.encode(rsaKeyPair.privateKey.content),
      );
      rsaPublicKeyBytes = Uint8List.fromList(
        utf8.encode(rsaKeyPair.publicKey.content),
      );

      ecdsaPrivateKeyBytes = Uint8List.fromList(
        utf8.encode(ecdsaKeyPair.privateKey.content),
      );
      ecdsaPublicKeyBytes = Uint8List.fromList(
        utf8.encode(ecdsaKeyPair.publicKey.content),
      );
    });

    test('Импорт RSA ключей из строк', () {
      // Act
      final privateKey = LicensifyKeyImporter.importPrivateKeyFromString(
        rsaKeyPair.privateKey.content,
      );
      final publicKey = LicensifyKeyImporter.importPublicKeyFromString(
        rsaKeyPair.publicKey.content,
      );

      // Assert
      expect(privateKey.keyType, equals(LicensifyKeyType.rsa));
      expect(publicKey.keyType, equals(LicensifyKeyType.rsa));
      expect(privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт пары RSA ключей из строк', () {
      // Act
      final keyPair = LicensifyKeyImporter.importKeyPairFromStrings(
        privateKeyPem: rsaKeyPair.privateKey.content,
        publicKeyPem: rsaKeyPair.publicKey.content,
      );

      // Assert
      expect(keyPair.keyType, equals(LicensifyKeyType.rsa));
      expect(keyPair.isConsistent, isTrue);
      expect(keyPair.privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(keyPair.publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт RSA ключей из байтов', () {
      // Act
      final privateKey = LicensifyKeyImporter.importPrivateKeyFromBytes(
        rsaPrivateKeyBytes,
      );
      final publicKey = LicensifyKeyImporter.importPublicKeyFromBytes(
        rsaPublicKeyBytes,
      );

      // Assert
      expect(privateKey.keyType, equals(LicensifyKeyType.rsa));
      expect(publicKey.keyType, equals(LicensifyKeyType.rsa));
      expect(privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт пары RSA ключей из байтов', () {
      // Act
      final keyPair = LicensifyKeyImporter.importKeyPairFromBytes(
        privateKeyBytes: rsaPrivateKeyBytes,
        publicKeyBytes: rsaPublicKeyBytes,
      );

      // Assert
      expect(keyPair.keyType, equals(LicensifyKeyType.rsa));
      expect(keyPair.isConsistent, isTrue);
      expect(keyPair.privateKey.content, equals(rsaKeyPair.privateKey.content));
      expect(keyPair.publicKey.content, equals(rsaKeyPair.publicKey.content));
    });

    test('Импорт ECDSA ключей из байтов', () {
      // Act
      final privateKey = LicensifyKeyImporter.importPrivateKeyFromBytes(
        ecdsaPrivateKeyBytes,
      );
      final publicKey = LicensifyKeyImporter.importPublicKeyFromBytes(
        ecdsaPublicKeyBytes,
      );

      // Assert
      expect(privateKey.keyType, equals(LicensifyKeyType.ecdsa));
      expect(publicKey.keyType, equals(LicensifyKeyType.ecdsa));
      expect(privateKey.content, equals(ecdsaKeyPair.privateKey.content));
      expect(publicKey.content, equals(ecdsaKeyPair.publicKey.content));
    });

    test('Импорт пары ECDSA ключей из байтов', () {
      // Act
      final keyPair = LicensifyKeyImporter.importKeyPairFromBytes(
        privateKeyBytes: ecdsaPrivateKeyBytes,
        publicKeyBytes: ecdsaPublicKeyBytes,
      );

      // Assert
      expect(keyPair.keyType, equals(LicensifyKeyType.ecdsa));
      expect(keyPair.isConsistent, isTrue);
    });

    test('Ошибка при несовместимых типах ключей', () {
      // Act & Assert
      expect(
        () => LicensifyKeyImporter.importKeyPairFromStrings(
          privateKeyPem: rsaKeyPair.privateKey.content,
          publicKeyPem: ecdsaKeyPair.publicKey.content,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LicensifyKeyImporter.importKeyPairFromBytes(
          privateKeyBytes: rsaPrivateKeyBytes,
          publicKeyBytes: ecdsaPublicKeyBytes,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Ошибка при неверном формате ключа', () {
      // Act & Assert
      expect(
        () =>
            LicensifyKeyImporter.importPrivateKeyFromString('not a valid key'),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LicensifyKeyImporter.importPublicKeyFromString(''),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => LicensifyKeyImporter.importPrivateKeyFromBytes(
          Uint8List.fromList(utf8.encode('not a valid key')),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
