// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'package:licensify/licensify.dart';

/// PASETO-based license domain entity
///
/// This represents a license as a PASETO token instead of separate data + signature.
/// The entire license is contained within the PASETO token, providing better security
/// and following modern cryptographic best practices.
class License {
  /// The PASETO token containing all license information
  final String token;

  /// Cached payload data (extracted from token)
  final Map<String, dynamic> _payload;

  /// Creates a new PASETO license instance
  ///
  /// [token] - The PASETO v4.public token containing license data
  /// [payload] - The decoded payload from the token (for caching)
  License._({required this.token, required Map<String, dynamic> payload})
      : _payload = payload;

  /// Creates a PASETO license from a token string
  ///
  /// Note: This doesn't validate the token, only parses it.
  /// Use [LicensifyPaseto_LicenseValidator] for validation.
  factory License.fromToken(String token) {
    // For now, we'll store the token and extract payload later during validation
    // This is a simple implementation - in production, you might want to
    // validate the structure but not the signature here
    return License._(
      token: token,
      payload: {}, // Will be populated during validation
    );
  }

  /// Creates a PASETO license from validated payload
  ///
  /// This should only be called after successful token validation
  factory License.fromValidatedPayload({
    required String token,
    required Map<String, dynamic> payload,
  }) {
    return License._(token: token, payload: payload);
  }

  /// Updates the internal payload after validation
  ///
  /// This is used by validators to populate the payload after successful verification
  void updatePayload(Map<String, dynamic> payload) {
    _payload.clear();
    // Ensure we have proper type conversion
    for (final entry in payload.entries) {
      _payload[entry.key] = entry.value;
    }
  }

  /// Unique license identifier (UUID)
  String get id => _payload['sub'] as String? ?? '';

  /// Application identifier this license is valid for
  String get appId => _payload['app_id'] as String? ?? '';

  /// License expiration date (UTC)
  DateTime get expirationDate {
    final expStr = _payload['exp'] as String?;
    if (expStr == null) return DateTime.now().toUtc();
    return DateTime.parse(expStr).toUtc();
  }

  /// License creation date (UTC)
  DateTime get createdAt {
    final iatStr = _payload['iat'] as String?;
    if (iatStr == null) return DateTime.now().toUtc();
    return DateTime.parse(iatStr).toUtc();
  }

  /// License type (can be predefined or custom)
  LicenseType get type {
    final typeStr = _payload['type'] as String?;
    if (typeStr == null) return LicenseType.standard;

    // Check for predefined types
    if (typeStr == 'standard') {
      return LicenseType.standard;
    }
    if (typeStr == 'pro') {
      return LicenseType.pro;
    }

    // For custom types, create a new instance
    return LicenseType(typeStr);
  }

  /// Available features or limitations for this license
  Map<String, dynamic> get features {
    final featuresData = _payload['features'];
    if (featuresData is Map<String, dynamic>) {
      return featuresData;
    }
    return {};
  }

  /// Additional license metadata
  Map<String, dynamic>? get metadata {
    final metadataData = _payload['metadata'];
    if (metadataData is Map<String, dynamic>) {
      return metadataData;
    }
    return null;
  }

  /// Flag indicating if this is a trial license
  bool get isTrial => _payload['trial'] as bool? ?? false;

  /// Checks if license has expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expirationDate);

  /// Returns the number of days remaining until expiration
  int get remainingDays =>
      expirationDate.difference(DateTime.now().toUtc()).inDays;

  /// Returns the raw PASETO token
  @override
  String toString() => token;

  /// Converts license to a map representation (from payload)
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_payload);

  /// Creates a JSON representation of the license payload
  String toJson() => jsonEncode(toMap());

  /// Creates a copy of this instance with optional changes
  ///
  /// Note: This will require re-signing the token, so it returns
  /// the payload data that can be used with a generator.
  Map<String, dynamic> copyWithPayload({
    String? id,
    String? appId,
    DateTime? expirationDate,
    DateTime? createdAt,
    LicenseType? type,
    Map<String, dynamic>? features,
    Object? metadata = const _Unset(),
    bool? isTrial,
  }) {
    return {
      'sub': id ?? this.id,
      'app_id': appId ?? this.appId,
      'exp': (expirationDate ?? this.expirationDate).toIso8601String(),
      'iat': (createdAt ?? this.createdAt).toIso8601String(),
      'type': (type ?? this.type).name,
      'features': features ?? this.features,
      'metadata': metadata is _Unset ? this.metadata : metadata,
      'trial': isTrial ?? this.isTrial,
    };
  }
}

/// Internal class for handling nullable field in copyWith
class _Unset {
  const _Unset();
}
