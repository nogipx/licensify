// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:licensify/licensify.dart';

part 'license_model.freezed.dart';
part 'license_model.g.dart';

/// License data model
@freezed
sealed class LicenseModel with _$LicenseModel {
  const LicenseModel._();

  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory LicenseModel({
    /// Unique license identifier
    required String id,

    /// Application identifier this license is valid for
    required String appId,

    /// License expiration date
    required DateTime expirationDate,

    /// License creation date
    required DateTime createdAt,

    /// Cryptographic signature for license verification
    required String signature,

    /// License type name (e.g., trial, standard, pro, or custom)
    @Default('standard') String type,

    /// Available features or limitations for this license
    @Default({}) Map<String, dynamic> features,

    /// Additional license metadata
    Map<String, dynamic>? metadata,
  }) = _LicenseModel;

  /// Creates a model object from JSON
  factory LicenseModel.fromJson(Map<String, dynamic> json) =>
      _$LicenseModelFromJson(json);

  /// Converts from domain entity
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

  /// Gets a domain entity from the model
  License toDomain() => License(
    id: id,
    appId: appId,
    expirationDate: expirationDate,
    createdAt: createdAt,
    signature: signature,
    type: _typeFromString(type),
    features: features,
    metadata: metadata,
  );

  /// Converts string type to LicenseType object
  ///
  /// Uses predefined types if the name matches, otherwise creates a custom type
  LicenseType _typeFromString(String typeName) {
    // Check standard types first
    if (typeName == LicenseType.trial.name) return LicenseType.trial;
    if (typeName == LicenseType.standard.name) return LicenseType.standard;
    if (typeName == LicenseType.pro.name) return LicenseType.pro;

    // Create custom type if no standard type matches
    return LicenseType(typeName);
  }
}
