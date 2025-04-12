// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:args/command_runner.dart';
import 'plans/_index.dart';

/// Main command for license plans management
class PlansCommand extends Command<void> {
  @override
  final String name = 'plans';

  @override
  final String description = 'Управление планами лицензий';

  PlansCommand() {
    // Добавляем подкоманды для работы с планами
    addSubcommand(ListPlansCommand());
    addSubcommand(CreatePlanCommand());
    addSubcommand(ShowPlanCommand());
    addSubcommand(RemovePlanCommand());
    addSubcommand(ExportPlansCommand());
    addSubcommand(ImportPlansCommand());
  }

  @override
  void run() {
    // Этот метод вызывается, если пользователь набрал только `licensify plans` без подкоманды
    if (argResults?.rest.isEmpty ?? true) {
      print(usage);
    }
  }
}
