// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// License data model
class LicenseModel {
  /// Unique license identifier
  final String id;

  /// Application identifier this license is valid for
  final String appId;

  /// License expiration date
  final DateTime expirationDate;

  /// License creation date
  final DateTime createdAt;

  /// Cryptographic signature for license verification
  final String signature;

  /// License type name (e.g., trial, standard, pro, or custom)
  final String type;

  /// Available features or limitations for this license
  final Map<String, dynamic> features;

  /// Additional license metadata
  final Map<String, dynamic>? metadata;

  /// Creates a new license model instance
  const LicenseModel({
    required this.id,
    required this.appId,
    required this.expirationDate,
    required this.createdAt,
    required this.signature,
    this.type = 'standard',
    this.features = const {},
    this.metadata,
  });

  /// Creates a model object from JSON
  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      id: json['id'] as String,
      appId: json['appId'] as String,
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      signature: json['signature'] as String,
      type: (json['type'] as String?) ?? 'standard',
      features: (json['features'] as Map<String, dynamic>?) ?? const {},
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

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

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {
    'id': id,
    'appId': appId,
    'expirationDate': expirationDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'signature': signature,
    'type': type,
    'features': features,
    'metadata': metadata,
  };

  /// Creates a copy of this instance with optional changes
  LicenseModel copyWith({
    String? id,
    String? appId,
    DateTime? expirationDate,
    DateTime? createdAt,
    String? signature,
    String? type,
    Map<String, dynamic>? features,
    Object? metadata = const _Unset(),
  }) {
    return LicenseModel(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      expirationDate: expirationDate ?? this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
      signature: signature ?? this.signature,
      type: type ?? this.type,
      features: features ?? this.features,
      metadata:
          metadata is _Unset
              ? this.metadata
              : metadata as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LicenseModel &&
        other.id == id &&
        other.appId == appId &&
        other.expirationDate == expirationDate &&
        other.createdAt == createdAt &&
        other.signature == signature &&
        other.type == type &&
        _mapsEqual(other.features, features) &&
        _mapsEqual(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      appId,
      expirationDate,
      createdAt,
      signature,
      type,
      Object.hashAll(features.entries),
      metadata != null ? Object.hashAll(metadata!.entries) : null,
    );
  }

  @override
  String toString() {
    return 'LicenseModel(id: $id, appId: $appId, expirationDate: $expirationDate, '
        'createdAt: $createdAt, signature: $signature, type: $type, '
        'features: $features, metadata: $metadata)';
  }

  /// Helper for comparing maps in operator ==
  bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }
}

/// Internal class for handling nullable field in copyWith
class _Unset {
  const _Unset();
}
