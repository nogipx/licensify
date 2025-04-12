// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import '../_base/_index.dart';

/// Command to show license plan details
class ShowPlanCommand extends BasePlansCommand {
  @override
  String get name => 'plan';

  @override
  String get description => 'Отображение детальной информации о плане';

  ShowPlanCommand() {
    argParser.addOption('id', help: 'Идентификатор плана', mandatory: true);
  }

  @override
  Future<void> run() async {
    final service = await loadPlansService();
    if (service == null) return;

    final planId = argResults!['id'] as String;
    final plan = service.getPlan(planId);

    if (plan == null) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'План не найден',
        'planId': planId,
      });
      print(errorJson);
      return;
    }

    // Подготовка данных плана для вывода
    final planData = {
      'id': plan.id,
      'name': plan.name,
      'description': plan.description,
      'licenseType': plan.licenseType.name,
      'durationDays': plan.durationDays,
      'isPublic': plan.isPublic,
      'priority': plan.priority,
      'price': plan.price,
      'isTrial': plan.isTrial,
      'appId': plan.appId,
    };

    // Добавляем информацию о фичах и метаданных, если они есть
    if (plan.features.isNotEmpty) {
      final features = <String, String>{};
      for (final feature in plan.features) {
        features[feature.key] = feature.schema.type.name;
      }
      planData['features'] = features;
    }

    if (plan.metadata.isNotEmpty) {
      final metadata = <String, String>{};
      for (final meta in plan.metadata) {
        metadata[meta.key] = meta.schema.type.name;
      }
      planData['metadata'] = metadata;
    }

    final outputData = {'status': 'success', 'plan': planData};

    final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
    print(jsonOutput);
  }
}
