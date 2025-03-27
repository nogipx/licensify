// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// Extension methods for DateTime to support license operations
extension LicensifyDateTimeExtensions on DateTime {
  /// Rounds the datetime to minutes (removing seconds and milliseconds)
  /// and converts to UTC
  ///
  /// This is useful for producing consistent datetime values for license validation
  /// where precision to the second is not necessary.
  ///
  /// Returns a new DateTime in UTC with seconds and smaller units set to zero
  DateTime roundToMinutes() {
    final utcDate = isUtc ? this : toUtc();
    return DateTime.utc(
      utcDate.year,
      utcDate.month,
      utcDate.day,
      utcDate.hour,
      utcDate.minute,
      0, // seconds = 0
      0, // milliseconds = 0
      0, // microseconds = 0
    );
  }

  /// Calculates days remaining until this date from the current time
  ///
  /// Returns the number of days remaining (can be negative if date is in the past)
  int get daysRemaining {
    final now = DateTime.now();
    return difference(now).inDays;
  }

  /// Checks if this date is in the past
  ///
  /// Returns true if the date has passed, false otherwise
  bool get isPast => isBefore(DateTime.now());
}
