// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to decrypt license request
class DecryptRequestCommand extends BaseLicenseCommand {
  @override
  final String name = 'decrypt-request';

  @override
  final String description =
      'Расшифровка запроса на лицензию (серверная сторона)';

  DecryptRequestCommand() {
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
      'outputJson',
      abbr: 'o',
      help: 'Сохранить детали запроса в JSON-файл',
    );
  }

  @override
  Future<void> run() async {
    final requestPath = argResults!['requestFile'] as String;
    final privateKeyPath = argResults!['privateKey'] as String;
    final outputJsonPath = argResults!['outputJson'] as String?;

    try {
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

      // Создание дешифровщика запросов
      final requestDecrypter = LicenseRequestDecrypter(privateKey: privateKey);

      // Расшифровка запроса
      final request = requestDecrypter(requestBytes);

      // Подготовка данных для JSON-вывода
      final requestDetails = {
        'appId': request.appId,
        'deviceHash': request.deviceHash,
        'createdAt': request.createdAt.toIso8601String(),
        'expiresAt': request.expiresAt.toIso8601String(),
        'isExpired': request.isExpired,
        'remainingHours':
            request.expiresAt.difference(DateTime.now().toUtc()).inHours,
      };

      final outputData = {
        'status': 'success',
        'message': 'Запрос на лицензию успешно расшифрован',
        'requestDetails': requestDetails,
      };

      // Добавляем предупреждение, если запрос просрочен
      if (request.isExpired) {
        outputData['warning'] = 'Этот запрос уже просрочен';
      }

      // Сохранение в JSON, если указан путь
      if (outputJsonPath != null) {
        final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
        final outputFile = File(outputJsonPath);
        await outputFile.writeAsString(jsonOutput);

        // Информация о сохранении в JSON формате
        final saveInfo = {
          'status': 'success',
          'message': 'Информация о запросе на лицензию сохранена в файл',
          'filePath': outputJsonPath,
        };
        final saveJson = JsonEncoder.withIndent('  ').convert(saveInfo);
        print(saveJson);
      } else {
        // Вывод результата в JSON
        final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);
        print(jsonOutput);
      }
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка расшифровки запроса на лицензию',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
