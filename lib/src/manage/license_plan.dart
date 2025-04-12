// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';

import 'package:licensify/src/license/domain/entities/license_schema.dart';
import 'package:licensify/src/license/domain/entities/license_type.dart';
import 'package:licensify/src/manage/feature_config.dart';
import 'package:licensify/src/manage/metadata_config.dart';

/// План лицензии, определяющий доступные опции и их настройки
///
/// License plan defining available options and their settings
class LicensePlan {
  /// Уникальный идентификатор плана
  ///
  /// Unique identifier for the plan
  final String id;

  /// Название плана
  ///
  /// Plan name
  final String name;

  /// Описание плана
  ///
  /// Plan description
  final String description;

  /// Тип лицензии
  ///
  /// License type
  final LicenseType licenseType;

  /// Конфигурации фич, доступных в этом плане
  ///
  /// Feature configurations available in this plan
  final List<FeatureConfig> features;

  /// Конфигурации метаданных, поддерживаемых в этом плане
  ///
  /// Metadata configurations supported in this plan
  final List<MetadataConfig> metadata;

  /// Срок действия лицензии в днях (null = бессрочная)
  ///
  /// License duration in days (null = permanent)
  final int? durationDays;

  /// Является ли план публичным (доступным для показа клиентам)
  ///
  /// Whether the plan is public (available for customers to see)
  final bool isPublic;

  /// Приоритет плана для сортировки
  ///
  /// Priority for sorting plans
  final int priority;

  /// Цена плана
  ///
  /// Plan price
  final num price;

  /// Является ли пробным планом
  ///
  /// Whether this is a trial plan
  final bool isTrial;

  /// Идентификатор приложения, к которому относится план
  ///
  /// Application identifier for the plan
  final String appId;

  /// Создает план лицензии
  ///
  /// Creates a license plan
  const LicensePlan({
    required this.id,
    required this.name,
    required this.description,
    required this.licenseType,
    required this.appId,
    this.features = const [],
    this.metadata = const [],
    this.durationDays,
    this.isPublic = true,
    this.priority = 100,
    this.price = 0,
    this.isTrial = false,
  });

  /// Получает схему лицензии на основе этого плана
  ///
  /// Gets a license schema based on this plan
  LicenseSchema toSchema({
    bool allowUnknownFeatures = false,
    bool allowUnknownMetadata = true,
  }) {
    final featureSchema = <String, SchemaField>{};
    final metadataSchema = <String, SchemaField>{};

    // Добавляем схемы для фич
    for (final feature in features) {
      featureSchema[feature.key] = feature.schema;
    }

    // Добавляем схемы для метаданных
    for (final field in metadata) {
      metadataSchema[field.key] = field.schema;
    }

    return LicenseSchema(
      featureSchema: featureSchema,
      metadataSchema: metadataSchema,
      allowUnknownFeatures: allowUnknownFeatures,
      allowUnknownMetadata: allowUnknownMetadata,
    );
  }

  /// Создает настройки фич по умолчанию
  ///
  /// Creates default feature settings
  Map<String, dynamic> createDefaultFeatures() {
    final result = <String, dynamic>{};

    for (final feature in features) {
      result[feature.key] = feature.toJson(feature.defaultValue);
    }

    return result;
  }

  /// Преобразует план в JSON-объект
  ///
  /// Converts plan to JSON object
  Map<String, dynamic> toJson() {
    final featureConfigs = <String, dynamic>{};

    // Опциональная сериализация конфигураций фич могла бы быть добавлена здесь
    // Пока используем пустой объект, так как в примере нет данных фич

    return {
      'id': id,
      'name': name,
      'description': description,
      'durationDays': durationDays,
      'features': featureConfigs,
      'isPublic': isPublic,
      'priority': priority,
      'price': price,
      'isTrial': isTrial,
      'appId': appId,
    };
  }

  /// Сериализует план в JSON строку
  ///
  /// Serializes plan to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Создает план из JSON-объекта
  ///
  /// Creates a plan from JSON object
  factory LicensePlan.fromJson(Map<String, dynamic> json) {
    return LicensePlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      licenseType: LicenseType.standard,
      appId: json['appId'] as String,
      durationDays: json['durationDays'] as int?,
      isPublic: json['isPublic'] as bool? ?? true,
      priority: json['priority'] as int? ?? 100,
      price: json['price'] as num? ?? 0,
      isTrial: json['isTrial'] as bool? ?? false,
      // Здесь можно добавить десериализацию фич и метаданных,
      // но пока оставляем их пустыми
    );
  }

  /// Создает план из JSON строки
  ///
  /// Creates a plan from JSON string
  factory LicensePlan.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return LicensePlan.fromJson(json);
  }

  /// Создает копию этого плана с опциональными изменениями
  ///
  /// Creates a copy of this plan with optional changes
  LicensePlan copyWith({
    String? id,
    String? name,
    String? description,
    LicenseType? licenseType,
    List<FeatureConfig>? features,
    List<MetadataConfig>? metadata,
    int? durationDays,
    bool clearDuration = false,
    bool? isPublic,
    int? priority,
    num? price,
    bool? isTrial,
    String? appId,
  }) {
    return LicensePlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      licenseType: licenseType ?? this.licenseType,
      appId: appId ?? this.appId,
      features: features ?? this.features,
      metadata: metadata ?? this.metadata,
      durationDays: clearDuration ? null : (durationDays ?? this.durationDays),
      isPublic: isPublic ?? this.isPublic,
      priority: priority ?? this.priority,
      price: price ?? this.price,
      isTrial: isTrial ?? this.isTrial,
    );
  }
}
