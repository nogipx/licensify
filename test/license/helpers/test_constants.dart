// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

// ignore_for_file: unused_element

import 'package:licensify/licensify.dart';

/// Константы и вспомогательные функции для тестирования модуля лицензирования
class TestConstants {
  static final testKeyPair = generateTestKeyPair();

  static LicensifyKeyPair generateTestKeyPair() =>
      EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);

  // Тестовый идентификатор приложения
  static const testAppId = 'com.example.app';

  // Срок действия тестовой лицензии (в днях)
  static const defaultLicenseDuration = 30;
}
