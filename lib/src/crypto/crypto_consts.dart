// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Supported ECDSA curves
enum EcCurve {
  /// NIST P-256 (secp256r1) - 128-bit security
  p256('secp256r1'),

  /// NIST P-384 (secp384r1) - 192-bit security
  p384('secp384r1'),

  /// NIST P-521 (secp521r1) - 256-bit security
  p521('secp521r1'),

  /// secp256k1 (Bitcoin/Ethereum curve) - 128-bit security
  secp256k1('secp256k1');

  /// Technical name of the curve
  final String name;

  /// Constructor
  const EcCurve(this.name);
}

/// Secure random algorithm to use
enum SecureRandomAlgorithm {
  /// Fortuna algorithm (recommended for most use cases)
  fortuna,

  /// Block cipher in CTR mode
  blockCtr,

  /// Block cipher in CTR mode with auto reseed
  autoSeedBlockCtr,
}
