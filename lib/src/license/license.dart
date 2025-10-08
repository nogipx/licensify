// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

part of 'package:licensify/licensify.dart';

/// PASETO-based license domain entity
///
/// 🔒 SECURITY: This class can ONLY be created from cryptographically validated tokens.
/// All constructors are private except for the internal validation factory.
///
/// This represents a license as a PASETO token that has been verified for:
/// - Signature authenticity (Ed25519)
/// - Token structure validity
/// - Payload format compliance
class License {
  /// The PASETO token containing all license information
  final String token;

  /// Pre-validated payload data (guaranteed to be cryptographically verified)
  final Map<String, dynamic> _validatedPayload;

  /// Creates a new PASETO license instance (PRIVATE - internal use only)
  License._from(this.token, [this._validatedPayload = const {}]);

  /// Unique license identifier (UUID)
  Future<String> get id async => _validatedPayload['sub'] as String? ?? '';

  /// Application identifier this license is valid for
  Future<String> get appId async =>
      _validatedPayload['app_id'] as String? ?? '';

  /// License expiration date (UTC)
  Future<DateTime> get expirationDate async {
    final expStr = _validatedPayload['exp'] as String?;
    if (expStr == null) return DateTime.now().toUtc();
    return DateTime.parse(expStr).toUtc();
  }

  /// License creation date (UTC)
  Future<DateTime> get createdAt async {
    final iatStr = _validatedPayload['iat'] as String?;
    if (iatStr == null) return DateTime.now().toUtc();
    return DateTime.parse(iatStr).toUtc();
  }

  /// License type (can be predefined or custom)
  Future<LicenseType> get type async {
    final typeStr = _validatedPayload['type'] as String?;
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
  Future<Map<String, dynamic>> get features async {
    final featuresData = _validatedPayload['features'];
    if (featuresData is Map<String, dynamic>) {
      return featuresData;
    }
    return {};
  }

  /// Additional license metadata
  Future<Map<String, dynamic>?> get metadata async {
    final metadataData = _validatedPayload['metadata'];
    if (metadataData is Map<String, dynamic>) {
      return metadataData;
    }
    return null;
  }

  /// Flag indicating if this is a trial license
  Future<bool> get isTrial async =>
      _validatedPayload['trial'] as bool? ?? false;

  /// Checks if license has expired
  Future<bool> get isExpired async {
    final expDate = await expirationDate;
    return DateTime.now().toUtc().isAfter(expDate);
  }

  /// Returns the number of days remaining until expiration
  Future<int> get remainingDays async {
    final expDate = await expirationDate;
    return expDate.difference(DateTime.now().toUtc()).inDays;
  }

  /// Returns the raw PASETO token
  @override
  String toString() => token;

  /// Converts license to a map representation (from validated payload)
  Future<Map<String, dynamic>> toJson() async =>
      Map<String, dynamic>.from(_validatedPayload);

  /// Creates a copy of this instance with optional changes
  ///
  /// Note: This will require re-signing the token, so it returns
  /// the payload data that can be used with a generator.
  Future<Map<String, dynamic>> copyWithPayload({
    String? id,
    String? appId,
    DateTime? expirationDate,
    DateTime? createdAt,
    LicenseType? type,
    Map<String, dynamic>? features,
    Object? metadata = const _Unset(),
    bool? isTrial,
  }) async {
    return {
      'sub': id ?? await this.id,
      'app_id': appId ?? await this.appId,
      'exp': (expirationDate ?? await this.expirationDate).toIso8601String(),
      'iat': (createdAt ?? await this.createdAt).toIso8601String(),
      'type': (type ?? await this.type).name,
      'features': features ?? await this.features,
      'metadata': metadata is _Unset ? await this.metadata : metadata,
      'trial': isTrial ?? await this.isTrial,
    };
  }
}

/// Internal class for handling nullable field in copyWith
class _Unset {
  const _Unset();
}
