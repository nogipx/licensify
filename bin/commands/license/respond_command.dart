// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:io';
import 'dart:convert';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to respond to license request
class RespondCommand extends BaseLicenseCommand {
  @override
  final String name = 'respond';

  @override
  final String description = 'Ответ на запрос лицензии (серверная сторона)';

  RespondCommand() {
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
      'extension',
      help: 'Расширение файла лицензии (без точки)',
    );

    argParser.addOption(
      'expiration',
      help: 'Дата истечения лицензии (YYYY-MM-DD)',
      mandatory: true,
    );

    argParser.addOption(
      'type',
      help: 'Тип лицензии (standard, pro или пользовательский)',
      defaultsTo: 'standard',
    );

    argParser.addFlag('trial', help: 'Пробная лицензия', defaultsTo: false);

    argParser.addMultiOption(
      'features',
      abbr: 'f',
      help: 'Фичи лицензии в формате key=value',
    );

    argParser.addMultiOption(
      'metadata',
      abbr: 'm',
      help: 'Метаданные лицензии в формате key=value',
    );

    argParser.addFlag(
      'encrypt',
      help: 'Зашифровать файл лицензии',
      defaultsTo: false,
    );

    argParser.addOption('encryptKey', help: 'Ключ для шифрования');
  }

  @override
  Future<void> run() async {
    final requestPath = argResults!['requestFile'] as String;
    final privateKeyPath = argResults!['privateKey'] as String;
    final outputPath = argResults!['output'] as String;
    final extension = argResults!['extension'] as String?;
    final expirationStr = argResults!['expiration'] as String;
    final licenseTypeStr = argResults!['type'] as String;
    final featuresList = argResults!['features'] as List<String>;
    final metadataList = argResults!['metadata'] as List<String>;
    final shouldEncrypt = argResults!['encrypt'] as bool;
    final encryptKey = argResults!['encryptKey'] as String?;
    final isTrial = argResults!['trial'] as bool;

    try {
      // Чтение файла запроса
      final requestFile = File(requestPath);
      if (!await requestFile.exists()) {
        handleError('Файл запроса не найден: $requestPath');
        return;
      }

      final requestBytes = await requestFile.readAsBytes();

      // Чтение приватного ключа
      final privateKeyFile = File(privateKeyPath);
      if (!await privateKeyFile.exists()) {
        handleError('Файл приватного ключа не найден: $privateKeyPath');
        return;
      }

      final privateKeyPem = await privateKeyFile.readAsString();
      final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPem);

      // Создание дешифровщика запросов
      final requestDecrypter = LicenseRequestDecrypter(privateKey: privateKey);

      // Расшифровка запроса
      final request = requestDecrypter(requestBytes);

      // Проверка, не просрочен ли запрос
      if (request.isExpired) {
        print(
          'ВНИМАНИЕ: Запрос на лицензию просрочен. Продолжаем всё равно...',
        );
      }

      // Проверка appId из запроса
      final appIdError = validateAppId(request.appId);
      if (appIdError != null) {
        handleError(appIdError);
        return;
      }

      // Разбор даты истечения
      DateTime expirationDate;
      try {
        expirationDate = DateTime.parse(expirationStr);
      } catch (e) {
        handleError(
          'Некорректный формат даты истечения. Используйте YYYY-MM-DD',
        );
        return;
      }

      // Парсинг фич и метаданных
      final features = parseKeyValues(featuresList);
      final additionalMetadata = parseKeyValues(metadataList);

      // Добавление хеша устройства в метаданные
      final metadata = {
        'deviceHash': request.deviceHash,
        ...additionalMetadata,
      };

      // Проверка типа лицензии
      final licenseTypeError = validateLicenseType(
        licenseTypeStr.toLowerCase(),
      );
      if (licenseTypeError != null) {
        handleError(licenseTypeError);
        return;
      }

      // Определение типа лицензии
      final licenseType = getLicenseType(licenseTypeStr);

      // Создание генератора лицензий
      final licenseGenerator = LicenseGenerator(privateKey: privateKey);

      // Генерация лицензии на основе запроса
      final license = licenseGenerator(
        appId: request.appId,
        expirationDate: expirationDate,
        type: licenseType,
        features: features,
        metadata: metadata,
        isTrial: isTrial,
      );

      // Кодирование лицензии
      final licenseBytes = LicenseEncoder.encode(license);

      // Опциональное шифрование
      final finalBytes =
          shouldEncrypt
              ? encryptLicense(licenseBytes, encryptKey)
              : licenseBytes;

      // Определяем итоговый путь с учетом расширения
      final String finalOutputPath;
      if (extension != null && outputPath == 'license.licensify') {
        // Если указано расширение и выходной путь не изменен пользователем,
        // заменяем стандартное расширение на пользовательское
        finalOutputPath =
            'license.${getLicenseFileExtension(customExtension: extension)}';
      } else {
        finalOutputPath = outputPath;
      }

      // Сохранение лицензии в файл
      final outputFile = File(finalOutputPath);
      await outputFile.writeAsBytes(finalBytes);

      // Преобразуем лицензию в DTO для получения JSON
      final licenseDto = LicenseDto.fromDomain(license);
      final licenseData = licenseDto.toJson();

      // Добавляем информацию о выходном файле
      licenseData['outputFile'] = finalOutputPath;

      // Выводим только данные лицензии
      final jsonOutput = JsonEncoder.withIndent('  ').convert(licenseData);
      print(jsonOutput);
    } catch (e) {
      print('Ошибка обработки запроса на лицензию: ${e.toString()}');
    }
  }
}
