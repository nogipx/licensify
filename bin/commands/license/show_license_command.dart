// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to show license data
class ShowLicenseCommand extends BaseLicenseCommand {
  @override
  final String name = 'show';

  @override
  final String description = 'Просмотр данных лицензии';

  ShowLicenseCommand() {
    argParser.addOption(
      'license',
      abbr: 'l',
      help: 'Путь к файлу лицензии',
      mandatory: true,
    );

    argParser.addOption(
      'decryptKey',
      help: 'Ключ для дешифрования лицензии (если зашифрована)',
    );

    argParser.addOption(
      'outputJson',
      abbr: 'o',
      help: 'Сохранить результат в JSON-файл',
    );
  }

  @override
  Future<void> run() async {
    final licensePath = argResults!['license'] as String;
    final decryptKey = argResults!['decryptKey'] as String?;
    final outputJsonPath = argResults!['outputJson'] as String?;

    try {
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

      // Преобразуем лицензию в DTO для получения JSON
      final licenseDto = LicenseDto.fromDomain(license);

      // Стандартизированный формат вывода с полями status, message и data
      final response = {
        'status': 'success',
        'message': 'Информация о лицензии',
        'data': licenseDto.toJson(),
      };

      // Форматированный JSON для вывода
      final jsonOutput = JsonEncoder.withIndent('  ').convert(response);

      // Сохранение в файл, если указан путь
      if (outputJsonPath != null) {
        final outputFile = File(outputJsonPath);
        await outputFile.writeAsString(jsonOutput);

        final saveResponse = {
          'status': 'success',
          'message': 'Информация о лицензии сохранена в файл',
          'filePath': outputJsonPath,
        };
        print(JsonEncoder.withIndent('  ').convert(saveResponse));
      } else {
        // Просто выводим JSON в консоль
        print(jsonOutput);
      }
    } catch (e) {
      // Выводим ошибку в JSON формате
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка при просмотре данных лицензии',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
