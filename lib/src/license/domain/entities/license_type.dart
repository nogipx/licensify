// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

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
      other is LicenseType &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'LicenseType($name)';
}
