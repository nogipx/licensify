// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:args/command_runner.dart';
import 'dart:convert';
import 'license/_index.dart';
import 'plans/_index.dart';

/// Main command for client-side license operations
class ClientCommand extends Command<void> {
  @override
  final String name = 'client';

  @override
  final String description = 'Клиентский процесс лицензирования';

  ClientCommand() {
    // Добавляем подкоманды для клиентского процесса
    addSubcommand(RequestCommand()); // Создать запрос на лицензию
    addSubcommand(VerifyCommand()); // Проверить лицензию
    addSubcommand(ShowLicenseCommand()); // Показать информацию о лицензии
    addSubcommand(ListPlansCommand()); // Просмотреть доступные планы лицензий
    addSubcommand(ShowPlanCommand()); // Просмотреть детали конкретного плана
  }

  @override
  void run() {
    // Этот метод вызывается, если пользователь набрал только `licensify client` без подкоманды
    if (argResults?.rest.isEmpty ?? true) {
      final helpData = {
        'status': 'info',
        'message': 'Клиентский процесс лицензирования',
        'workflow': [
          {
            'step': 1,
            'description': 'Просмотрите доступные планы лицензий',
            'command': 'licensify client list-plans --app-id APPID',
          },
          {
            'step': 2,
            'description': 'Просмотрите детали конкретного плана',
            'command': 'licensify client plan --id PLAN_ID --app-id APPID',
          },
          {
            'step': 3,
            'description': 'Создайте запрос на лицензию',
            'command':
                'licensify client request --appId APPID --publicKey PATH_TO_PUBLIC_KEY --output request.bin',
          },
          {
            'step': 4,
            'description': 'Отправьте файл запроса поставщику лицензии',
            'command': null,
          },
          {
            'step': 5,
            'description': 'После получения лицензии проверьте её',
            'command':
                'licensify client verify --license PATH_TO_LICENSE --publicKey PATH_TO_PUBLIC_KEY',
          },
          {
            'step': 6,
            'description': 'Просмотрите информацию о лицензии',
            'command': 'licensify client show --license PATH_TO_LICENSE',
          },
        ],
        'help': 'licensify client COMMAND --help',
      };
      print(JsonEncoder.withIndent('  ').convert(helpData));
    }
  }
}
