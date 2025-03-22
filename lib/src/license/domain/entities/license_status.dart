// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'license.dart';

/// Базовый класс статуса лицензии
abstract class LicenseStatus {
  const LicenseStatus();

  /// Возвращает true, если лицензия активна
  bool get isActive => this is ActiveLicenseStatus;

  /// Возвращает true, если лицензия истекла
  bool get isExpired => this is ExpiredLicenseStatus;

  /// Возвращает true, если нет лицензии
  bool get isNoLicense => this is NoLicenseStatus;

  /// Возвращает true, если лицензия недействительна
  bool get isInvalid => this is InvalidLicenseStatus;

  /// Возвращает true, если произошла ошибка
  bool get isError => this is ErrorLicenseStatus;

  /// Возвращает лицензию, если она есть
  License? get license =>
      this is ActiveLicenseStatus
          ? (this as ActiveLicenseStatus).license
          : this is ExpiredLicenseStatus
          ? (this as ExpiredLicenseStatus).license
          : null;
}

/// Нет лицензии
class NoLicenseStatus extends LicenseStatus {
  const NoLicenseStatus();
}

/// Лицензия активна
class ActiveLicenseStatus extends LicenseStatus {
  @override
  final License license;
  const ActiveLicenseStatus(this.license);
}

/// Лицензия истекла
class ExpiredLicenseStatus extends LicenseStatus {
  @override
  final License license;
  const ExpiredLicenseStatus(this.license);
}

/// Лицензия недействительна
class InvalidLicenseStatus extends LicenseStatus {
  final String? message;
  const InvalidLicenseStatus({this.message});
}

/// Ошибка при проверке лицензии
class ErrorLicenseStatus extends LicenseStatus {
  final String message;
  final Object? exception;
  const ErrorLicenseStatus({required this.message, this.exception});
}
