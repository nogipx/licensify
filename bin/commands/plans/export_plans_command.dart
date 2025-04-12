// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import '../_base/_index.dart';

/// Command to export license plans
class ExportPlansCommand extends BasePlansCommand {
  @override
  String get name => 'export';

  @override
  String get description => 'Экспорт планов лицензий';

  ExportPlansCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Путь для сохранения экспорта',
      mandatory: true,
    );

    argParser.addFlag(
      'base64',
      help: 'Экспорт в формате Base64',
      defaultsTo: false,
    );

    argParser.addFlag(
      'force',
      abbr: 'F',
      help: 'Перезаписать файл, если он существует',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final service = await loadPlansService();
    if (service == null) return;

    final outputPath = argResults!['output'] as String;
    final useBase64 = argResults!['base64'] as bool;
    final force = argResults!['force'] as bool;

    // Проверим, существует ли файл
    final outputFile = File(outputPath);
    if (await outputFile.exists() && !force) {
      final confirmJson = JsonEncoder.withIndent('  ').convert({
        'status': 'confirm',
        'message': 'Файл уже существует. Перезаписать?',
        'filePath': outputPath,
      });
      print(confirmJson);

      stdout.write('Перезаписать файл? (y/n): ');
      final response = stdin.readLineSync()?.toLowerCase();

      if (response != 'y' && response != 'yes') {
        final cancelJson = JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'cancelled', 'message': 'Операция отменена'});
        print(cancelJson);
        return;
      }
    }

    // Получаем данные в нужном формате
    String data;
    if (useBase64) {
      data = service.exportToBase64();
    } else {
      data = service.exportToString();
    }

    try {
      await outputFile.writeAsString(data);
      final successJson = JsonEncoder.withIndent('  ').convert({
        'status': 'success',
        'message': 'Планы успешно экспортированы',
        'outputFile': outputPath,
        'format': useBase64 ? 'base64' : 'json',
        'plansCount': service.getAllPlans().length,
      });
      print(successJson);
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка при экспорте планов',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
