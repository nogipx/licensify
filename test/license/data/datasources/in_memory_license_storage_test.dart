// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('InMemoryLicenseStorage', () {
    late InMemoryLicenseStorage sut;

    setUp(() {
      // Создаем новое пустое хранилище перед каждым тестом
      sut = InMemoryLicenseStorage();
    });

    test('пустое_хранилище_не_содержит_лицензии', () async {
      // Arrange - хранилище создано пустым в setUp

      // Act
      final hasLicense = await sut.hasLicense();
      final licenseData = await sut.loadLicenseData();
      final dataSize = sut.dataSize;

      // Assert
      expect(hasLicense, isFalse);
      expect(licenseData, isNull);
      expect(dataSize, equals(0));
    });

    test('успешно_сохраняет_и_загружает_данные', () async {
      // Arrange
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Act - сохраняем данные
      final saveResult = await sut.saveLicenseData(testData);
      final hasLicense = await sut.hasLicense();
      final loadedData = await sut.loadLicenseData();
      final dataSize = sut.dataSize;

      // Assert
      expect(saveResult, isTrue);
      expect(hasLicense, isTrue);
      expect(loadedData, equals(testData));
      expect(dataSize, equals(testData.length));
    });

    test('успешно_удаляет_данные', () async {
      // Arrange - сначала сохраняем данные
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      await sut.saveLicenseData(testData);

      // Проверяем, что данные сохранились
      expect(await sut.hasLicense(), isTrue);

      // Act - удаляем данные
      final deleteResult = await sut.deleteLicenseData();
      final hasLicense = await sut.hasLicense();
      final loadedData = await sut.loadLicenseData();
      final dataSize = sut.dataSize;

      // Assert
      expect(deleteResult, isTrue);
      expect(hasLicense, isFalse);
      expect(loadedData, isNull);
      expect(dataSize, equals(0));
    });

    test('метод_clear_очищает_данные', () async {
      // Arrange - сначала сохраняем данные
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      await sut.saveLicenseData(testData);

      // Проверяем, что данные сохранились
      expect(await sut.hasLicense(), isTrue);

      // Act - очищаем данные
      sut.clear();
      final hasLicense = await sut.hasLicense();
      final loadedData = await sut.loadLicenseData();
      final dataSize = sut.dataSize;

      // Assert
      expect(hasLicense, isFalse);
      expect(loadedData, isNull);
      expect(dataSize, equals(0));
    });

    test('создание_с_предзагруженными_данными_работает_корректно', () async {
      // Arrange
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Act - создаем хранилище с предзагруженными данными
      final preloadedStorage = InMemoryLicenseStorage.withData(testData);
      final hasLicense = await preloadedStorage.hasLicense();
      final loadedData = await preloadedStorage.loadLicenseData();
      final dataSize = preloadedStorage.dataSize;

      // Assert
      expect(hasLicense, isTrue);
      expect(loadedData, equals(testData));
      expect(dataSize, equals(testData.length));
    });
  });
}
