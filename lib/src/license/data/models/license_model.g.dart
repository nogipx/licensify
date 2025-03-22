// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'license_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LicenseModel _$LicenseModelFromJson(Map<String, dynamic> json) =>
    _LicenseModel(
      id: json['id'] as String,
      appId: json['appId'] as String,
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      signature: json['signature'] as String,
      type: json['type'] as String? ?? 'standard',
      features: json['features'] as Map<String, dynamic>? ?? const {},
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$LicenseModelToJson(_LicenseModel instance) =>
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
