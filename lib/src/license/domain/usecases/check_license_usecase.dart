// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// Use case for checking license validity
///
/// This class handles verification of license status including signature
/// validation and expiration checks
class CheckLicenseUseCase {
  /// Repository for license storage and retrieval
  final ILicenseRepository _repository;

  /// Validator for cryptographic signature and expiration
  final ILicenseValidator _validator;

  /// Creates a new instance with the specified dependencies
  ///
  /// [repository] - Repository for license storage and retrieval
  /// [validator] - Validator for license integrity and expiration
  const CheckLicenseUseCase({
    required ILicenseRepository repository,
    required ILicenseValidator validator,
  }) : _repository = repository,
       _validator = validator;

  /// Checks the current license in the repository
  ///
  /// Verifies signature and expiration date of the installed license.
  ///
  /// Returns a LicenseStatus indicating the current state:
  /// - ActiveLicenseStatus - License is valid and active
  /// - ExpiredLicenseStatus - License has expired
  /// - InvalidLicenseStatus - License signature is invalid
  /// - NoLicenseStatus - No license is installed
  /// - ErrorLicenseStatus - An error occurred during validation
  Future<LicenseStatus> checkCurrentLicense() async {
    try {
      final license = await _repository.getCurrentLicense();

      if (license == null) {
        return const NoLicenseStatus();
      }

      if (!_validator.validateSignature(license)) {
        return const InvalidLicenseStatus(message: 'Invalid license signature');
      }

      if (!_validator.validateExpiration(license)) {
        return ExpiredLicenseStatus(license);
      }

      return ActiveLicenseStatus(license);
    } catch (e) {
      return ErrorLicenseStatus(
        message: 'Error checking license',
        exception: e,
      );
    }
  }

  /// Checks a license from binary data
  ///
  /// Saves the license from binary data and then verifies its validity.
  ///
  /// [licenseData] - The raw bytes of the license file
  ///
  /// Returns a LicenseStatus indicating the license state
  Future<LicenseStatus> checkLicenseFromBytes(Uint8List licenseData) async {
    try {
      final result = await _repository.saveLicenseFromBytes(licenseData);

      if (!result) {
        return const ErrorLicenseStatus(message: 'Failed to save license');
      }

      return checkCurrentLicense();
    } catch (e) {
      return ErrorLicenseStatus(
        message: 'Error checking license from binary data',
        exception: e,
      );
    }
  }

  /// Checks a license from a file
  ///
  /// Loads the license from the specified file path and verifies its validity.
  ///
  /// [filePath] - Path to the license file
  ///
  /// Returns a LicenseStatus indicating the license state
  Future<LicenseStatus> checkLicenseFromFile(String filePath) async {
    try {
      final result = await _repository.saveLicenseFromFile(filePath);

      if (!result) {
        return const ErrorLicenseStatus(
          message: 'Failed to save license from file',
        );
      }

      return checkCurrentLicense();
    } catch (e) {
      return ErrorLicenseStatus(
        message: 'Error checking license from file',
        exception: e,
      );
    }
  }

  /// Removes the current license
  ///
  /// Returns true if the license was successfully removed, false otherwise
  Future<bool> removeLicense() => _repository.removeLicense();
}
