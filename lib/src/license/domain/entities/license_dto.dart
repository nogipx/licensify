// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// License data transfer object
class LicenseDto {
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

  /// Flag indicating if this is a trial license
  final bool isTrial;

  /// Creates a new license DTO instance
  const LicenseDto({
    required this.id,
    required this.appId,
    required this.expirationDate,
    required this.createdAt,
    required this.signature,
    this.type = 'standard',
    this.features = const {},
    this.metadata,
    this.isTrial = false,
  });

  /// Converts from domain entity
  factory LicenseDto.fromDomain(License license) =>
      LicenseMapper.toDto(license);

  /// Gets a domain entity from the DTO
  License toDomain() => LicenseMapper.toDomain(this);

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
    'isTrial': isTrial,
  };

  /// Creates a DTO object from JSON
  factory LicenseDto.fromJson(Map<String, dynamic> json) {
    return LicenseDto(
      id: json['id'] as String,
      appId: json['appId'] as String,
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      signature: json['signature'] as String,
      type: (json['type'] as String?) ?? 'standard',
      features: (json['features'] as Map<String, dynamic>?) ?? const {},
      metadata: json['metadata'] as Map<String, dynamic>?,
      isTrial: (json['isTrial'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LicenseDto &&
        other.id == id &&
        other.appId == appId &&
        other.expirationDate == expirationDate &&
        other.createdAt == createdAt &&
        other.signature == signature &&
        other.type == type &&
        _mapsEqual(other.features, features) &&
        _mapsEqual(other.metadata, metadata) &&
        other.isTrial == isTrial;
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
      isTrial,
    );
  }

  @override
  String toString() {
    return 'LicenseDto(id: $id, appId: $appId, expirationDate: $expirationDate, '
        'createdAt: $createdAt, signature: $signature, type: $type, '
        'features: $features, metadata: $metadata, isTrial: $isTrial)';
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
