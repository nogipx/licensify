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
      final key = Licensify.encryptionKeyFromBytes(keyBytes: keyBytes);

      final paserk = Licensify.encryptionKeyToPaserk(key: key);
      expect(paserk, startsWith('k4.local.'));

      final identifier = Licensify.encryptionKeyIdentifier(key: key);
      expect(identifier, startsWith('k4.lid.'));

      final restored = Licensify.encryptionKeyFromPaserk(paserk: paserk);
      expect(restored.keyBytes, equals(keyBytes));
    });

    test('symmetric key password wrapping', () async {
      final keyBytes = List<int>.generate(32, (index) => index * 2 % 256);
      final key = Licensify.encryptionKeyFromBytes(keyBytes: keyBytes);

      final paserk = await Licensify.encryptionKeyToPaserkPassword(
        key: key,
        password: 'S3cure-Passw0rd',
      );

      expect(paserk, startsWith('k4.local-pw.'));

      final restored = await Licensify.encryptionKeyFromPaserkPassword(
        paserk: paserk,
        password: 'S3cure-Passw0rd',
      );

      expect(restored.keyBytes, equals(keyBytes));
    });

    test('symmetric key wrap with another symmetric key', () {
      final keyBytes = List<int>.generate(32, (index) => (index * 7) % 256);
      final wrappingBytes = List<int>.generate(32, (index) => (255 - index));

      final key = Licensify.encryptionKeyFromBytes(keyBytes: keyBytes);
      final wrappingKey =
          Licensify.encryptionKeyFromBytes(keyBytes: wrappingBytes);

      final wrapped = Licensify.encryptionKeyToPaserkWrap(
        key: key,
        wrappingKey: wrappingKey,
      );
      expect(wrapped, startsWith('k4.local-wrap.'));

      final restored = Licensify.encryptionKeyFromPaserkWrap(
        paserk: wrapped,
        wrappingKey: wrappingKey,
      );
      expect(restored.keyBytes, equals(keyBytes));
    });

    test('signing keys to/from PASERK', () {
      final privateBytes = List<int>.generate(32, (index) => index + 1);
      final publicBytes = List<int>.generate(32, (index) => 255 - index);

      final pair = Licensify.keysFromBytes(
        privateKeyBytes: privateBytes,
        publicKeyBytes: publicBytes,
      );

      final paserkSecret = Licensify.signingKeysToPaserk(keyPair: pair);
      expect(paserkSecret, startsWith('k4.secret.'));

      final secretId = Licensify.signingKeyIdentifier(keyPair: pair);
      expect(secretId, startsWith('k4.sid.'));

      final restoredPair =
          Licensify.signingKeysFromPaserk(paserk: paserkSecret);
      final restoredBytes = restoredPair.asBytes;

      expect(restoredBytes.privateKeyBytes, equals(privateBytes));
      expect(restoredBytes.publicKeyBytes, equals(publicBytes));
    });

    test('private key PASERK utilities', () async {
      final privateBytes = List<int>.generate(32, (index) => (index * 5) % 256);
      final publicBytes = List<int>.generate(32, (index) => (150 - index) % 256);

      final privateKey = LicensifyPrivateKey.ed25519(
        keyBytes: Uint8List.fromList(privateBytes),
      );
      final publicKey = LicensifyPublicKey.ed25519(
        keyBytes: Uint8List.fromList(publicBytes),
      );

      final paserkSecret =
          privateKey.toPaserkSecret(publicKey: publicKey);
      expect(paserkSecret, startsWith('k4.secret.'));

      final identifier =
          privateKey.toPaserkSecretIdentifier(publicKey: publicKey);
      expect(identifier, startsWith('k4.sid.'));

      final restoredPrivate = LicensifyPrivateKey.fromPaserkSecret(
        paserk: paserkSecret,
      );
      expect(restoredPrivate.keyBytes, equals(privateBytes));

      final passwordWrapped = await privateKey.toPaserkSecretPassword(
        password: 'Sup3rSecret',
        publicKey: publicKey,
      );
      expect(passwordWrapped, startsWith('k4.secret-pw.'));

      final restoredFromPassword = await LicensifyPrivateKey
          .fromPaserkSecretPassword(
        paserk: passwordWrapped,
        password: 'Sup3rSecret',
      );
      expect(restoredFromPassword.keyBytes, equals(privateBytes));

      final wrappingBytes = List<int>.generate(32, (index) => (index * 9) % 256);
      final wrappingKey =
          Licensify.encryptionKeyFromBytes(keyBytes: wrappingBytes);

      final wrapped = privateKey.toPaserkSecretWrap(
        wrappingKey: wrappingKey,
        publicKey: publicKey,
      );
      expect(wrapped, startsWith('k4.secret-wrap.'));

      final restoredFromWrap = LicensifyPrivateKey.fromPaserkSecretWrap(
        paserk: wrapped,
        wrappingKey: wrappingKey,
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
      final wrappingKey =
          Licensify.encryptionKeyFromBytes(keyBytes: wrappingBytes);

      final wrapped = Licensify.signingKeysToPaserkWrap(
        keyPair: pair,
        wrappingKey: wrappingKey,
      );
      expect(wrapped, startsWith('k4.secret-wrap.'));

      final restored = Licensify.signingKeysFromPaserkWrap(
        paserk: wrapped,
        wrappingKey: wrappingKey,
      );
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
        keyPair: pair,
        password: 'UltraSecret!',
      );

      expect(paserkSecret, startsWith('k4.secret-pw.'));

      final restoredPair = await Licensify.signingKeysFromPaserkPassword(
        paserk: paserkSecret,
        password: 'UltraSecret!',
      );

      final restoredBytes = restoredPair.asBytes;

      expect(restoredBytes.privateKeyBytes, equals(privateBytes));
      expect(restoredBytes.publicKeyBytes, equals(publicBytes));
    });

    test('public key PASERK utilities', () {
      final publicBytes = List<int>.generate(32, (index) => 200 - index);
      final publicKey = LicensifyPublicKey.ed25519(
        keyBytes: Uint8List.fromList(publicBytes),
      );

      final paserkPublic = Licensify.publicKeyToPaserk(key: publicKey);
      expect(paserkPublic, startsWith('k4.public.'));
      expect(Licensify.isPaserk(data: paserkPublic), isTrue);

      final pid = Licensify.publicKeyIdentifier(key: publicKey);
      expect(pid, startsWith('k4.pid.'));

      final restored = Licensify.publicKeyFromPaserk(paserk: paserkPublic);
      expect(restored.keyBytes, equals(publicBytes));
    });

    test('symmetric key sealing and unsealing', () async {
      final encryptionBytes =
          List<int>.generate(32, (index) => (index * 11) % 256);
      final encryptionKey =
          Licensify.encryptionKeyFromBytes(keyBytes: encryptionBytes);

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
        key: encryptionKey,
        publicKey: signingPair.publicKey,
      );

      expect(sealed, startsWith('k4.seal.'));

      final unsealed = await Licensify.encryptionKeyFromPaserkSeal(
        paserk: sealed,
        keyPair: signingPair,
      );

      expect(unsealed.keyBytes, equals(encryptionBytes));
    });
  });
}
