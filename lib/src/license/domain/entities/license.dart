// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

/// Типы лицензий
enum LicenseType { trial, standard, pro }

/// Доменная сущность лицензии
class License {
  /// Уникальный идентификатор лицензии
  final String id;

  /// Идентификатор приложения, для которого действует лицензия
  final String appId;

  /// Дата истечения срока действия лицензии (UTC)
  final DateTime expirationDate;

  /// Дата создания лицензии (UTC)
  final DateTime createdAt;

  /// Подпись лицензии для проверки подлинности
  final String signature;

  /// Тип лицензии (trial - тестовая, standard - с ограничениями, pro - все фичи)
  final LicenseType type;

  /// Доступные функции или ограничения для данной лицензии
  final Map<String, dynamic> features;

  /// Дополнительные метаданные лицензии
  final Map<String, dynamic>? metadata;

  /// Конструктор
  License({
    required this.id,
    required this.appId,
    required DateTime expirationDate,
    required DateTime createdAt,
    required this.signature,
    this.type = LicenseType.trial,
    this.features = const {},
    this.metadata,
  }) : expirationDate = expirationDate.isUtc ? expirationDate : expirationDate.toUtc(),
       createdAt = createdAt.isUtc ? createdAt : createdAt.toUtc();

  /// Проверяет, истек ли срок действия лицензии
  bool get isExpired => DateTime.now().toUtc().isAfter(expirationDate);

  /// Возвращает оставшееся количество дней
  int get remainingDays => expirationDate.difference(DateTime.now().toUtc()).inDays;

  /// Преобразует лицензию в массив байтов
  Uint8List get bytes => utf8.encode(jsonEncode(toJson()));

  /// Преобразует лицензию в JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'appId': appId,
    'expirationDate': expirationDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'signature': signature,
    'type': type.name,
    'features': features,
    'metadata': metadata,
  };
}
