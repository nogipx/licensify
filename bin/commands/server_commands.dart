// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:args/command_runner.dart';
import 'license/_index.dart';
import 'plans/_index.dart';

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
      print('Серверный процесс лицензирования');
      print('');
      print('Доступные операции:');
      print('');
      print('Управление ключами:');
      print(
        '  licensify server keygen --private private.pem --public public.pem',
      );
      print('');
      print('Управление планами лицензий:');
      print('  licensify server list --app-id APPID');
      print('  licensify server plan --id PLAN_ID --app-id APPID');
      print(
        '  licensify server create --id PLAN_ID --name NAME --app-id APPID [--description DESC] [--type TYPE] [...]',
      );
      print('  licensify server remove --id PLAN_ID --app-id APPID');
      print('  licensify server import --input plans.json --app-id APPID');
      print('  licensify server export --output plans.json --app-id APPID');
      print('');
      print('Работа с лицензиями:');
      print(
        '  licensify server decrypt-request --requestFile request.bin --privateKey private.pem',
      );
      print(
        '  licensify server respond --requestFile request.bin --privateKey private.pem --expiration 2025-12-31',
      );
      print(
        '  licensify server respond-with-plan --requestFile request.bin --privateKey private.pem --planId PLAN_ID --app-id APPID',
      );
      print(
        '  licensify server generate --appId APPID --privateKey private.pem --expiration 2025-12-31 [options]',
      );
      print('');
      print(
        'Для получения дополнительной информации по конкретной команде используйте:',
      );
      print('licensify server COMMAND --help');
    }
  }
}
