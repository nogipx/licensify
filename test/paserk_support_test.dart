// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:licensify/licensify.dart';
import 'package:test/test.dart';

void main() {
  group('PASERK k4 support', () {
    test('symmetric key to/from PASERK', () {
      final keyBytes = List<int>.generate(32, (index) => index);
      final key = Licensify.encryptionKeyFromBytes(keyBytes);

      final paserk = Licensify.encryptionKeyToPaserk(key);
      expect(paserk, startsWith('k4.local.'));

      final identifier = Licensify.encryptionKeyIdentifier(key);
      expect(identifier, startsWith('k4.lid.'));

      final restored = Licensify.encryptionKeyFromPaserk(paserk);
      expect(restored.keyBytes, equals(keyBytes));
    });

    test('symmetric key password wrapping', () async {
      final keyBytes = List<int>.generate(32, (index) => index * 2 % 256);
      final key = Licensify.encryptionKeyFromBytes(keyBytes);

      final paserk = await Licensify.encryptionKeyToPaserkPassword(
        key,
        'S3cure-Passw0rd',
      );

      expect(paserk, startsWith('k4.local-pw.'));

      final restored = await Licensify.encryptionKeyFromPaserkPassword(
        paserk,
        'S3cure-Passw0rd',
      );

      expect(restored.keyBytes, equals(keyBytes));
    });

    test('symmetric key wrap with another symmetric key', () {
      final keyBytes = List<int>.generate(32, (index) => (index * 7) % 256);
      final wrappingBytes = List<int>.generate(32, (index) => (255 - index));

      final key = Licensify.encryptionKeyFromBytes(keyBytes);
      final wrappingKey = Licensify.encryptionKeyFromBytes(wrappingBytes);

      final wrapped = Licensify.encryptionKeyToPaserkWrap(key, wrappingKey);
      expect(wrapped, startsWith('k4.local-wrap.'));

      final restored =
          Licensify.encryptionKeyFromPaserkWrap(wrapped, wrappingKey);
      expect(restored.keyBytes, equals(keyBytes));
    });

    test('signing keys to/from PASERK', () {
      final privateBytes = List<int>.generate(32, (index) => index + 1);
      final publicBytes = List<int>.generate(32, (index) => 255 - index);

      final pair = Licensify.keysFromBytes(
        privateKeyBytes: privateBytes,
        publicKeyBytes: publicBytes,
      );

      final paserkSecret = Licensify.signingKeysToPaserk(pair);
      expect(paserkSecret, startsWith('k4.secret.'));

      final secretId = Licensify.signingKeyIdentifier(pair);
      expect(secretId, startsWith('k4.sid.'));

      final restoredPair = Licensify.signingKeysFromPaserk(paserkSecret);
      final restoredBytes = restoredPair.asBytes;

      expect(restoredBytes.privateKeyBytes, equals(privateBytes));
      expect(restoredBytes.publicKeyBytes, equals(publicBytes));
    });

    test('private key PASERK utilities', () async {
      final privateBytes = List<int>.generate(32, (index) => (index * 5) % 256);
      final publicBytes = List<int>.generate(32, (index) => (150 - index) % 256);

      final privateKey = LicensifyPrivateKey.ed25519(
        Uint8List.fromList(privateBytes),
      );
      final publicKey = LicensifyPublicKey.ed25519(
        Uint8List.fromList(publicBytes),
      );

      final paserkSecret = privateKey.toPaserkSecret(publicKey);
      expect(paserkSecret, startsWith('k4.secret.'));

      final identifier = privateKey.toPaserkSecretIdentifier(publicKey);
      expect(identifier, startsWith('k4.sid.'));

      final restoredPrivate = LicensifyPrivateKey.fromPaserkSecret(paserkSecret);
      expect(restoredPrivate.keyBytes, equals(privateBytes));

      final passwordWrapped = await privateKey.toPaserkSecretPassword(
        'Sup3rSecret',
        publicKey: publicKey,
      );
      expect(passwordWrapped, startsWith('k4.secret-pw.'));

      final restoredFromPassword = await LicensifyPrivateKey
          .fromPaserkSecretPassword(passwordWrapped, 'Sup3rSecret');
      expect(restoredFromPassword.keyBytes, equals(privateBytes));

      final wrappingBytes = List<int>.generate(32, (index) => (index * 9) % 256);
      final wrappingKey = Licensify.encryptionKeyFromBytes(wrappingBytes);

      final wrapped = privateKey.toPaserkSecretWrap(
        wrappingKey,
        publicKey: publicKey,
      );
      expect(wrapped, startsWith('k4.secret-wrap.'));

      final restoredFromWrap = LicensifyPrivateKey.fromPaserkSecretWrap(
        wrapped,
        wrappingKey,
      );
      expect(restoredFromWrap.keyBytes, equals(privateBytes));
    });

    test('signing keys symmetric wrapping', () {
      final privateBytes = List<int>.generate(32, (index) => (index + 10));
      final publicBytes = List<int>.generate(32, (index) => (200 - index));
      final wrappingBytes = List<int>.generate(32, (index) => (index * 3) % 256);

      final pair = Licensify.keysFromBytes(
        privateKeyBytes: privateBytes,
        publicKeyBytes: publicBytes,
      );
      final wrappingKey = Licensify.encryptionKeyFromBytes(wrappingBytes);

      final wrapped =
          Licensify.signingKeysToPaserkWrap(pair, wrappingKey);
      expect(wrapped, startsWith('k4.secret-wrap.'));

      final restored =
          Licensify.signingKeysFromPaserkWrap(wrapped, wrappingKey);
      final restoredBytes = restored.asBytes;

      expect(restoredBytes.privateKeyBytes, equals(privateBytes));
      expect(restoredBytes.publicKeyBytes, equals(publicBytes));
    });

    test('signing keys password wrapping', () async {
      final privateBytes = List<int>.generate(32, (index) => 100 + index);
      final publicBytes = List<int>.generate(32, (index) => 200 - index);

      final pair = Licensify.keysFromBytes(
        privateKeyBytes: privateBytes,
        publicKeyBytes: publicBytes,
      );

      final paserkSecret = await Licensify.signingKeysToPaserkPassword(
        pair,
        'UltraSecret!',
      );

      expect(paserkSecret, startsWith('k4.secret-pw.'));

      final restoredPair = await Licensify.signingKeysFromPaserkPassword(
        paserkSecret,
        'UltraSecret!',
      );

      final restoredBytes = restoredPair.asBytes;

      expect(restoredBytes.privateKeyBytes, equals(privateBytes));
      expect(restoredBytes.publicKeyBytes, equals(publicBytes));
    });

    test('public key PASERK utilities', () {
      final publicBytes = List<int>.generate(32, (index) => 200 - index);
      final publicKey = LicensifyPublicKey.ed25519(Uint8List.fromList(publicBytes));

      final paserkPublic = Licensify.publicKeyToPaserk(publicKey);
      expect(paserkPublic, startsWith('k4.public.'));
      expect(Licensify.isPaserk(paserkPublic), isTrue);

      final pid = Licensify.publicKeyIdentifier(publicKey);
      expect(pid, startsWith('k4.pid.'));

      final restored = Licensify.publicKeyFromPaserk(paserkPublic);
      expect(restored.keyBytes, equals(publicBytes));
    });

    test('symmetric key sealing and unsealing', () async {
      final encryptionBytes =
          List<int>.generate(32, (index) => (index * 11) % 256);
      final encryptionKey = Licensify.encryptionKeyFromBytes(encryptionBytes);

      final seed = Uint8List.fromList(
        List<int>.generate(32, (index) => (index + 42) % 256),
      );
      final ed25519 = Ed25519();
      final edKeyPair = await ed25519.newKeyPairFromSeed(seed);
      final privateKeyBytesFull = await edKeyPair.extractPrivateKeyBytes();
      final privateKeyBytes = privateKeyBytesFull.length > 32
          ? Uint8List.fromList(privateKeyBytesFull.sublist(0, 32))
          : Uint8List.fromList(privateKeyBytesFull);
      final publicKeyBytes =
          (await edKeyPair.extractPublicKey()).bytes;

      final signingPair = Licensify.keysFromBytes(
        privateKeyBytes: privateKeyBytes,
        publicKeyBytes: Uint8List.fromList(publicKeyBytes),
      );

      final sealed = await Licensify.encryptionKeyToPaserkSeal(
        encryptionKey,
        signingPair.publicKey,
      );

      expect(sealed, startsWith('k4.seal.'));

      final unsealed = await Licensify.encryptionKeyFromPaserkSeal(
        sealed,
        signingPair,
      );

      expect(unsealed.keyBytes, equals(encryptionBytes));
    });
  });
}
