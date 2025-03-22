// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'license_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LicenseModelImpl _$$LicenseModelImplFromJson(Map<String, dynamic> json) =>
    _$LicenseModelImpl(
      id: json['id'] as String,
      appId: json['appId'] as String,
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      signature: json['signature'] as String,
      type: json['type'] as String? ?? 'standard',
      features: json['features'] as Map<String, dynamic>? ?? const {},
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$LicenseModelImplToJson(_$LicenseModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appId': instance.appId,
      'expirationDate': instance.expirationDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'signature': instance.signature,
      'type': instance.type,
      'features': instance.features,
      'metadata': instance.metadata,
    };
