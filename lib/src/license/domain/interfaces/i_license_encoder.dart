// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

abstract interface class ILicenseEncoder {
  Uint8List encodeToBytes(License license);

  License decodeFromBytes(Uint8List bytes);

  bool isValidLicenseBytes(Uint8List bytes);
}
