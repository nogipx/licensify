// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

part of 'package:licensify/licensify.dart';

/// Wrapper for Argon2 salts that ensures PASERK-compatible sizing and
/// provides safe conversions between bytes and base64url strings.
final class LicensifySalt {
  LicensifySalt._(this._bytes);

  /// Constructs a salt from raw [bytes], enforcing the PASERK
  /// [K4LocalPw.saltLength] minimum length.
  factory LicensifySalt.fromBytes({required List<int> bytes}) {
    final copy = Uint8List.fromList(bytes);
    _validateLength(copy.length);
    return LicensifySalt._(copy);
  }

  /// Parses a salt from a base64url [value].
  factory LicensifySalt.fromString({required String value}) {
    final decoded = _decodeBase64Url(value);
    return LicensifySalt.fromBytes(bytes: decoded);
  }

  /// Generates a random salt using `Random.secure()`.
  factory LicensifySalt.random({int length = K4LocalPw.saltLength}) {
    _validateLength(length);

    final random = Random.secure();
    final buffer = Uint8List(length);
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] = random.nextInt(256);
    }
    return LicensifySalt._(buffer);
  }

  final Uint8List _bytes;

  /// Returns a defensive copy of the salt bytes.
  Uint8List asBytes() => Uint8List.fromList(_bytes);

  /// Salt length in bytes.
  int get length => _bytes.length;

  /// Serialises the salt into a base64url string without padding.
  String asString() => _encodeBase64Url(_bytes);

  @override
  String toString() => asString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LicensifySalt) return false;
    if (other._bytes.length != _bytes.length) return false;
    for (var i = 0; i < _bytes.length; i++) {
      if (other._bytes[i] != _bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_bytes);

  static void _validateLength(int length) {
    if (length < K4LocalPw.saltLength) {
      throw ArgumentError(
        'salt must be at least ${K4LocalPw.saltLength} bytes',
      );
    }
  }

  static String _encodeBase64Url(Uint8List bytes) {
    final encoded = base64Url.encode(bytes);
    return encoded.replaceAll('=', '');
  }

  static Uint8List _decodeBase64Url(String value) {
    final padded = value.padRight((value.length + 3) ~/ 4 * 4, '=');
    try {
      return Uint8List.fromList(base64Url.decode(padded));
    } on FormatException {
      throw FormatException('Invalid base64url salt representation');
    }
  }
}
