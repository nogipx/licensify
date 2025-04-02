// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';

/// License request model
///
/// Contains data required to identify a device
/// and generate a license on the server.
class LicenseRequest {
  /// Magic header for license request
  static const magicHeader = 'LCRQ';

  /// Device data hash
  final String deviceHash;

  /// Application identifier
  final String appId;

  /// Creation date and time
  final DateTime createdAt;

  /// Expiration date and time
  final DateTime expiresAt;

  /// Creates a new license request
  ///
  /// [deviceHash] - Hash of unique device data
  /// [appId] - Application identifier
  /// [createdAt] - Creation date and time
  /// [expiresAt] - Expiration date and time
  const LicenseRequest({
    required this.deviceHash,
    required this.appId,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Checks if the request has expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Converts request to JSON
  Map<String, dynamic> toJson() => {
    'deviceHash': deviceHash,
    'appId': appId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };

  /// Creates a request from JSON
  factory LicenseRequest.fromJson(Map<String, dynamic> json) {
    return LicenseRequest(
      deviceHash: json['deviceHash'] as String,
      appId: json['appId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Converts request to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Creates a request from JSON string
  factory LicenseRequest.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return LicenseRequest.fromJson(json);
  }
}
