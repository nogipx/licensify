// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to decrypt license request
class RequestReadCommand extends BaseLicenseCommand {
  @override
  final String name = 'request-read';

  @override
  final String description = 'Read license request (server side)';

  RequestReadCommand() {
    argParser.addOption(
      'requestFile',
      abbr: 'r',
      help: 'Path to license request file',
      mandatory: true,
    );

    argParser.addOption(
      'privateKey',
      abbr: 'k',
      help: 'Path to private key file',
      mandatory: true,
    );

    argParser.addOption(
      'outputJson',
      abbr: 'o',
      help: 'Save request details to JSON file',
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
          'message': 'Request file not found',
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
          'message': 'Private key file not found',
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

      // Используем родной метод toJson вместо ручного создания JSON
      final requestDetails = request.toJson();

      // Сохранение в JSON, если указан путь
      if (outputJsonPath != null) {
        final jsonOutput = JsonEncoder.withIndent('  ').convert(requestDetails);
        final outputFile = File(outputJsonPath);
        await outputFile.writeAsString(jsonOutput);
        print('License request information saved to file: $outputJsonPath');
      } else {
        // Просто выводим JSON в консоль
        final jsonOutput = JsonEncoder.withIndent('  ').convert(requestDetails);
        print(jsonOutput);
      }
    } catch (e) {
      print('Error decrypting license request: ${e.toString()}');
    }
  }
}
