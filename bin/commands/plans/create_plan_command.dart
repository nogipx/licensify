// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:licensify/src/license/domain/entities/license_type.dart';
import 'package:licensify/src/manage/license_plan_builder.dart';
import '../_base/_index.dart';

/// Command to create a new license plan
class CreatePlanCommand extends BasePlansCommand {
  @override
  String get name => 'create';

  @override
  String get description => 'Создание нового плана лицензии';

  CreatePlanCommand() {
    argParser.addOption('id', help: 'Идентификатор плана', mandatory: true);
    argParser.addOption('name', help: 'Название плана', mandatory: true);
    argParser.addOption('description', help: 'Описание плана', defaultsTo: '');
    argParser.addOption(
      'type',
      help: 'Тип лицензии (standard, pro или пользовательский)',
      defaultsTo: 'standard',
    );
    argParser.addOption(
      'duration',
      help: 'Срок действия в днях (пусто = бессрочный)',
    );
    argParser.addFlag('public', help: 'Публичный план', defaultsTo: true);
    argParser.addOption(
      'priority',
      help: 'Приоритет (для сортировки)',
      defaultsTo: '100',
    );
    argParser.addOption('price', help: 'Цена плана', defaultsTo: '0');
    argParser.addFlag('trial', help: 'Пробный план', defaultsTo: false);
  }

  @override
  Future<void> run() async {
    final service = await loadPlansService();
    if (service == null) return;

    final planId = argResults!['id'] as String;
    final name = argResults!['name'] as String;
    final description = argResults!['description'] as String;
    final typeStr = argResults!['type'] as String;
    final durationStr = argResults!['duration'] as String?;
    final isPublic = argResults!['public'] as bool;
    final priorityStr = argResults!['priority'] as String;
    final priceStr = argResults!['price'] as String;
    final isTrial = argResults!['trial'] as bool;

    // Валидация введенных данных
    if (planId.isEmpty || name.isEmpty) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'ID и название плана не могут быть пустыми',
      });
      print(errorJson);
      return;
    }

    // Проверяем, существует ли уже план с таким ID
    if (service.getPlan(planId) != null) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'План с указанным ID уже существует',
        'planId': planId,
      });
      print(errorJson);
      return;
    }

    // Проверка типа лицензии
    final licenseTypeError = validateLicenseType(typeStr.toLowerCase());
    if (licenseTypeError != null) {
      final errorJson = JsonEncoder.withIndent(
        '  ',
      ).convert({'status': 'error', 'message': licenseTypeError});
      print(errorJson);
      return;
    }

    // Определяем тип лицензии
    LicenseType licenseType;
    switch (typeStr.toLowerCase()) {
      case 'pro':
        licenseType = LicenseType.pro;
        break;
      case 'standard':
        licenseType = LicenseType.standard;
        break;
      default:
        // Create a custom license type
        licenseType = LicenseType(typeStr.toLowerCase());
        break;
    }

    // Создаем builder для плана
    final builder = LicensePlanBuilder(
      id: planId,
      name: name,
      description: description,
      licenseType: licenseType,
    );

    // Устанавливаем appId
    builder.setAppId(service.appId);

    // Устанавливаем срок действия
    if (durationStr != null && durationStr.isNotEmpty) {
      final duration = int.tryParse(durationStr);
      if (duration != null) {
        builder.withDuration(duration);
      } else {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Некорректный формат срока действия',
          'value': durationStr,
        });
        print(errorJson);
        return;
      }
    } else {
      builder.permanent();
    }

    // Устанавливаем остальные параметры
    builder.setPublic(isPublic);

    final priority = int.tryParse(priorityStr) ?? 100;
    builder.setPriority(priority);

    final price = num.tryParse(priceStr) ?? 0;
    builder.setPrice(price);

    builder.setTrial(isTrial);

    // Создаем план
    final plan = builder.build();

    // Сохраняем план
    final result = service.addPlan(plan);

    if (result.success) {
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
        'appId': service.appId,
      };

      // Вывод информации о созданном плане
      final outputData = {
        'status': 'success',
        'message': result.message,
        'plan': planData,
      };

      final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
      print(jsonOutput);

      await savePlans(service);
    } else {
      final errorJson = JsonEncoder.withIndent(
        '  ',
      ).convert({'status': 'error', 'message': result.message});
      print(errorJson);
    }
  }
}
