// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:io';
import 'dart:convert';
import 'package:licensify/src/manage/license_plan_repository_impl.dart';
import 'package:licensify/src/manage/license_plan_service.dart';

import 'base_command.dart';

/// Base class for license plan management commands
abstract class BasePlansCommand extends BaseCommand {
  BasePlansCommand() {
    // Добавляем общие аргументы для всех команд управления планами
    argParser.addOption(
      'app-id',
      abbr: 'a',
      help: 'Идентификатор приложения',
      mandatory: true,
    );

    argParser.addOption(
      'file',
      help: 'Путь к файлу с планами',
      defaultsTo: 'license_plans.json',
    );
  }

  /// Загружает сервис с планами лицензий
  Future<LicensePlanService?> loadPlansService() async {
    final appId = argResults!['app-id'] as String;
    final filePath = argResults!['file'] as String;

    // Проверка appId
    final appIdError = validateAppId(appId);
    if (appIdError != null) {
      final errorJson = JsonEncoder.withIndent(
        '  ',
      ).convert({'status': 'error', 'message': appIdError});
      print(errorJson);
      return null;
    }

    final repository = InMemoryLicensePlanRepository(appId: appId);
    final service = LicensePlanService(appId: appId, repository: repository);

    // Проверяем наличие файла с планами
    final file = File(filePath);
    if (await file.exists()) {
      try {
        final data = await file.readAsString();
        final result = service.importFromString(data);
        if (!result.success) {
          final warningJson = JsonEncoder.withIndent(
            '  ',
          ).convert({'status': 'warning', 'message': result.message});
          print(warningJson);
        }
      } catch (e) {
        final warningJson = JsonEncoder.withIndent('  ').convert({
          'status': 'warning',
          'message': 'Ошибка загрузки планов из файла',
          'error': e.toString(),
        });
        print(warningJson);
        return service;
      }
    }

    return service;
  }

  /// Сохраняет планы в файл
  Future<Map<String, dynamic>> savePlans(LicensePlanService service) async {
    final filePath = argResults!['file'] as String;
    final data = service.exportToString();

    try {
      await File(filePath).writeAsString(data);
      return {
        'status': 'success',
        'message': 'Планы сохранены в файл',
        'filePath': filePath,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Ошибка при сохранении планов',
        'error': e.toString(),
      };
    }
  }
}
