// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

final class LicenseFormatException implements Exception {
  const LicenseFormatException(this.message, [this.stackTrace]);
  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'LicenseFormatException: $message\n$stackTrace';
  }
}
