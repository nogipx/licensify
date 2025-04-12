// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import '../_base/_index.dart';

/// Command to remove a license plan
class RemovePlanCommand extends BasePlansCommand {
  @override
  String get name => 'remove';

  @override
  String get description => 'Удаление плана лицензии';

  RemovePlanCommand() {
    argParser.addOption(
      'id',
      help: 'Идентификатор плана для удаления',
      mandatory: true,
    );

    argParser.addFlag(
      'force',
      abbr: 'F',
      help: 'Удалить план без подтверждения',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final service = await loadPlansService();
    if (service == null) return;

    final planId = argResults!['id'] as String;
    final force = argResults!['force'] as bool;

    // Проверяем существование плана
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

    // Запрашиваем подтверждение, если не указан флаг force
    if (!force) {
      final confirmJson = JsonEncoder.withIndent('  ').convert({
        'status': 'confirm',
        'message': 'Подтвердите удаление плана',
        'plan': {'id': plan.id, 'name': plan.name},
      });
      print(confirmJson);

      stdout.write('Подтвердите удаление (y/n): ');
      final response = stdin.readLineSync()?.toLowerCase();

      if (response != 'y' && response != 'yes') {
        final cancelJson = JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'cancelled', 'message': 'Операция отменена'});
        print(cancelJson);
        return;
      }
    }

    final result = service.removePlan(planId);

    if (result.success) {
      final successJson = JsonEncoder.withIndent('  ').convert({
        'status': 'success',
        'message': result.message,
        'planId': planId,
      });
      print(successJson);
      await savePlans(service);
    } else {
      final errorJson = JsonEncoder.withIndent(
        '  ',
      ).convert({'status': 'error', 'message': result.message});
      print(errorJson);
    }
  }
}
