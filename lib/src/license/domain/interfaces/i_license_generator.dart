// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

abstract interface class ILicenseGenerator {
  License call({
    required String appId,
    required DateTime expirationDate,
    required LicenseType type,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
  });
}
