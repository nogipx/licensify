// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:licensify/licensify.dart';
import 'package:licensify/src/manage/license_plan_service.dart';
import 'package:licensify/src/manage/license_plan_repository_impl.dart';
import 'package:licensify/src/manage/license_plan.dart';

import '../_base/_index.dart';

/// Command to respond to license request using a specific plan
class RespondWithPlanCommand extends BaseLicenseCommand {
  @override
  final String name = 'respond-with-plan';

  @override
  final String description =
      'Ответ на запрос лицензии, используя указанный план';

  RespondWithPlanCommand() {
    argParser.addOption(
      'requestFile',
      abbr: 'r',
      help: 'Путь к файлу запроса на лицензию',
      mandatory: true,
    );

    argParser.addOption(
      'privateKey',
      abbr: 'k',
      help: 'Путь к файлу приватного ключа',
      mandatory: true,
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Путь для сохранения лицензии',
      defaultsTo: 'license.licensify',
    );

    argParser.addOption(
      'planId',
      help: 'ID плана лицензии, который нужно использовать',
      mandatory: true,
    );

    argParser.addOption(
      'app-id',
      help: 'Идентификатор приложения для поиска плана',
      mandatory: true,
    );

    argParser.addOption(
      'plansFile',
      help: 'Путь к файлу с планами лицензий',
      defaultsTo: 'license_plans.json',
    );

    argParser.addMultiOption(
      'metadata',
      abbr: 'm',
      help: 'Дополнительные метаданные лицензии в формате key=value',
    );

    argParser.addFlag(
      'encrypt',
      help: 'Зашифровать файл лицензии',
      defaultsTo: false,
    );

    argParser.addOption('encryptKey', help: 'Ключ для шифрования');

    argParser.addOption(
      'customExpiration',
      help:
          'Пользовательская дата истечения (YYYY-MM-DD), иначе используется длительность из плана',
    );
  }

  @override
  Future<void> run() async {
    final requestPath = argResults!['requestFile'] as String;
    final privateKeyPath = argResults!['privateKey'] as String;
    final outputPath = argResults!['output'] as String;
    final planId = argResults!['planId'] as String;
    final appId = argResults!['app-id'] as String;
    final plansFilePath = argResults!['plansFile'] as String;
    final metadataList = argResults!['metadata'] as List<String>;
    final shouldEncrypt = argResults!['encrypt'] as bool;
    final encryptKey = argResults!['encryptKey'] as String?;
    final customExpirationStr = argResults!['customExpiration'] as String?;

    try {
      // Загрузка плана
      final plan = await loadPlan(planId, appId, plansFilePath);
      if (plan == null) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'План не найден',
          'planId': planId,
        });
        print(errorJson);
        return;
      }

      // Чтение файла запроса
      final requestFile = File(requestPath);
      if (!await requestFile.exists()) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Файл запроса не найден',
          'path': requestPath,
        });
        print(errorJson);
        return;
      }

      final requestBytes = await requestFile.readAsBytes();

      // Чтение приватного ключа
      final privateKeyFile = File(privateKeyPath);
      if (!await privateKeyFile.exists()) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Файл приватного ключа не найден',
          'path': privateKeyPath,
        });
        print(errorJson);
        return;
      }

      final privateKeyPem = await privateKeyFile.readAsString();
      final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPem);

      // Расшифровка запроса
      final requestDecrypter = LicenseRequestDecrypter(privateKey: privateKey);
      final request = requestDecrypter(requestBytes);

      // Проверка, не просрочен ли запрос
      if (request.isExpired) {
        final warningJson = JsonEncoder.withIndent('  ').convert({
          'status': 'warning',
          'message': 'Запрос на лицензию просрочен, продолжаем обработку',
        });
        print(warningJson);
      }

      // Проверка, что appId из запроса совпадает с appId из плана
      if (request.appId != plan.appId) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'AppId в запросе не совпадает с appId в плане',
          'requestAppId': request.appId,
          'planAppId': plan.appId,
        });
        print(errorJson);
        return;
      }

      // Определение даты истечения
      DateTime expirationDate;
      if (customExpirationStr != null) {
        try {
          expirationDate = DateTime.parse(customExpirationStr);
        } catch (e) {
          final errorJson = JsonEncoder.withIndent('  ').convert({
            'status': 'error',
            'message':
                'Некорректный формат даты истечения, используйте YYYY-MM-DD',
            'value': customExpirationStr,
          });
          print(errorJson);
          return;
        }
      } else if (plan.durationDays != null) {
        // Используем продолжительность из плана
        expirationDate = DateTime.now().add(Duration(days: plan.durationDays!));
      } else {
        // Бессрочная лицензия - по умолчанию 100 лет
        expirationDate = DateTime.now().add(Duration(days: 36500));
      }

      // Парсинг метаданных
      final additionalMetadata = parseKeyValues(metadataList);

      // Добавление хеша устройства и возможно других метаданных из плана
      final metadata = {
        'deviceHash': request.deviceHash,
        'planId': plan.id,
        ...additionalMetadata,
      };

      // Создание генератора лицензий
      final licenseGenerator = LicenseGenerator(privateKey: privateKey);

      // Генерация лицензии на основе запроса и плана
      final license = licenseGenerator(
        appId: request.appId,
        expirationDate: expirationDate,
        type: plan.licenseType,
        features: plan.createDefaultFeatures(),
        metadata: metadata,
        isTrial: plan.isTrial,
      );

      // Кодирование лицензии
      final licenseBytes = LicenseEncoder.encode(license);

      // Опциональное шифрование
      final finalBytes =
          shouldEncrypt
              ? encryptLicense(licenseBytes, encryptKey)
              : licenseBytes;

      // Сохранение лицензии в файл
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(finalBytes);

      // Подготовка данных лицензии для вывода
      final licenseData = {
        'id': license.id,
        'appId': license.appId,
        'type': license.type.name,
        'isTrial': license.isTrial,
        'createdAt': license.createdAt.toIso8601String(),
        'expirationDate': license.expirationDate.toIso8601String(),
        'remainingDays': license.remainingDays,
        'usedPlan': {
          'id': plan.id,
          'name': plan.name,
          'description': plan.description,
          'price': plan.price,
        },
        'deviceHash': metadata['deviceHash'],
        'features': license.features,
        'metadata': license.metadata,
      };

      // Формирование JSON-ответа
      final outputData = {
        'status': 'success',
        'message': 'Лицензия успешно создана на основе плана',
        'filePath': outputPath,
        'encrypted': shouldEncrypt,
        'license': licenseData,
      };

      final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
      print(jsonOutput);
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка создания лицензии',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }

  /// Загружает план по ID из файла планов
  Future<LicensePlan?> loadPlan(
    String planId,
    String appId,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final repository = InMemoryLicensePlanRepository(appId: appId);
      final service = LicensePlanService(appId: appId, repository: repository);

      // Загружаем планы из файла
      final data = await file.readAsString();
      service.importFromString(data);

      // Поиск плана по ID
      return service.getPlan(planId);
    } catch (e) {
      return null;
    }
  }
}
