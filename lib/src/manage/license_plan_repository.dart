// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/src/manage/license_plan.dart';

/// Интерфейс репозитория планов лицензий
///
/// License plan repository interface
abstract class LicensePlanRepository {
  /// Получает все планы
  ///
  /// Gets all plans
  List<LicensePlan> getAll();

  /// Получает план по идентификатору
  ///
  /// Gets a plan by identifier
  LicensePlan? getById(String id);

  /// Сохраняет план
  ///
  /// Saves a plan
  void save(LicensePlan plan);

  /// Удаляет план
  ///
  /// Removes a plan
  bool remove(String id);

  /// Получает публичные планы
  ///
  /// Gets public plans
  List<LicensePlan> getPublicPlans();

  /// Получает пробные планы
  ///
  /// Gets trial plans
  List<LicensePlan> getTrialPlans();

  /// Сериализует все планы в строку
  ///
  /// Serializes all plans to string
  String exportToString();

  /// Загружает планы из строки
  ///
  /// Loads plans from string
  void importFromString(String data);

  /// Экспортирует планы в Base64
  ///
  /// Exports plans to Base64
  String exportToBase64();

  /// Импортирует планы из Base64
  ///
  /// Imports plans from Base64
  void importFromBase64(String base64String);
}
