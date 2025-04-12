// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:args/command_runner.dart';
import 'dart:convert';

/// Base class for all licensify commands
abstract class BaseCommand extends Command<void> {
  // Общие методы и функциональность для всех команд

  /// Handles errors and exits with appropriate code
  void handleError(String message) {
    final errorJson = JsonEncoder.withIndent(
      '  ',
    ).convert({'status': 'error', 'message': message});
    print(errorJson);
  }

  /// Validates application ID
  String? validateAppId(String appId) {
    // Check length
    if (appId.length < 3) {
      return 'Application ID should be at least 3 characters long';
    }

    if (appId.length > 100) {
      return 'Application ID should not exceed 100 characters';
    }

    // Check allowed characters (latin letters, numbers, dots, dashes, underscores)
    final validPattern = RegExp(r'^[a-zA-Z0-9\-_\.]+$');

    if (!validPattern.hasMatch(appId)) {
      return 'Application ID should contain only latin letters, numbers, and symbols -_. (for example, com.example.app)';
    }

    return null;
  }

  /// Validates license type value
  String? validateLicenseType(String licenseType) {
    // Check length
    if (licenseType.length < 2) {
      return 'License type should be at least 2 characters long';
    }

    if (licenseType.length > 100) {
      return 'License type should not exceed 100 characters';
    }

    // Check allowed characters (only latin letters and numbers)
    final validPattern = RegExp(r'^[a-zA-Z0-9\-_\.@]+$');

    if (!validPattern.hasMatch(licenseType)) {
      return 'License type should contain only latin letters, numbers, and symbols -_.@. No other special characters allowed.';
    }

    return null;
  }
}
