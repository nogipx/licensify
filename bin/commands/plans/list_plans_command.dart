// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:licensify/src/manage/license_plan.dart';
import '../_base/_index.dart';

/// Command to list license plans
class ListPlansCommand extends BasePlansCommand {
  @override
  String get name => 'ls';

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

    final showAll = argResults!['all'] == true;
    final showTrials = argResults!['trials'] == true;

    List<LicensePlan> plans = service.getAllPlans();

    // Фильтруем планы по appId
    plans = plans.where((plan) => plan.appId == service.appId).toList();

    // Применяем фильтры
    if (!showAll) {
      plans = plans.where((plan) => plan.isPublic).toList();
    }

    // Если указан флаг --trials, показываем только trial-планы
    if (showTrials) {
      plans = plans.where((plan) => plan.isTrial).toList();
    }

    // Сортируем планы по приоритету
    plans.sort((a, b) => a.priority.compareTo(b.priority));

    // Формируем вывод в JSON
    final category =
        showTrials
            ? 'trial plans'
            : showAll
            ? 'all plans'
            : 'public plans';

    final output = {
      'status': 'success',
      'message': 'Список планов',
      'data': {
        'category': category,
        'appId': service.appId,
        'count': plans.length,
        'plans': plans.map((plan) => plan.toJson()).toList(),
      },
    };

    final jsonOutput = JsonEncoder.withIndent('  ').convert(output);
    print(jsonOutput);
  }
}
