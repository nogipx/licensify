// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of '_index.dart';

/// Result of PASETO operations
class PasetoImplementationResult {
  final Map<String, dynamic> payload;
  final String? footer;

  const PasetoImplementationResult({
    required this.payload,
    this.footer,
  });
}

/// Real PASETO v4 implementation using paseto_dart library
///
/// This implementation provides actual cryptographic security using
/// the official PASETO v4 specification with:
/// - v4.public: Ed25519 signatures
/// - v4.local: XChaCha20 encryption + BLAKE2b MAC
abstract interface class _PasetoV4 {
  /// Signs a PASETO v4.public token
  static Future<String> signPublic({
    required Map<String, dynamic> payload,
    required Uint8List privateKeyBytes,
    String? footer,
    String? implicitAssertion,
  }) async {
    try {
      // Create Ed25519 instance
      final ed25519 = Ed25519();

      // Create key pair from private key bytes (seed)
      final keyPair = await ed25519.newKeyPairFromSeed(privateKeyBytes);

      // Create package with JSON payload
      final package = Package(
        content: utf8.encode(jsonEncode(payload)),
        footer: footer != null ? utf8.encode(footer) : null,
      );

      // Sign with PublicV4
      final signedPayload = await PublicV4.sign(
        package,
        keyPair: keyPair,
        implicit:
            implicitAssertion != null ? utf8.encode(implicitAssertion) : null,
      );

      // Create token
      final token = Token(
        header: PublicV4.header,
        payload: signedPayload,
        footer: null,
      );

      return token.toTokenString;
    } catch (e) {
      throw Exception('Failed to sign PASETO v4.public token: $e');
    }
  }

  /// Verifies a PASETO v4.public token
  static Future<PasetoImplementationResult> verifyPublic({
    required String token,
    required Uint8List publicKeyBytes,
    String? implicitAssertion,
  }) async {
    try {
      // Parse token from string
      final receivedToken = await Token.fromString(token);

      // Verify this is a v4.public token
      if (receivedToken.header != PublicV4.header) {
        throw Exception('Token is not v4.public format');
      }

      // Create Ed25519 public key
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );

      // Verify signature using Token.verifyPublicMessage()
      final verified = await receivedToken.verifyPublicMessage(
        publicKey: publicKey,
        implicit:
            implicitAssertion != null ? utf8.encode(implicitAssertion) : null,
      );

      // Decode payload from JSON
      final payloadJson = utf8.decode(verified.package.content);
      final decodedPayload = jsonDecode(payloadJson);

      // Safe type conversion
      final payload = <String, dynamic>{};
      if (decodedPayload is Map) {
        for (final entry in decodedPayload.entries) {
          payload[entry.key.toString()] = entry.value;
        }
      } else {
        throw Exception(
            'Invalid payload format: expected Map, got ${decodedPayload.runtimeType}');
      }

      return PasetoImplementationResult(
        payload: payload,
        footer: verified.package.footer != null
            ? utf8.decode(verified.package.footer!)
            : null,
      );
    } catch (e) {
      throw Exception('Failed to verify PASETO v4.public token: $e');
    }
  }

  /// Encrypts a PASETO v4.local token
  static Future<String> encryptLocal({
    required Map<String, dynamic> payload,
    required Uint8List symmetricKeyBytes,
    String? footer,
    String? implicitAssertion,
  }) async {
    try {
      // Create symmetric key
      final secretKey = SecretKeyData(symmetricKeyBytes);

      // Create package with JSON payload
      final package = Package(
        content: utf8.encode(jsonEncode(payload)),
        footer: footer != null ? utf8.encode(footer) : null,
      );

      // Encrypt with LocalV4 - this returns encrypted payload data
      final encryptedPayload = await LocalV4.encrypt(
        package,
        secretKey: secretKey,
        implicit:
            implicitAssertion != null ? utf8.encode(implicitAssertion) : null,
      );

      // Create token - do NOT set footer to null, use the original package footer
      final token = Token(
        header: LocalV4.header,
        payload: encryptedPayload,
        footer: package.footer, // Use original footer, not null!
      );

      return token.toTokenString;
    } catch (e) {
      throw Exception('Failed to encrypt PASETO v4.local token: $e');
    }
  }

  /// Decrypts a PASETO v4.local token
  static Future<PasetoImplementationResult> decryptLocal({
    required String token,
    required Uint8List symmetricKeyBytes,
    String? footer,
    String? implicitAssertion,
  }) async {
    try {
      // Parse token from string
      final receivedToken = await Token.fromString(token);

      // Verify this is a v4.local token
      if (receivedToken.header != LocalV4.header) {
        throw Exception('Token is not v4.local format');
      }

      // Create symmetric key
      final secretKey = SecretKeyData(symmetricKeyBytes);

      // Decrypt using Token.decryptLocalMessage()
      final decrypted = await receivedToken.decryptLocalMessage(
        secretKey: secretKey,
        implicit:
            implicitAssertion != null ? utf8.encode(implicitAssertion) : null,
      );

      // Decode payload from JSON
      final payloadJson = utf8.decode(decrypted.package.content);
      final decodedPayload = jsonDecode(payloadJson);

      // Safe type conversion
      final payload = <String, dynamic>{};
      if (decodedPayload is Map) {
        for (final entry in decodedPayload.entries) {
          payload[entry.key.toString()] = entry.value;
        }
      } else {
        throw Exception(
            'Invalid payload format: expected Map, got ${decodedPayload.runtimeType}');
      }

      return PasetoImplementationResult(
        payload: payload,
        footer: decrypted.package.footer != null
            ? utf8.decode(decrypted.package.footer!)
            : null,
      );
    } catch (e) {
      throw Exception('Failed to decrypt PASETO v4.local token: $e');
    }
  }

  /// Generates a new Ed25519 key pair for v4.public
  static Future<Map<String, Uint8List>> generateEd25519KeyPair() async {
    try {
      final ed25519 = Ed25519();
      final keyPair = await ed25519.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();

      // Extract seed (private key) - note: Ed25519 uses 32-byte seed
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      final publicKeyBytes = publicKey.bytes;

      return {
        'privateKey': Uint8List.fromList(privateKeyBytes),
        'publicKey': Uint8List.fromList(publicKeyBytes),
      };
    } catch (e) {
      throw Exception('Failed to generate Ed25519 key pair: $e');
    }
  }

  /// Generates a new Ed25519 key pair from existing seed
  static Future<Map<String, Uint8List>> generateEd25519KeyPairFromSeed(
    Uint8List seed,
  ) async {
    try {
      if (seed.length != 32) {
        throw ArgumentError('Ed25519 seed must be exactly 32 bytes');
      }

      final ed25519 = Ed25519();
      final keyPair = await ed25519.newKeyPairFromSeed(seed);
      final publicKey = await keyPair.extractPublicKey();

      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      final publicKeyBytes = publicKey.bytes;

      return {
        'privateKey': Uint8List.fromList(privateKeyBytes),
        'publicKey': Uint8List.fromList(publicKeyBytes),
      };
    } catch (e) {
      throw Exception('Failed to generate Ed25519 key pair from seed: $e');
    }
  }

  /// Validates Ed25519 key bytes
  static void validateEd25519KeyBytes(Uint8List keyBytes, String keyType) {
    if (keyBytes.length != 32) {
      throw ArgumentError('Ed25519 $keyType must be exactly 32 bytes');
    }
  }

  /// Validates XChaCha20 key bytes
  static void validateXChaCha20KeyBytes(Uint8List keyBytes) {
    if (keyBytes.length != 32) {
      throw ArgumentError('XChaCha20 key must be exactly 32 bytes');
    }
  }

  /// Generates a random symmetric key for v4.local (32 bytes)
  static Uint8List generateSymmetricKey() {
    // Generate 32 random bytes for XChaCha20 key
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(32, (i) => random.nextInt(256)),
    );
  }
}
