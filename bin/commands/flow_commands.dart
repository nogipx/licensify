// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:args/command_runner.dart';
import 'license/_index.dart';
import 'plans/_index.dart';

/// Main command for client-side license flows
class FlowCommand extends Command<void> {
  @override
  final String name = 'flow';

  @override
  final String description = 'Клиентский процесс лицензирования';

  FlowCommand() {
    // Добавляем подкоманды для клиентского процесса
    addSubcommand(RequestCommand()); // Создать запрос на лицензию
    addSubcommand(VerifyCommand()); // Проверить лицензию
    addSubcommand(ShowLicenseCommand()); // Показать информацию о лицензии
    addSubcommand(ListPlansCommand()); // Просмотреть доступные планы лицензий
    addSubcommand(ShowPlanCommand()); // Просмотреть детали конкретного плана
    addSubcommand(RespondWithPlanCommand()); // Создать лицензию на основе плана
  }

  @override
  void run() {
    // Этот метод вызывается, если пользователь набрал только `licensify flow` без подкоманды
    if (argResults?.rest.isEmpty ?? true) {
      print('Клиентский процесс лицензирования.');
      print('Для получения лицензии выполните следующие шаги:');
      print('');
      print('1. Просмотрите доступные планы лицензий:');
      print('   licensify flow list --app-id APPID');
      print('');
      print('2. Просмотрите детали конкретного плана:');
      print('   licensify flow plan --id PLAN_ID --app-id APPID');
      print('');
      print('3. Создайте запрос на лицензию:');
      print(
        '   licensify flow request --appId APPID --publicKey PATH_TO_PUBLIC_KEY --output request.bin',
      );
      print('');
      print('4. Отправьте файл запроса поставщику лицензии.');
      print(
        '   Провайдер лицензии может использовать команду для создания лицензии на основе плана:',
      );
      print(
        '   licensify license respond-with-plan --requestFile request.bin --privateKey private.pem --planId PLAN_ID --app-id APPID',
      );
      print('');
      print('5. После получения лицензии проверьте её:');
      print(
        '   licensify flow verify --license PATH_TO_LICENSE --publicKey PATH_TO_PUBLIC_KEY',
      );
      print('');
      print('6. Просмотрите информацию о лицензии:');
      print('   licensify flow show --license PATH_TO_LICENSE');
      print('');
      print(
        'Для получения дополнительной информации по конкретной команде используйте:',
      );
      print('licensify flow COMMAND --help');
    }
  }
}
