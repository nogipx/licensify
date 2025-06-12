// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

/// License type representation
///
/// This class allows creating custom license types for specific business needs.
/// Any license type can be set as a trial license using the isTrial flag
/// in the License class.
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
