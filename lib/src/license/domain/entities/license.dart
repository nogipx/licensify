// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

/// License domain entity
///
/// Represents a cryptographically signed license with validity information
/// and custom features.
class License {
  /// Unique license identifier (UUID)
  final String id;

  /// Application identifier this license is valid for
  final String appId;

  /// License expiration date (UTC)
  final DateTime expirationDate;

  /// License creation date (UTC)
  final DateTime createdAt;

  /// Cryptographic signature for license verification
  final String signature;

  /// License type (can be predefined or custom)
  final LicenseType type;

  /// Available features or limitations for this license
  /// Can contain any custom parameters needed by the application
  final Map<String, dynamic> features;

  /// Additional license metadata
  /// Can store information about customer, purchase, etc.
  final Map<String, dynamic>? metadata;

  /// Creates a new license instance
  ///
  /// All dates are automatically converted to UTC
  License({
    required this.id,
    required this.appId,
    required DateTime expirationDate,
    required DateTime createdAt,
    required this.signature,
    this.type = LicenseType.trial,
    this.features = const {},
    this.metadata,
  }) : expirationDate =
           expirationDate.isUtc ? expirationDate : expirationDate.toUtc(),
       createdAt = createdAt.isUtc ? createdAt : createdAt.toUtc();

  /// Checks if license has expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expirationDate);

  /// Returns the number of days remaining until expiration
  /// May return negative values if license has already expired
  int get remainingDays =>
      expirationDate.difference(DateTime.now().toUtc()).inDays;

  /// Creates a copy of this instance with optional changes
  License copyWith({
    String? id,
    String? appId,
    DateTime? expirationDate,
    DateTime? createdAt,
    String? signature,
    LicenseType? type,
    Map<String, dynamic>? features,
    Object? metadata = const _Unset(),
  }) {
    return License(
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
}

/// Internal class for handling nullable field in copyWith
class _Unset {
  const _Unset();
}
