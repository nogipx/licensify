// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:args/command_runner.dart';
import 'license/_index.dart';

/// Main command for license operations
class LicenseCommand extends Command<void> {
  @override
  final String name = 'license';

  @override
  final String description = 'Операции с лицензиями';

  LicenseCommand() {
    // Добавляем подкоманды для работы с лицензиями
    addSubcommand(KeygenCommand());
    addSubcommand(GenerateCommand());
    addSubcommand(VerifyCommand());
    addSubcommand(ShowLicenseCommand());
    addSubcommand(RequestCommand());
    addSubcommand(DecryptRequestCommand());
    addSubcommand(RespondCommand());
    addSubcommand(RespondWithPlanCommand());
  }

  @override
  void run() {
    // Этот метод вызывается, если пользователь набрал только `licensify license` без подкоманды
    if (argResults?.rest.isEmpty ?? true) {
      print(usage);
    }
  }
}
