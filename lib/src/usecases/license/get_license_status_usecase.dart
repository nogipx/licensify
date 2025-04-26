// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

class GetLicenseStatusUseCase {
  final ILicenseValidator _licenseValidator;
  final IDeviceHashGenerator? _deviceHashGenerator;

  GetLicenseStatusUseCase({
    required ILicenseValidator licenseValidator,
    IDeviceHashGenerator? deviceHashGenerator,
  }) : _licenseValidator = licenseValidator,
       _deviceHashGenerator = deviceHashGenerator;

  Future<LicenseStatus> call(License? license, {LicenseSchema? schema}) async {
    if (license == null) {
      return NoLicenseStatus();
    }

    if (!_licenseValidator.validateSignature(license).isValid) {
      return InvalidLicenseSignatureStatus();
    }

    if (!_licenseValidator.validateExpiration(license).isValid) {
      return ExpiredLicenseStatus(license);
    }

    if (_deviceHashGenerator != null) {
      final deviceHash = await _deviceHashGenerator();
      if (license.metadata?['deviceHash'] != deviceHash) {
        return InvalidLicenseDeviceHashStatus();
      }
    }

    if (schema != null) {
      final schemaResult = _licenseValidator.validateSchema(license, schema);
      if (!schemaResult.isValid) {
        return InvalidLicenseSchemaStatus(schemaResult);
      }
    }

    return ActiveLicenseStatus(license);
  }
}
