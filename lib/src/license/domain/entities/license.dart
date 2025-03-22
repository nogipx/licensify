// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';

import 'package:licensify/licensify.dart';

/// License type representation
///
/// This class allows both using predefined license types and
/// creating custom types for specific business needs.
class LicenseType {
  /// The name identifier of the license type
  final String name;

  /// Creates a license type with the specified name
  ///
  /// Use this constructor to create custom license types:
  /// ```dart
  /// final enterpriseType = LicenseType('enterprise');
  /// ```
  const LicenseType(this.name);

  /// Trial license with limited functionality or time period
  static const trial = LicenseType('trial');

  /// Standard license with basic functionality
  static const standard = LicenseType('standard');

  /// Professional license with all features enabled
  static const pro = LicenseType('pro');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicenseType && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'LicenseType($name)';
}

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
  }) : expirationDate = expirationDate.isUtc ? expirationDate : expirationDate.toUtc(),
       createdAt = createdAt.isUtc ? createdAt : createdAt.toUtc();

  /// Checks if license has expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expirationDate);

  /// Returns the number of days remaining until expiration
  /// May return negative values if license has already expired
  int get remainingDays => expirationDate.difference(DateTime.now().toUtc()).inDays;

  /// Converts the license to a byte array using formatted header
  Uint8List get bytes => LicenseFileFormat.encodeToBytes(toJson());

  /// Converts the license to JSON representation
  Map<String, dynamic> toJson() => {
    'id': id,
    'appId': appId,
    'expirationDate': expirationDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'signature': signature,
    'type': type.name,
    'features': features,
    'metadata': metadata,
  };
}
