// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';

/// Модель запроса лицензии
///
/// Содержит данные, необходимые для идентификации устройства
/// и генерации лицензии на сервере.
class LicenseRequest {
  /// Магический заголовок для запроса лицензии
  static const magicHeader = 'LCRQ';

  /// Хеш данных устройства
  final String deviceHash;

  /// Идентификатор приложения
  final String appId;

  /// Дата и время создания запроса
  final DateTime createdAt;

  /// Дата и время истечения срока действия запроса
  final DateTime expiresAt;

  /// Создает новый запрос лицензии
  ///
  /// [deviceHash] - Хеш уникальных данных устройства
  /// [appId] - Идентификатор приложения
  /// [createdAt] - Дата и время создания запроса
  /// [expiresAt] - Дата и время истечения срока действия запроса
  const LicenseRequest({
    required this.deviceHash,
    required this.appId,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Конвертирует запрос в JSON
  Map<String, dynamic> toJson() => {
    'deviceHash': deviceHash,
    'appId': appId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };

  /// Создает запрос из JSON
  factory LicenseRequest.fromJson(Map<String, dynamic> json) {
    return LicenseRequest(
      deviceHash: json['deviceHash'] as String,
      appId: json['appId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Конвертирует запрос в JSON строку
  String toJsonString() => jsonEncode(toJson());

  /// Создает запрос из JSON строки
  factory LicenseRequest.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return LicenseRequest.fromJson(json);
  }
}
