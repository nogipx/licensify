// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/src/license/domain/entities/license_type.dart';
import 'package:licensify/src/manage/feature_config.dart';
import 'package:licensify/src/manage/license_plan.dart';
import 'package:licensify/src/manage/metadata_config.dart';

/// Конструктор плана лицензии с типобезопасными методами
///
/// License plan builder with type-safe methods
class LicensePlanBuilder {
  /// Идентификатор плана
  ///
  /// Plan identifier
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

  /// Идентификатор приложения
  ///
  /// Application identifier
  String _appId = '';

  /// Конфигурации фич
  ///
  /// Feature configurations
  final List<FeatureConfig> _features = [];

  /// Конфигурации метаданных
  ///
  /// Metadata configurations
  final List<MetadataConfig> _metadata = [];

  /// Срок действия лицензии в днях
  ///
  /// License duration in days
  int? _durationDays;

  /// Является ли план публичным
  ///
  /// Whether the plan is public
  bool _isPublic = true;

  /// Приоритет плана
  ///
  /// Plan priority
  int _priority = 100;

  /// Цена плана
  ///
  /// Plan price
  num _price = 0;

  /// Является ли план пробным
  ///
  /// Whether this is a trial plan
  bool _isTrial = false;

  /// Создает новый конструктор плана лицензии
  ///
  /// Creates a new license plan builder
  LicensePlanBuilder({
    required this.id,
    required this.name,
    required this.description,
    required this.licenseType,
    String appId = '',
  }) : _appId = appId;

  /// Добавляет фичу в план
  ///
  /// Adds a feature to the plan
  LicensePlanBuilder addFeature<T>(FeatureConfig<T> feature) {
    _features.add(feature);
    return this;
  }

  /// Добавляет метаданные в план
  ///
  /// Adds metadata to the plan
  LicensePlanBuilder addMetadata<T>(MetadataConfig<T> metadata) {
    _metadata.add(metadata);
    return this;
  }

  /// Устанавливает срок действия лицензии в днях
  ///
  /// Sets the license duration in days
  LicensePlanBuilder withDuration(int days) {
    _durationDays = days;
    return this;
  }

  /// Создает бессрочную лицензию
  ///
  /// Creates a permanent license
  LicensePlanBuilder permanent() {
    _durationDays = null;
    return this;
  }

  /// Устанавливает публичность плана
  ///
  /// Sets plan visibility
  LicensePlanBuilder setPublic(bool isPublic) {
    _isPublic = isPublic;
    return this;
  }

  /// Устанавливает приоритет плана
  ///
  /// Sets plan priority
  LicensePlanBuilder setPriority(int priority) {
    _priority = priority;
    return this;
  }

  /// Устанавливает цену плана
  ///
  /// Sets plan price
  LicensePlanBuilder setPrice(num price) {
    _price = price;
    return this;
  }

  /// Устанавливает признак пробного плана
  ///
  /// Sets trial plan flag
  LicensePlanBuilder setTrial(bool isTrial) {
    _isTrial = isTrial;
    return this;
  }

  /// Устанавливает идентификатор приложения
  ///
  /// Sets application identifier
  LicensePlanBuilder setAppId(String appId) {
    _appId = appId;
    return this;
  }

  /// Строит план лицензии
  ///
  /// Builds the license plan
  LicensePlan build() {
    if (_appId.isEmpty) {
      throw ArgumentError('Application ID (appId) must be set');
    }

    return LicensePlan(
      id: id,
      name: name,
      description: description,
      licenseType: licenseType,
      appId: _appId,
      features: List.unmodifiable(_features),
      metadata: List.unmodifiable(_metadata),
      durationDays: _durationDays,
      isPublic: _isPublic,
      priority: _priority,
      price: _price,
      isTrial: _isTrial,
    );
  }
}
