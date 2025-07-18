// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert' show utf8, base64, jsonDecode, jsonEncode;
import 'dart:math' show Random;
import 'dart:typed_data' show Uint8List;
import 'package:uuid/uuid.dart' show Uuid;
import 'package:paseto_dart/paseto_dart.dart';

part 'src/crypto/license_generator.dart';
part 'src/crypto/license_validator.dart';
part 'src/crypto/licensify_symmetric_crypto.dart';
part 'src/crypto/paseto_v4.dart';

part 'src/crypto/keys/key_base.dart';
part 'src/crypto/keys/licensify_key_pair.dart';
part 'src/crypto/keys/licensify_private_key.dart';
part 'src/crypto/keys/licensify_public_key.dart';
part 'src/crypto/keys/licensify_symmetric_key.dart';

part 'src/license/license_exception.dart';
part 'src/license/license_status.dart';
part 'src/license/license_type.dart';
part 'src/license/license_validation_result.dart';
part 'src/license/license.dart';

part 'src/licensify.dart';
