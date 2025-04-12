// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'package:licensify/src/manage/license_plan_service.dart';

import '../_base/_index.dart';

/// Command to import license plans
class ImportPlansCommand extends BasePlansCommand {
  @override
  String get name => 'import';

  @override
  String get description => 'Импорт планов лицензий';

  ImportPlansCommand() {
    argParser.addOption(
      'input',
      abbr: 'i',
      help: 'Путь к файлу для импорта',
      mandatory: true,
    );

    argParser.addFlag(
      'base64',
      help: 'Импорт из формата Base64',
      defaultsTo: false,
    );

    argParser.addFlag(
      'merge',
      help: 'Объединить с существующими планами',
      defaultsTo: true,
    );

    argParser.addFlag(
      'force',
      abbr: 'F',
      help: 'Импортировать без подтверждения перезаписи существующих планов',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final service = await loadPlansService();
    if (service == null) return;

    final inputPath = argResults!['input'] as String;
    final isBase64 = argResults!['base64'] as bool;
    final merge = argResults!['merge'] as bool;
    final force = argResults!['force'] as bool;

    final file = File(inputPath);
    if (!await file.exists()) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Файл не найден',
        'path': inputPath,
      });
      print(errorJson);
      return;
    }

    // Проверяем, есть ли существующие планы и нужно ли их сохранять
    final existingPlans = service.getAllPlans();
    final hasExistingPlans = existingPlans.isNotEmpty;

    if (hasExistingPlans && !merge && !force) {
      final confirmJson = JsonEncoder.withIndent('  ').convert({
        'status': 'confirm',
        'message': 'Существующие планы будут удалены',
        'plansCount': existingPlans.length,
      });
      print(confirmJson);

      stdout.write('Продолжить? (y/n): ');
      final response = stdin.readLineSync()?.toLowerCase();

      if (response != 'y' && response != 'yes') {
        final cancelJson = JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'cancelled', 'message': 'Операция отменена'});
        print(cancelJson);
        return;
      }
    }

    try {
      final data = await file.readAsString();

      PlanOperationResult<void> result;
      if (isBase64) {
        result = service.importFromBase64(data);
      } else {
        result = service.importFromString(data);
      }

      if (result.success) {
        final plansAfterImport = service.getAllPlans();

        final successJson = JsonEncoder.withIndent('  ').convert({
          'status': 'success',
          'message': result.message,
          'plansCount': plansAfterImport.length,
          'inputFile': inputPath,
          'format': isBase64 ? 'base64' : 'json',
          'mode': merge ? 'merge' : 'replace',
        });
        print(successJson);

        await savePlans(service);
      } else {
        final errorJson = JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'error', 'message': result.message});
        print(errorJson);
      }
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка при импорте планов',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
