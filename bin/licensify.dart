#!/usr/bin/env dart
// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:io';
import 'package:args/command_runner.dart';

// Import commands
import 'commands/plans_commands.dart';
import 'commands/license_commands.dart';
import 'commands/flow_commands.dart';

void main(List<String> args) async {
  final runner =
      CommandRunner<void>(
          'licensify',
          'Tool for managing licenses and license plans',
        )
        // Add top-level commands
        ..addCommand(PlansCommand())
        ..addCommand(LicenseCommand())
        ..addCommand(FlowCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64); // command line usage error
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
