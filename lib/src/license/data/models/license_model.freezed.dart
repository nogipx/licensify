// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'license_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LicenseModel _$LicenseModelFromJson(Map<String, dynamic> json) {
  return _LicenseModel.fromJson(json);
}

/// @nodoc
mixin _$LicenseModel {
  /// Уникальный идентификатор лицензии
  String get id => throw _privateConstructorUsedError;

  /// Идентификатор приложения, для которого действует лицензия
  String get appId => throw _privateConstructorUsedError;

  /// Дата истечения срока действия лицензии
  DateTime get expirationDate => throw _privateConstructorUsedError;

  /// Дата создания лицензии
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Подпись лицензии для проверки подлинности
  String get signature => throw _privateConstructorUsedError;

  /// Тип лицензии (например, trial, standard, pro)
  String get type => throw _privateConstructorUsedError;

  /// Доступные функции или ограничения для данной лицензии
  Map<String, dynamic> get features => throw _privateConstructorUsedError;

  /// Дополнительные метаданные лицензии
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this LicenseModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LicenseModelCopyWith<LicenseModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LicenseModelCopyWith<$Res> {
  factory $LicenseModelCopyWith(
    LicenseModel value,
    $Res Function(LicenseModel) then,
  ) = _$LicenseModelCopyWithImpl<$Res, LicenseModel>;
  @useResult
  $Res call({
    String id,
    String appId,
    DateTime expirationDate,
    DateTime createdAt,
    String signature,
    String type,
    Map<String, dynamic> features,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class _$LicenseModelCopyWithImpl<$Res, $Val extends LicenseModel>
    implements $LicenseModelCopyWith<$Res> {
  _$LicenseModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? appId = null,
    Object? expirationDate = null,
    Object? createdAt = null,
    Object? signature = null,
    Object? type = null,
    Object? features = null,
    Object? metadata = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            appId:
                null == appId
                    ? _value.appId
                    : appId // ignore: cast_nullable_to_non_nullable
                        as String,
            expirationDate:
                null == expirationDate
                    ? _value.expirationDate
                    : expirationDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            signature:
                null == signature
                    ? _value.signature
                    : signature // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            features:
                null == features
                    ? _value.features
                    : features // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>,
            metadata:
                freezed == metadata
                    ? _value.metadata
                    : metadata // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LicenseModelImplCopyWith<$Res>
    implements $LicenseModelCopyWith<$Res> {
  factory _$$LicenseModelImplCopyWith(
    _$LicenseModelImpl value,
    $Res Function(_$LicenseModelImpl) then,
  ) = __$$LicenseModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String appId,
    DateTime expirationDate,
    DateTime createdAt,
    String signature,
    String type,
    Map<String, dynamic> features,
    Map<String, dynamic>? metadata,
  });
}

/// @nodoc
class __$$LicenseModelImplCopyWithImpl<$Res>
    extends _$LicenseModelCopyWithImpl<$Res, _$LicenseModelImpl>
    implements _$$LicenseModelImplCopyWith<$Res> {
  __$$LicenseModelImplCopyWithImpl(
    _$LicenseModelImpl _value,
    $Res Function(_$LicenseModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? appId = null,
    Object? expirationDate = null,
    Object? createdAt = null,
    Object? signature = null,
    Object? type = null,
    Object? features = null,
    Object? metadata = freezed,
  }) {
    return _then(
      _$LicenseModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        appId:
            null == appId
                ? _value.appId
                : appId // ignore: cast_nullable_to_non_nullable
                    as String,
        expirationDate:
            null == expirationDate
                ? _value.expirationDate
                : expirationDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        signature:
            null == signature
                ? _value.signature
                : signature // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        features:
            null == features
                ? _value._features
                : features // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>,
        metadata:
            freezed == metadata
                ? _value._metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LicenseModelImpl extends _LicenseModel {
  const _$LicenseModelImpl({
    required this.id,
    required this.appId,
    required this.expirationDate,
    required this.createdAt,
    required this.signature,
    this.type = 'standard',
    final Map<String, dynamic> features = const {},
    final Map<String, dynamic>? metadata,
  }) : _features = features,
       _metadata = metadata,
       super._();

  factory _$LicenseModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LicenseModelImplFromJson(json);

  /// Уникальный идентификатор лицензии
  @override
  final String id;

  /// Идентификатор приложения, для которого действует лицензия
  @override
  final String appId;

  /// Дата истечения срока действия лицензии
  @override
  final DateTime expirationDate;

  /// Дата создания лицензии
  @override
  final DateTime createdAt;

  /// Подпись лицензии для проверки подлинности
  @override
  final String signature;

  /// Тип лицензии (например, trial, standard, pro)
  @override
  @JsonKey()
  final String type;

  /// Доступные функции или ограничения для данной лицензии
  final Map<String, dynamic> _features;

  /// Доступные функции или ограничения для данной лицензии
  @override
  @JsonKey()
  Map<String, dynamic> get features {
    if (_features is EqualUnmodifiableMapView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_features);
  }

  /// Дополнительные метаданные лицензии
  final Map<String, dynamic>? _metadata;

  /// Дополнительные метаданные лицензии
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'LicenseModel(id: $id, appId: $appId, expirationDate: $expirationDate, createdAt: $createdAt, signature: $signature, type: $type, features: $features, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LicenseModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.appId, appId) || other.appId == appId) &&
            (identical(other.expirationDate, expirationDate) ||
                other.expirationDate == expirationDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.signature, signature) ||
                other.signature == signature) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    appId,
    expirationDate,
    createdAt,
    signature,
    type,
    const DeepCollectionEquality().hash(_features),
    const DeepCollectionEquality().hash(_metadata),
  );

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LicenseModelImplCopyWith<_$LicenseModelImpl> get copyWith =>
      __$$LicenseModelImplCopyWithImpl<_$LicenseModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LicenseModelImplToJson(this);
  }
}

abstract class _LicenseModel extends LicenseModel {
  const factory _LicenseModel({
    required final String id,
    required final String appId,
    required final DateTime expirationDate,
    required final DateTime createdAt,
    required final String signature,
    final String type,
    final Map<String, dynamic> features,
    final Map<String, dynamic>? metadata,
  }) = _$LicenseModelImpl;
  const _LicenseModel._() : super._();

  factory _LicenseModel.fromJson(Map<String, dynamic> json) =
      _$LicenseModelImpl.fromJson;

  /// Уникальный идентификатор лицензии
  @override
  String get id;

  /// Идентификатор приложения, для которого действует лицензия
  @override
  String get appId;

  /// Дата истечения срока действия лицензии
  @override
  DateTime get expirationDate;

  /// Дата создания лицензии
  @override
  DateTime get createdAt;

  /// Подпись лицензии для проверки подлинности
  @override
  String get signature;

  /// Тип лицензии (например, trial, standard, pro)
  @override
  String get type;

  /// Доступные функции или ограничения для данной лицензии
  @override
  Map<String, dynamic> get features;

  /// Дополнительные метаданные лицензии
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LicenseModelImplCopyWith<_$LicenseModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
