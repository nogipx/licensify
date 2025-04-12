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
      print('План с ID "$planId" не найден');
      return;
    }

    // Используем родной метод toJson вместо ручного создания JSON
    final jsonOutput = JsonEncoder.withIndent('  ').convert(plan.toJson());
    print(jsonOutput);
  }
}
