// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:async';

import 'package:licensify/licensify.dart';

/// Сценарий использования для мониторинга статуса лицензии
class MonitorLicenseUseCase {
  final CheckLicenseUseCase _checkLicenseUseCase;

  /// Период проверки лицензии по умолчанию (1 день)
  static const _defaultCheckPeriod = Duration(days: 1);

  /// Контроллер для статуса лицензии
  final _statusController = StreamController<LicenseStatus>.broadcast();

  /// Таймер для периодической проверки
  Timer? _checkTimer;

  /// Последний известный статус
  LicenseStatus? _lastKnownStatus;

  /// Конструктор
  MonitorLicenseUseCase({required CheckLicenseUseCase checkLicenseUseCase})
    : _checkLicenseUseCase = checkLicenseUseCase;

  /// Поток статуса лицензии
  Stream<LicenseStatus> get licenseStatusStream => _statusController.stream;

  /// Последний известный статус лицензии
  LicenseStatus? get currentStatus => _lastKnownStatus;

  /// Начинает мониторинг лицензии
  Future<void> startMonitoring({Duration checkPeriod = _defaultCheckPeriod}) async {
    // Проверяем текущую лицензию немедленно
    await _checkAndEmitStatus();

    // Настраиваем периодическую проверку
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(checkPeriod, (_) => _checkAndEmitStatus());
  }

  /// Останавливает мониторинг
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Проверяет статус лицензии и отправляет его в поток
  Future<void> _checkAndEmitStatus() async {
    final status = await _checkLicenseUseCase.checkCurrentLicense();
    _lastKnownStatus = status;

    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Освобождает ресурсы
  void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}
