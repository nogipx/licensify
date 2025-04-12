// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/src/license/domain/entities/license.dart';
import 'package:licensify/src/license/domain/entities/license_request.dart';
import 'package:licensify/src/license/domain/entities/license_schema.dart';
import 'package:licensify/src/license/domain/entities/validation_result.dart';
import 'package:licensify/src/manage/feature_config.dart';
import 'package:licensify/src/manage/license_plan.dart';
import 'package:licensify/src/manage/license_plan_repository.dart';
import 'package:licensify/src/manage/metadata_config.dart';

/// Результат операции с планом лицензии
///
/// License plan operation result
class PlanOperationResult<T> {
  /// Успешность операции
  ///
  /// Operation success
  final bool success;

  /// Сообщение
  ///
  /// Message
  final String message;

  /// Данные результата
  ///
  /// Result data
  final T? data;

  /// Создает успешный результат
  ///
  /// Creates a successful result
  const PlanOperationResult.success(this.message, [this.data]) : success = true;

  /// Создает неудачный результат
  ///
  /// Creates a failed result
  const PlanOperationResult.failure(this.message)
    : success = false,
      data = null;
}

/// Сервис для работы с планами лицензий
///
/// License plan service
class LicensePlanService {
  /// Репозиторий планов лицензий
  ///
  /// License plan repository
  final LicensePlanRepository _repository;

  /// Идентификатор приложения
  ///
  /// Application identifier
  final String appId;

  /// Создает сервис для работы с планами лицензий
  ///
  /// Creates a license plan service
  LicensePlanService({
    required this.appId,
    required LicensePlanRepository repository,
  }) : _repository = repository;

  /// Добавляет план лицензии
  ///
  /// Adds a license plan
  PlanOperationResult<LicensePlan> addPlan(LicensePlan plan) {
    try {
      _repository.save(plan);
      return PlanOperationResult.success(
        'План "${plan.name}" (${plan.id}) добавлен успешно',
        plan,
      );
    } catch (e) {
      return PlanOperationResult.failure('Ошибка при добавлении плана: $e');
    }
  }

  /// Удаляет план лицензии
  ///
  /// Removes a license plan
  PlanOperationResult<String> removePlan(String planId) {
    final plan = _repository.getById(planId);

    if (plan == null) {
      return PlanOperationResult.failure('План с ID "$planId" не найден');
    }

    final success = _repository.remove(planId);

    if (success) {
      return PlanOperationResult.success(
        'План "${plan.name}" (${plan.id}) удален успешно',
        planId,
      );
    } else {
      return PlanOperationResult.failure('Не удалось удалить план');
    }
  }

  /// Получает все планы
  ///
  /// Gets all plans
  List<LicensePlan> getAllPlans() => _repository.getAll();

  /// Получает план по идентификатору
  ///
  /// Gets a plan by identifier
  LicensePlan? getPlan(String planId) => _repository.getById(planId);

  /// Получает публичные планы
  ///
  /// Gets public plans
  List<LicensePlan> getPublicPlans() => _repository.getPublicPlans();

  /// Получает пробные планы
  ///
  /// Gets trial plans
  List<LicensePlan> getTrialPlans() => _repository.getTrialPlans();

  /// Экспортирует планы в строку
  ///
  /// Exports plans to string
  String exportToString() => _repository.exportToString();

  /// Экспортирует планы в Base64
  ///
  /// Exports plans to Base64
  String exportToBase64() => _repository.exportToBase64();

  /// Импортирует планы из строки
  ///
  /// Imports plans from string
  PlanOperationResult<void> importFromString(String data) {
    try {
      _repository.importFromString(data);
      return PlanOperationResult.success('Планы успешно импортированы');
    } catch (e) {
      return PlanOperationResult.failure('Ошибка при импорте планов: $e');
    }
  }

  /// Импортирует планы из Base64
  ///
  /// Imports plans from Base64
  PlanOperationResult<void> importFromBase64(String base64String) {
    try {
      _repository.importFromBase64(base64String);
      return PlanOperationResult.success(
        'Планы успешно импортированы из Base64',
      );
    } catch (e) {
      return PlanOperationResult.failure(
        'Ошибка при импорте планов из Base64: $e',
      );
    }
  }

  /// Получает тип-безопасный доступ к полю фичи
  ///
  /// Gets type-safe access to a feature field
  T getFeature<T>(License license, FeatureConfig<T> config) {
    final value = license.features[config.key];
    return value != null ? config.fromJson(value) : config.defaultValue;
  }

  /// Получает тип-безопасный доступ к полю метаданных
  ///
  /// Gets type-safe access to a metadata field
  T? getMetadata<T>(License license, MetadataConfig<T> config) {
    if (license.metadata == null) return null;
    final value = license.metadata![config.key];
    return value != null ? config.fromJson(value) : null;
  }

  /// Создает типобезопасное значение фичи для JSON
  ///
  /// Creates type-safe feature value for JSON
  Object? createFeatureValue<T>(FeatureConfig<T> config, T value) {
    return config.toJson(value);
  }

  /// Создает типобезопасное значение метаданных для JSON
  ///
  /// Creates type-safe metadata value for JSON
  Object? createMetadataValue<T>(MetadataConfig<T> config, T value) {
    return config.toJson(value);
  }

  /// Создает карту значений фич для лицензии
  ///
  /// Creates a map of feature values for license
  Map<String, dynamic> createFeaturesMap(
    List<MapEntry<FeatureConfig, dynamic>> features,
  ) {
    final result = <String, dynamic>{};

    for (final entry in features) {
      final config = entry.key;
      final value = entry.value;
      result[config.key] = config.toJson(value);
    }

    return Map.unmodifiable(result);
  }

  /// Создает карту значений метаданных для лицензии
  ///
  /// Creates a map of metadata values for license
  Map<String, dynamic> createMetadataMap(
    List<MapEntry<MetadataConfig, dynamic>> metadata,
  ) {
    final result = <String, dynamic>{};

    for (final entry in metadata) {
      final config = entry.key;
      final value = entry.value;
      result[config.key] = config.toJson(value);
    }

    return Map.unmodifiable(result);
  }

  /// Проверяет валидность лицензии для конкретного плана
  ///
  /// Validates a license for a specific plan
  ValidationResult validateLicenseForPlan(License license, String planId) {
    final plan = _repository.getById(planId);

    if (plan == null) {
      return ValidationResult.invalid('Unknown license plan: $planId');
    }

    // Проверяем, что лицензия для нашего приложения
    if (license.appId != appId) {
      return ValidationResult.invalid(
        'License is for app ${license.appId}, expected $appId',
      );
    }

    // Проверяем, не истек ли срок действия
    if (license.isExpired) {
      return ValidationResult.invalid(
        'License has expired on ${license.expirationDate}',
      );
    }

    // Проверяем соответствие схеме
    final schemaResult = plan.toSchema().validateLicense(license);
    if (!schemaResult.isValid) {
      return ValidationResult.invalid(
        'License does not match plan schema: ${schemaResult.errors}',
      );
    }

    return ValidationResult.valid();
  }

  /// Создает запрос на лицензию для конкретного плана
  ///
  /// Creates a license request for a specific plan
  LicenseRequest? createRequestForPlan(
    String planId,
    String deviceHash, {
    required DateTime createdAt,
    required DateTime expireAt,
  }) {
    final plan = _repository.getById(planId);
    if (plan == null) return null;

    return LicenseRequest(
      deviceHash: deviceHash,
      appId: appId,
      createdAt: createdAt,
      expiresAt: expireAt,
    );
  }

  /// Создает схему лицензии, включающую все планы
  ///
  /// Creates a license schema that includes all plans
  LicenseSchema createCombinedSchema({
    bool allowUnknownFeatures = true,
    bool allowUnknownMetadata = true,
  }) {
    final featureSchema = <String, SchemaField>{};
    final metadataSchema = <String, SchemaField>{};

    for (final plan in _repository.getAll()) {
      // Объединяем схемы фич
      for (final feature in plan.features) {
        featureSchema[feature.key] = feature.schema;
      }

      // Объединяем схемы метаданных
      for (final field in plan.metadata) {
        metadataSchema[field.key] = field.schema;
      }
    }

    return LicenseSchema(
      featureSchema: featureSchema,
      metadataSchema: metadataSchema,
      allowUnknownFeatures: allowUnknownFeatures,
      allowUnknownMetadata: allowUnknownMetadata,
    );
  }
}
