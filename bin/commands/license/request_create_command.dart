// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to create license request
class RequestCreateCommand extends BaseLicenseCommand {
  @override
  final String name = 'request-create';

  @override
  final String description = 'Create license request (client side)';

  RequestCreateCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Path to save license request',
      defaultsTo: 'license_request.bin',
    );

    argParser.addOption(
      'extension',
      help: 'License request file extension (without dot)',
    );

    argParser.addOption(
      'appId',
      help: 'Application ID for request',
      mandatory: true,
    );

    argParser.addOption('deviceId', help: 'Device ID (will be hashed)');

    argParser.addOption(
      'publicKey',
      abbr: 'k',
      help: 'Path to public key file (from license publisher)',
      mandatory: true,
    );

    argParser.addOption(
      'validHours',
      help: 'Request validity in hours',
      defaultsTo: '48',
    );
  }

  @override
  Future<void> run() async {
    final outputPath = argResults!['output'] as String;
    final extension = argResults!['extension'] as String?;
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
          'message': 'Public key file not found',
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
            'message': 'Request validity must be a positive number',
          });
          print(errorJson);
          return;
        }
      } catch (e) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Invalid request validity format',
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

      // Определяем итоговый путь с учетом расширения
      final String finalOutputPath;
      if (extension != null && outputPath == 'license_request.bin') {
        // Если указано расширение и выходной путь не изменен пользователем,
        // заменяем стандартное расширение на пользовательское
        finalOutputPath =
            'license_request.${getRequestFileExtension(customExtension: extension)}';
      } else {
        finalOutputPath = outputPath;
      }

      // Сохранение в файл
      final outputFile = File(finalOutputPath);
      await outputFile.writeAsBytes(requestBytes);

      // Подготовка данных для вывода в JSON
      final outputData = {
        'status': 'success',
        'message': 'License request created successfully',
        'requestDetails': {
          'appId': appId,
          'deviceHash': deviceHash,
          'deviceIdSource': deviceId != null ? 'provided' : 'generated',
          'validHours': validHours,
          'outputFile': finalOutputPath,
        },
      };

      // Вывод JSON с результатом
      final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
      print(jsonOutput);
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Error creating license request',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
