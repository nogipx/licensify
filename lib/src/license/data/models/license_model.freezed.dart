// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'license_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LicenseModel {

/// Unique license identifier
 String get id;/// Application identifier this license is valid for
 String get appId;/// License expiration date
 DateTime get expirationDate;/// License creation date
 DateTime get createdAt;/// Cryptographic signature for license verification
 String get signature;/// License type name (e.g., trial, standard, pro, or custom)
 String get type;/// Available features or limitations for this license
 Map<String, dynamic> get features;/// Additional license metadata
 Map<String, dynamic>? get metadata;
/// Create a copy of LicenseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LicenseModelCopyWith<LicenseModel> get copyWith => _$LicenseModelCopyWithImpl<LicenseModel>(this as LicenseModel, _$identity);

  /// Serializes this LicenseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LicenseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.expirationDate, expirationDate) || other.expirationDate == expirationDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.features, features)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appId,expirationDate,createdAt,signature,type,const DeepCollectionEquality().hash(features),const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'LicenseModel(id: $id, appId: $appId, expirationDate: $expirationDate, createdAt: $createdAt, signature: $signature, type: $type, features: $features, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $LicenseModelCopyWith<$Res>  {
  factory $LicenseModelCopyWith(LicenseModel value, $Res Function(LicenseModel) _then) = _$LicenseModelCopyWithImpl;
@useResult
$Res call({
 String id, String appId, DateTime expirationDate, DateTime createdAt, String signature, String type, Map<String, dynamic> features, Map<String, dynamic>? metadata
});




}
/// @nodoc
class _$LicenseModelCopyWithImpl<$Res>
    implements $LicenseModelCopyWith<$Res> {
  _$LicenseModelCopyWithImpl(this._self, this._then);

  final LicenseModel _self;
  final $Res Function(LicenseModel) _then;

/// Create a copy of LicenseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appId = null,Object? expirationDate = null,Object? createdAt = null,Object? signature = null,Object? type = null,Object? features = null,Object? metadata = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,expirationDate: null == expirationDate ? _self.expirationDate : expirationDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _LicenseModel extends LicenseModel {
  const _LicenseModel({required this.id, required this.appId, required this.expirationDate, required this.createdAt, required this.signature, this.type = 'standard', final  Map<String, dynamic> features = const {}, final  Map<String, dynamic>? metadata}): _features = features,_metadata = metadata,super._();
  factory _LicenseModel.fromJson(Map<String, dynamic> json) => _$LicenseModelFromJson(json);

/// Unique license identifier
@override final  String id;
/// Application identifier this license is valid for
@override final  String appId;
/// License expiration date
@override final  DateTime expirationDate;
/// License creation date
@override final  DateTime createdAt;
/// Cryptographic signature for license verification
@override final  String signature;
/// License type name (e.g., trial, standard, pro, or custom)
@override@JsonKey() final  String type;
/// Available features or limitations for this license
 final  Map<String, dynamic> _features;
/// Available features or limitations for this license
@override@JsonKey() Map<String, dynamic> get features {
  if (_features is EqualUnmodifiableMapView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_features);
}

/// Additional license metadata
 final  Map<String, dynamic>? _metadata;
/// Additional license metadata
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of LicenseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LicenseModelCopyWith<_LicenseModel> get copyWith => __$LicenseModelCopyWithImpl<_LicenseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LicenseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LicenseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.expirationDate, expirationDate) || other.expirationDate == expirationDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._features, _features)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appId,expirationDate,createdAt,signature,type,const DeepCollectionEquality().hash(_features),const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'LicenseModel(id: $id, appId: $appId, expirationDate: $expirationDate, createdAt: $createdAt, signature: $signature, type: $type, features: $features, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$LicenseModelCopyWith<$Res> implements $LicenseModelCopyWith<$Res> {
  factory _$LicenseModelCopyWith(_LicenseModel value, $Res Function(_LicenseModel) _then) = __$LicenseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String appId, DateTime expirationDate, DateTime createdAt, String signature, String type, Map<String, dynamic> features, Map<String, dynamic>? metadata
});




}
/// @nodoc
class __$LicenseModelCopyWithImpl<$Res>
    implements _$LicenseModelCopyWith<$Res> {
  __$LicenseModelCopyWithImpl(this._self, this._then);

  final _LicenseModel _self;
  final $Res Function(_LicenseModel) _then;

/// Create a copy of LicenseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appId = null,Object? expirationDate = null,Object? createdAt = null,Object? signature = null,Object? type = null,Object? features = null,Object? metadata = freezed,}) {
  return _then(_LicenseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,expirationDate: null == expirationDate ? _self.expirationDate : expirationDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
