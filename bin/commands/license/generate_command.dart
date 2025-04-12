// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:io';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to generate license
class GenerateCommand extends BaseLicenseCommand {
  @override
  final String name = 'generate';

  @override
  final String description = 'Генерация и подписание лицензии';

  GenerateCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Путь для сохранения лицензии',
      defaultsTo: 'license.licensify',
    );

    argParser.addOption(
      'privateKey',
      abbr: 'k',
      help: 'Путь к файлу приватного ключа',
      mandatory: true,
    );

    argParser.addOption(
      'appId',
      help: 'Идентификатор приложения для лицензии',
      mandatory: true,
    );

    argParser.addOption(
      'id',
      help: 'ID лицензии (UUID). Будет сгенерирован, если не указан',
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
    final outputPath = argResults!['output'] as String;
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

      // Проверка типа лицензии
      final licenseTypeError = validateLicenseType(licenseTypeStr);
      if (licenseTypeError != null) {
        handleError(licenseTypeError);
        return;
      }

      // Чтение приватного ключа
      final privateKeyFile = File(privateKeyPath);
      if (!await privateKeyFile.exists()) {
        handleError('Файл приватного ключа не найден: $privateKeyPath');
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

      // Сохранение в файл
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(finalBytes);

      print('Лицензия успешно сгенерирована: $outputPath');
      print('ID: ${license.id}');
      print('Приложение: ${license.appId}');
      print('Тип: ${license.type.name}');
      print('Пробная: ${license.isTrial ? 'Да' : 'Нет'}');
      print('Дата истечения: ${license.expirationDate}');

      if (features.isNotEmpty) {
        print('\nФичи:');
        features.forEach((key, value) {
          print('  $key: $value');
        });
      }

      if (metadata.isNotEmpty) {
        print('\nМетаданные:');
        metadata.forEach((key, value) {
          print('  $key: $value');
        });
      }
    } catch (e) {
      handleError('Ошибка генерации лицензии: $e');
    }
  }
}
