// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

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
  });
}
