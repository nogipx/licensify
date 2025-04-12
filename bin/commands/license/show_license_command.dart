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

    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Показать подробную информацию о лицензии',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final licensePath = argResults!['license'] as String;
    final decryptKey = argResults!['decryptKey'] as String?;
    final outputJsonPath = argResults!['outputJson'] as String?;
    final verbose = argResults!['verbose'] as bool;

    try {
      // Чтение файла лицензии
      final licenseFile = File(licensePath);
      if (!await licenseFile.exists()) {
        handleError('Файл лицензии не найден: $licensePath');
        return;
      }

      final licenseBytes = await licenseFile.readAsBytes();

      // Опциональное дешифрование лицензии
      Uint8List decodedBytes = decryptLicense(licenseBytes, decryptKey);

      // Декодирование лицензии
      final license = LicenseEncoder.decode(decodedBytes);

      // Преобразуем лицензию в DTO для получения JSON
      final licenseDto = LicenseDto.fromDomain(license);

      // Добавляем вычисляемые поля, если нужны подробности
      final Map<String, dynamic> outputData = Map<String, dynamic>.from(
        licenseDto.toJson(),
      );

      // Если не нужны подробности, удаляем некоторые поля
      if (!verbose) {
        // Опционально можем скрыть подпись и другие большие поля
        if (outputData['signature'] != null &&
            outputData['signature'].length > 40) {
          outputData['signature'] =
              '${outputData['signature'].substring(0, 30)}...';
        }
      }

      // Форматированный JSON для вывода
      final jsonOutput = JsonEncoder.withIndent('  ').convert(outputData);

      // Сохранение в файл, если указан путь
      if (outputJsonPath != null) {
        final outputFile = File(outputJsonPath);
        await outputFile.writeAsString(jsonOutput);

        // Выводим статус операции в JSON
        final resultJson = JsonEncoder.withIndent('  ').convert({
          'status': 'success',
          'message': 'Информация о лицензии сохранена в файл',
          'filePath': outputJsonPath,
        });
        print(resultJson);
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
