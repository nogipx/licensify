// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Расширение для работы с датами в контексте лицензий
extension DateTimeExtensions on DateTime {
  /// Округляет дату до минут, обнуляя секунды и миллисекунды
  /// и возвращает UTC дату
  DateTime roundToMinutes() {
    final utcDate = isUtc ? this : toUtc();
    return DateTime.utc(
      utcDate.year,
      utcDate.month,
      utcDate.day,
      utcDate.hour,
      utcDate.minute,
      0, // секунды = 0
      0, // миллисекунды = 0
      0, // микросекунды = 0
    );
  }
}
