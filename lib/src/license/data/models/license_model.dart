// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:licensify/licensify.dart';

part 'license_model.freezed.dart';
part 'license_model.g.dart';

/// Модель данных лицензии
@freezed
class LicenseModel with _$LicenseModel {
  const LicenseModel._();

  const factory LicenseModel({
    /// Уникальный идентификатор лицензии
    required String id,

    /// Идентификатор приложения, для которого действует лицензия
    required String appId,

    /// Дата истечения срока действия лицензии
    required DateTime expirationDate,

    /// Дата создания лицензии
    required DateTime createdAt,

    /// Подпись лицензии для проверки подлинности
    required String signature,

    /// Тип лицензии (например, trial, standard, pro)
    @Default('standard') String type,

    /// Доступные функции или ограничения для данной лицензии
    @Default({}) Map<String, dynamic> features,

    /// Дополнительные метаданные лицензии
    Map<String, dynamic>? metadata,
  }) = _LicenseModel;

  /// Создаёт объект модели из JSON
  factory LicenseModel.fromJson(Map<String, dynamic> json) => _$LicenseModelFromJson(json);

  /// Преобразование из доменной сущности
  factory LicenseModel.fromDomain(License license) => LicenseModel(
    id: license.id,
    appId: license.appId,
    expirationDate: license.expirationDate,
    createdAt: license.createdAt,
    signature: license.signature,
    type: license.type.name,
    features: license.features,
    metadata: license.metadata,
  );

  /// Получает доменную сущность из модели
  License toDomain() => License(
    id: id,
    appId: appId,
    expirationDate: expirationDate,
    createdAt: createdAt,
    signature: signature,
    type: LicenseType.values.firstWhere((e) => e.name == type, orElse: () => LicenseType.trial),
    features: features,
    metadata: metadata,
  );
}
