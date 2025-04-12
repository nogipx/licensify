// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:test/test.dart';
import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('License', () {
    // Фабричный метод для быстрого создания лицензий для тестов
    License createLicense({
      String? id,
      String? appId,
      DateTime? expirationDate,
      DateTime? createdAt,
      String? signature,
      LicenseType type = LicenseType.standard,
      Map<String, dynamic> features = const {},
      bool isTrial = false,
    }) {
      return License(
        id: id ?? 'test-license-id',
        appId: appId ?? TestConstants.testAppId,
        expirationDate:
            expirationDate ??
            DateTime.now()
                .add(Duration(days: TestConstants.defaultLicenseDuration))
                .toUtc(),
        createdAt: createdAt ?? DateTime.now().toUtc(),
        signature: signature ?? 'test_signature',
        type: type,
        features: features,
        isTrial: isTrial,
      );
    }

    test('не_истекшая_лицензия_возвращает_false', () {
      // Arrange
      final sut = createLicense(
        expirationDate: DateTime.now().add(const Duration(days: 30)).toUtc(),
      );

      // Act
      final result = sut.isExpired;

      // Assert
      expect(result, isFalse);
    });

    test('истекшая_лицензия_возвращает_true', () {
      // Arrange
      final sut = createLicense(
        expirationDate:
            DateTime.now().subtract(const Duration(days: 1)).toUtc(),
      );

      // Act
      final result = sut.isExpired;

      // Assert
      expect(result, isTrue);
    });

    test('для_будущей_лицензии_возвращает_положительное_количество_дней', () {
      // Arrange
      final expDate = DateTime.now().add(const Duration(days: 30)).toUtc();
      final sut = createLicense(expirationDate: expDate);

      // Act
      final result = sut.remainingDays;

      // Assert
      // Допускаем погрешность из-за разницы во времени между arrange и act
      expect(result, greaterThanOrEqualTo(29));
      expect(result, lessThanOrEqualTo(30));
    });

    test('для_истекшей_лицензии_возвращает_отрицательное_количество_дней', () {
      // Arrange
      final expDate = DateTime.now().subtract(const Duration(days: 10)).toUtc();
      final sut = createLicense(expirationDate: expDate);

      // Act
      final result = sut.remainingDays;

      // Assert
      expect(result, lessThanOrEqualTo(-10));
    });

    test('конструктор_преобразует_не_utc_даты_в_utc', () {
      // Arrange
      final nonUtcExpDate = DateTime.now().add(const Duration(days: 30));
      final nonUtcCreatedDate = DateTime.now();

      // Act
      final sut = createLicense(
        expirationDate: nonUtcExpDate,
        createdAt: nonUtcCreatedDate,
      );

      // Assert
      expect(sut.expirationDate.isUtc, isTrue);
      expect(sut.createdAt.isUtc, isTrue);
    });

    test('конструктор_сохраняет_utc_даты_без_изменений', () {
      // Arrange
      final utcExpDate = DateTime.now().add(const Duration(days: 30)).toUtc();
      final utcCreatedDate = DateTime.now().toUtc();

      // Act
      final sut = createLicense(
        expirationDate: utcExpDate,
        createdAt: utcCreatedDate,
      );

      // Assert
      expect(sut.expirationDate.isUtc, isTrue);
      expect(sut.expirationDate, equals(utcExpDate));
      expect(sut.createdAt.isUtc, isTrue);
      expect(sut.createdAt, equals(utcCreatedDate));
    });

    test('конструктор_сохраняет_дополнительные_фичи', () {
      // Arrange
      final features = {'maxUsers': 10, 'canExport': true};

      // Act
      final sut = createLicense(features: features);

      // Assert
      expect(sut.features, equals(features));
      expect(sut.features['maxUsers'], equals(10));
      expect(sut.features['canExport'], isTrue);
    });
  });
}
