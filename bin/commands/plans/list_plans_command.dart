// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:licensify/src/manage/license_plan.dart';
import '../_base/_index.dart';

/// Command to list license plans
class ListPlansCommand extends BasePlansCommand {
  @override
  String get name => 'list';

  @override
  String get description => 'Просмотр списка планов лицензий';

  ListPlansCommand() {
    argParser.addFlag(
      'all',
      help: 'Показать все планы (включая непубличные)',
      defaultsTo: false,
    );

    argParser.addFlag(
      'trials',
      help: 'Показать только пробные планы',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final service = await loadPlansService();
    if (service == null) return;

    final showAll = argResults!['all'] as bool;
    final showTrials = argResults!['trials'] as bool;
    final currentAppId = service.appId;

    List<LicensePlan> plans;

    if (showTrials) {
      plans = service.getTrialPlans();
    } else if (showAll) {
      plans = service.getAllPlans();
    } else {
      plans = service.getPublicPlans();
    }

    // Всегда фильтруем планы по app-id
    plans = plans.where((plan) => plan.appId == currentAppId).toList();

    // Сортируем по приоритету
    plans.sort((a, b) => a.priority.compareTo(b.priority));

    final category = showTrials ? 'trial' : (showAll ? 'all' : 'public');

    final plansOutput =
        plans
            .map(
              (plan) => {
                'id': plan.id,
                'name': plan.name,
                'description': plan.description,
                'isTrial': plan.isTrial,
                'isPublic': plan.isPublic,
                'durationDays': plan.durationDays,
                'priority': plan.priority,
                'price': plan.price,
                'appId': plan.appId,
              },
            )
            .toList();

    final outputData = {
      'status': 'success',
      'category': category,
      'appId': currentAppId,
      'count': plans.length,
      'plans': plansOutput,
    };

    final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
    print(jsonOutput);
  }
}
