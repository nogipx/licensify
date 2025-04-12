// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to verify a license
class VerifyCommand extends BaseLicenseCommand {
  @override
  final String name = 'verify';

  @override
  final String description = 'Проверка лицензии';

  VerifyCommand() {
    argParser.addOption(
      'license',
      abbr: 'l',
      help: 'Путь к файлу лицензии',
      mandatory: true,
    );

    argParser.addOption(
      'publicKey',
      abbr: 'k',
      help: 'Путь к файлу публичного ключа',
      mandatory: true,
    );

    argParser.addOption('decryptKey', help: 'Ключ для дешифрования лицензии');

    argParser.addOption(
      'outputJson',
      abbr: 'o',
      help: 'Сохранить результат проверки в JSON-файл',
    );
  }

  @override
  Future<void> run() async {
    final licensePath = argResults!['license'] as String;
    final publicKeyPath = argResults!['publicKey'] as String;
    final decryptKey = argResults!['decryptKey'] as String?;
    final outputJsonPath = argResults!['outputJson'] as String?;

    try {
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

      // Чтение файла лицензии
      final licenseFile = File(licensePath);
      if (!await licenseFile.exists()) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Файл лицензии не найден',
          'path': licensePath,
        });
        print(errorJson);
        return;
      }

      final licenseBytes = await licenseFile.readAsBytes();

      // Опциональное дешифрование лицензии
      Uint8List decodedBytes = decryptLicense(licenseBytes, decryptKey);

      // Декодирование лицензии
      final license = LicenseEncoder.decode(decodedBytes);

      // Проверка подписи
      final validator = LicenseValidator(publicKey: publicKey);
      final validationResult = validator(license);

      final response = {
        'status': validationResult.isValid ? 'success' : 'error',
        'message':
            validationResult.isValid
                ? 'Лицензия валидна'
                : 'Лицензия невалидна: ${validationResult.message}',
        'data': <String, dynamic>{
          'validation': {
            'isValid': validationResult.isValid,
            'message': validationResult.message,
          },
        },
      };

      // Если лицензия валидна, добавляем данные лицензии
      if (validationResult.isValid) {
        final licenseDto = LicenseDto.fromDomain(license);
        (response['data'] as Map<String, dynamic>)['license'] =
            licenseDto.toJson();
      }

      // Форматированный JSON для вывода
      final jsonOutput = JsonEncoder.withIndent('  ').convert(response);

      // Сохранение в JSON, если указан путь
      if (outputJsonPath != null) {
        final outputFile = File(outputJsonPath);
        await outputFile.writeAsString(jsonOutput);

        final saveResponse = {
          'status': 'success',
          'message': 'Информация о валидации лицензии сохранена в файл',
          'filePath': outputJsonPath,
        };
        print(JsonEncoder.withIndent('  ').convert(saveResponse));
      } else {
        // Просто выводим JSON в консоль
        print(jsonOutput);
      }
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка проверки лицензии',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
