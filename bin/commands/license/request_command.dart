// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to create license request
class RequestCommand extends BaseLicenseCommand {
  @override
  final String name = 'request';

  @override
  final String description =
      'Создание запроса на лицензию (клиентская сторона)';

  RequestCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Путь для сохранения запроса на лицензию',
      defaultsTo: 'license_request.bin',
    );

    argParser.addOption(
      'appId',
      help: 'Идентификатор приложения для запроса',
      mandatory: true,
    );

    argParser.addOption(
      'deviceId',
      help: 'Идентификатор устройства (будет захеширован)',
    );

    argParser.addOption(
      'publicKey',
      abbr: 'k',
      help: 'Путь к файлу публичного ключа (от издателя лицензии)',
      mandatory: true,
    );

    argParser.addOption(
      'validHours',
      help: 'Срок действия запроса в часах',
      defaultsTo: '48',
    );
  }

  @override
  Future<void> run() async {
    final outputPath = argResults!['output'] as String;
    final appId = argResults!['appId'] as String;
    final deviceId = argResults!['deviceId'] as String?;
    final publicKeyPath = argResults!['publicKey'] as String;
    final validHoursStr = argResults!['validHours'] as String;

    try {
      // Проверка appId
      final appIdError = validateAppId(appId);
      if (appIdError != null) {
        final errorJson = JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'error', 'message': appIdError});
        print(errorJson);
        return;
      }

      // Чтение публичного ключа
      final publicKeyFile = File(publicKeyPath);
      if (!await publicKeyFile.exists()) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Файл публичного ключа не найден',
          'path': publicKeyPath,
        });
        print(errorJson);
        return;
      }

      final publicKeyPem = await publicKeyFile.readAsString();
      final publicKey = LicensifyPublicKey.ecdsa(publicKeyPem);

      // Генерация хеша устройства
      final deviceHash = generateDeviceHash(deviceId);

      // Парсинг срока действия
      int validHours;
      try {
        validHours = int.parse(validHoursStr);
        if (validHours <= 0) {
          final errorJson = JsonEncoder.withIndent('  ').convert({
            'status': 'error',
            'message': 'Срок действия должен быть положительным числом',
          });
          print(errorJson);
          return;
        }
      } catch (e) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Некорректный формат срока действия',
          'value': validHoursStr,
        });
        print(errorJson);
        return;
      }

      // Создание генератора запросов на лицензию
      final requestGenerator = publicKey.licenseRequestGenerator();

      // Генерация запроса
      final requestBytes = requestGenerator(
        deviceHash: deviceHash,
        appId: appId,
        expirationHours: validHours,
      );

      // Сохранение в файл
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(requestBytes);

      // Подготовка данных для вывода в JSON
      final outputData = {
        'status': 'success',
        'message': 'Запрос на лицензию успешно создан',
        'requestDetails': {
          'appId': appId,
          'deviceHash': deviceHash,
          'deviceIdSource': deviceId != null ? 'provided' : 'generated',
          'validHours': validHours,
          'outputFile': outputPath,
        },
      };

      // Вывод JSON с результатом
      final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
      print(jsonOutput);
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка создания запроса на лицензию',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
