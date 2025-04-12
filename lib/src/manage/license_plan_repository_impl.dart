// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';

import 'package:licensify/src/manage/license_plan.dart';
import 'package:licensify/src/manage/license_plan_repository.dart';

/// Реализация репозитория планов лицензий, хранящая данные в памяти
///
/// In-memory implementation of license plan repository
class InMemoryLicensePlanRepository implements LicensePlanRepository {
  /// Карта планов по идентификатору
  ///
  /// Map of plans by identifier
  final Map<String, LicensePlan> _plans = {};

  /// Идентификатор приложения
  ///
  /// Application identifier
  final String appId;

  /// Создает репозиторий с начальным набором планов
  ///
  /// Creates a repository with an initial set of plans
  InMemoryLicensePlanRepository({
    required this.appId,
    List<LicensePlan> initialPlans = const [],
  }) {
    for (final plan in initialPlans) {
      _plans[plan.id] = plan;
    }
  }

  @override
  List<LicensePlan> getAll() => _plans.values.toList();

  @override
  LicensePlan? getById(String id) => _plans[id];

  @override
  void save(LicensePlan plan) {
    _plans[plan.id] = plan;
  }

  @override
  bool remove(String id) {
    final hadPlan = _plans.containsKey(id);
    _plans.remove(id);
    return hadPlan;
  }

  @override
  List<LicensePlan> getPublicPlans() {
    return _plans.values.where((plan) => plan.isPublic).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  @override
  List<LicensePlan> getTrialPlans() {
    return _plans.values.where((plan) => plan.isTrial).toList();
  }

  @override
  String exportToString() {
    final plansList = getAll().map((plan) => plan.toJson()).toList();
    return jsonEncode(plansList);
  }

  @override
  void importFromString(String data) {
    final json = jsonDecode(data) as List;
    final plans =
        json
            .cast<Map<String, dynamic>>()
            .map((map) => LicensePlan.fromJson(map))
            .toList();

    // Очищаем существующие планы и добавляем новые
    _plans.clear();
    for (final plan in plans) {
      save(plan);
    }
  }

  @override
  String exportToBase64() {
    final jsonStr = exportToString();
    final bytes = utf8.encode(jsonStr);
    return base64.encode(bytes);
  }

  @override
  void importFromBase64(String base64String) {
    final bytes = base64.decode(base64String);
    final jsonString = utf8.decode(bytes);
    importFromString(jsonString);
  }
}
