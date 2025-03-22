// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// Интерфейс для валидации лицензии
abstract class ILicenseValidator {
  /// Проверяет подпись лицензии
  bool validateSignature(License license);

  /// Проверяет срок действия лицензии
  bool validateExpiration(License license);

  /// Полная проверка лицензии (подпись и срок действия)
  bool validateLicense(License license);
}
