// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:args/command_runner.dart';
import 'license/_index.dart';
import 'plans/_index.dart';
import 'dart:convert';

/// Main command for server-side license operations
class ServerCommand extends Command<void> {
  @override
  final String name = 'server';

  @override
  final String description = 'Серверный процесс лицензирования';

  ServerCommand() {
    // Ключи
    addSubcommand(KeygenCommand()); // Генерация ключей

    // Планы лицензий
    addSubcommand(ListPlansCommand()); // Просмотр списка планов
    addSubcommand(ShowPlanCommand()); // Просмотр плана
    addSubcommand(CreatePlanCommand()); // Создание плана
    addSubcommand(RemovePlanCommand()); // Удаление плана
    addSubcommand(ImportPlansCommand()); // Импорт планов
    addSubcommand(ExportPlansCommand()); // Экспорт планов

    // Работа с лицензиями
    addSubcommand(GenerateCommand()); // Прямая генерация лицензии
    addSubcommand(DecryptRequestCommand()); // Расшифровка запроса на лицензию
    addSubcommand(RespondCommand()); // Ответ на запрос лицензии
    addSubcommand(
      RespondWithPlanCommand(),
    ); // Ответ на запрос с использованием плана
    addSubcommand(VerifyCommand()); // Проверка лицензии
    addSubcommand(ShowLicenseCommand()); // Просмотр информации о лицензии
  }

  @override
  void run() {
    // Этот метод вызывается, если пользователь набрал только `licensify server` без подкоманды
    if (argResults?.rest.isEmpty ?? true) {
      final helpData = {
        'status': 'info',
        'message': 'Серверный процесс лицензирования',
        'commands': {
          'keyManagement': [
            'licensify server keygen --private private.pem --public public.pem',
          ],
          'planManagement': [
            'licensify server list --app-id APPID',
            'licensify server plan --id PLAN_ID --app-id APPID',
            'licensify server create --id PLAN_ID --name NAME --app-id APPID [--description DESC] [--type TYPE] [...]',
            'licensify server remove --id PLAN_ID --app-id APPID',
            'licensify server import --input plans.json --app-id APPID',
            'licensify server export --output plans.json --app-id APPID',
          ],
          'licenseManagement': [
            'licensify server decrypt-request --requestFile request.bin --privateKey private.pem',
            'licensify server respond --requestFile request.bin --privateKey private.pem --expiration 2025-12-31',
            'licensify server respond-with-plan --requestFile request.bin --privateKey private.pem --planId PLAN_ID --app-id APPID',
            'licensify server generate --appId APPID --privateKey private.pem --expiration 2025-12-31 [options]',
          ],
          'help': 'licensify server COMMAND --help',
        },
      };
      print(JsonEncoder.withIndent('  ').convert(helpData));
    }
  }
}
