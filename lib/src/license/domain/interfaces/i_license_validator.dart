// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Interface for license validation operations
///
/// Implementations of this interface handle verification of license
/// authenticity and expiration status.
abstract interface class ILicenseValidator {
  /// Validates the cryptographic signature of a license
  ///
  /// Returns true if the signature is valid, false otherwise
  bool validateSignature(License license);

  /// Checks if the license is still within its valid time period
  ///
  /// Returns true if the license has not expired, false otherwise
  bool validateExpiration(License license);

  /// Performs complete license validation (both signature and expiration)
  ///
  /// Returns true only if both the signature is valid and the license has not expired
  bool validateLicense(License license);
}
