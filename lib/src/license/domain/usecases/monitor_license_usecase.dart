// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:async';

import 'package:licensify/licensify.dart';

/// Use case for monitoring license status over time
///
/// This class provides continuous license state monitoring with periodic checks,
/// notifying subscribers of any changes through a stream.
class MonitorLicenseUseCase {
  final CheckLicenseUseCase _checkLicenseUseCase;

  /// Default license check period (1 day)
  static const _defaultCheckPeriod = Duration(days: 1);

  /// Controller for broadcasting license status updates
  final _statusController = StreamController<LicenseStatus>.broadcast();

  /// Timer for periodic license validation
  Timer? _checkTimer;

  /// Most recent license status
  LicenseStatus? _lastKnownStatus;

  /// Creates a new license monitor with the provided license checker
  MonitorLicenseUseCase({required CheckLicenseUseCase checkLicenseUseCase})
    : _checkLicenseUseCase = checkLicenseUseCase;

  /// Stream of license status updates
  ///
  /// Subscribe to this stream to be notified of license status changes
  Stream<LicenseStatus> get licenseStatusStream => _statusController.stream;

  /// Most recent license status
  LicenseStatus? get currentStatus => _lastKnownStatus;

  /// Starts periodic license monitoring
  ///
  /// [checkPeriod] - How often to check for license changes (default: 1 day)
  Future<void> startMonitoring({
    Duration checkPeriod = _defaultCheckPeriod,
  }) async {
    // Perform initial check immediately
    await _checkAndEmitStatus();

    // Set up periodic checking
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(checkPeriod, (_) => _checkAndEmitStatus());
  }

  /// Stops periodic license monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Checks license status and emits it to the stream
  Future<void> _checkAndEmitStatus() async {
    final status = await _checkLicenseUseCase.checkCurrentLicense();
    _lastKnownStatus = status;

    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Releases resources used by this use case
  void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}
