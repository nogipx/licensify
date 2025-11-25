// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

import 'package:licensify/licensify.dart';
import 'package:test/test.dart';

void main() {
  group('PASETO v4.public helpers', () {
    test('signs and verifies tokens with PASERK keys and footer', () async {
      final keyPair = await Licensify.generateSigningKeys();
      final paserkSecret = Licensify.signingKeysToPaserk(keyPair: keyPair);
      final paserkPublic = Licensify.publicKeyToPaserk(key: keyPair.publicKey);

      final privateKey = LicensifyPrivateKey.fromPaserkSecret(
        paserk: paserkSecret,
      );
      final publicKey = LicensifyPublicKey.fromPaserk(
        paserk: paserkPublic,
      );

      const implicit = 'licensify:test';
      final payload = {
        'user': 'demo',
        'scopes': ['read', 'write'],
        'meta': {'tier': 'gold'},
      };

      try {
        final token = await Licensify.signPublicToken(
          payload: payload,
          privateKey: privateKey,
          footer: 'k4.pid:${Licensify.publicKeyIdentifier(key: publicKey)}',
          implicitAssertion: implicit,
        );

        expect(token.startsWith('v4.public.'), isTrue);

        final result = await Licensify.verifyPublicToken(
          token: token,
          publicKey: publicKey,
          implicitAssertion: implicit,
        );

        expect(result['user'], equals('demo'));
        expect(result['scopes'], equals(['read', 'write']));
        expect(
          (result['meta'] as Map<String, dynamic>)['tier'],
          equals('gold'),
        );
        expect(result['_footer'], startsWith('k4.pid:'));
      } finally {
        keyPair.privateKey.dispose();
        keyPair.publicKey.dispose();
        privateKey.dispose();
        publicKey.dispose();
      }
    });

    test('rejects tokens signed by another public key', () async {
      final issuerKeys = await Licensify.generateSigningKeys();
      final verifierKeys = await Licensify.generateSigningKeys();

      try {
        final token = await Licensify.signPublicToken(
          payload: {'id': 1},
          privateKey: issuerKeys.privateKey,
        );

        expect(
          () => Licensify.verifyPublicToken(
            token: token,
            publicKey: verifierKeys.publicKey,
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        issuerKeys.privateKey.dispose();
        issuerKeys.publicKey.dispose();
        verifierKeys.privateKey.dispose();
        verifierKeys.publicKey.dispose();
      }
    });

    test('throws for non v4.public tokens', () async {
      final encryptionKey = Licensify.generateEncryptionKey();
      final verifierKeys = await Licensify.generateSigningKeys();

      try {
        final token = await Licensify.encryptData(
          data: {'message': 'hi'},
          encryptionKey: encryptionKey,
        );

        expect(
          () => Licensify.verifyPublicToken(
            token: token,
            publicKey: verifierKeys.publicKey,
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        encryptionKey.dispose();
        verifierKeys.privateKey.dispose();
        verifierKeys.publicKey.dispose();
      }
    });

    test('fails verification when implicit assertion mismatches', () async {
      final keys = await Licensify.generateSigningKeys();

      try {
        final token = await Licensify.signPublicToken(
          payload: {'test': true},
          privateKey: keys.privateKey,
          implicitAssertion: 'expected',
        );

        expect(
          () => Licensify.verifyPublicToken(
            token: token,
            publicKey: keys.publicKey,
            implicitAssertion: 'other',
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        keys.privateKey.dispose();
        keys.publicKey.dispose();
      }
    });
  });
}
