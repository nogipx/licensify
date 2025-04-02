// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

abstract interface class ILicenseRequestGenerator {
  Uint8List call({
    required String deviceHash,
    required String appId,
    int expirationHours = 48,
  });
}
