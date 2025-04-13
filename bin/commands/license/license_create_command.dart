// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:io';
import 'dart:convert';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to create license
class LicenseCreateCommand extends BaseLicenseCommand {
  @override
  final String name = 'license-create';

  @override
  final String description = 'Create and sign license';

  LicenseCreateCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Path to save license',
      defaultsTo: 'license.licensify',
    );

    argParser.addOption(
      'extension',
      help: 'License file extension (without dot)',
    );

    argParser.addOption(
      'privateKey',
      abbr: 'k',
      help: 'Path to private key file',
      mandatory: true,
    );

    argParser.addOption(
      'appId',
      help: 'Application ID for license',
      mandatory: true,
    );

    argParser.addOption(
      'id',
      help: 'License ID (UUID). Will be generated if not specified',
    );

    argParser.addOption(
      'expiration',
      help: 'License expiration date (YYYY-MM-DD)',
      mandatory: true,
    );

    argParser.addOption(
      'type',
      help: 'License type (standard, pro or custom)',
      defaultsTo: 'standard',
    );

    argParser.addFlag('trial', help: 'Trial license', defaultsTo: false);

    argParser.addMultiOption(
      'features',
      abbr: 'f',
      help: 'License features in key=value format',
    );

    argParser.addMultiOption(
      'metadata',
      abbr: 'm',
      help: 'License metadata in key=value format',
    );

    argParser.addFlag(
      'encrypt',
      help: 'Encrypt license file',
      defaultsTo: false,
    );

    argParser.addOption('encryptKey', help: 'Encryption key');
  }

  @override
  Future<void> run() async {
    final outputPath = argResults!['output'] as String;
    final extension = argResults!['extension'] as String?;
    final privateKeyPath = argResults!['privateKey'] as String;
    final appId = argResults!['appId'] as String;
    final expirationStr = argResults!['expiration'] as String;
    final licenseTypeStr = argResults!['type'] as String;
    final featuresList = argResults!['features'] as List<String>;
    final metadataList = argResults!['metadata'] as List<String>;
    final shouldEncrypt = argResults!['encrypt'] as bool;
    final encryptKey = argResults!['encryptKey'] as String?;
    final isTrial = argResults!['trial'] as bool;

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

      // Разбор даты истечения
      DateTime expirationDate;
      try {
        expirationDate = DateTime.parse(expirationStr);
      } catch (e) {
        final errorJson = JsonEncoder.withIndent('  ').convert({
          'status': 'error',
          'message': 'Invalid expiration date format. Use YYYY-MM-DD',
          'value': expirationStr,
        });
        print(errorJson);
        return;
      }

      // Проверка типа лицензии
      final licenseTypeError = validateLicenseType(licenseTypeStr);
      if (licenseTypeError != null) {
        final errorJson = JsonEncoder.withIndent(
          '  ',
        ).convert({'status': 'error', 'message': licenseTypeError});
        print(errorJson);
        return;
      }

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

      // Парсинг фич и метаданных
      final features = parseKeyValues(featuresList);
      final metadata = parseKeyValues(metadataList);

      // Определение типа лицензии
      final licenseType = getLicenseType(licenseTypeStr);

      // Создание генератора лицензий
      final licenseGenerator = LicenseGenerator(privateKey: privateKey);

      // Генерация лицензии
      final license = licenseGenerator(
        appId: appId,
        expirationDate: expirationDate,
        type: licenseType,
        features: features,
        metadata: metadata,
        isTrial: isTrial,
      );

      // Кодирование лицензии в байты
      final licenseBytes = LicenseEncoder.encode(license);

      // Шифрование, если необходимо
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

      // Сохранение в файл
      final outputFile = File(finalOutputPath);
      await outputFile.writeAsBytes(finalBytes);

      // Преобразуем лицензию в DTO для получения JSON
      final licenseDto = LicenseDto.fromDomain(license);

      // Подготовка данных для вывода
      final result = {
        'status': 'success',
        'message': 'License generated successfully',
        'filePath': finalOutputPath,
        'encrypted': shouldEncrypt,
        'license': licenseDto.toJson(),
      };

      // Вывод JSON
      print(JsonEncoder.withIndent('  ').convert(result));
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Error generating license',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
