// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';
import 'package:test/test.dart';
import '../../../license/helpers/test_constants.dart';

void main() {
  group('LicenseSchema - исправленные тесты', () {
    // Тестовые данные
    late LicenseSchema sut; // System Under Test
    final validFeatures = {
      'maxUsers': 50,
      'modules': ['reporting', 'export'],
      'premium': true,
    };

    final validMetadata = {
      'clientName': 'Example Corp',
      'deviceHash': 'device-123',
    };

    // Фабричный метод для создания стандартной схемы для тестов
    LicenseSchema createTestSchema({
      bool allowUnknownFeatures = false,
      bool allowUnknownMetadata = true,
    }) {
      return LicenseSchema(
        featureSchema: {
          'maxUsers': SchemaField(
            type: FieldType.integer,
            required: true,
            validators: [NumberValidator(minimum: 5, maximum: 100)],
          ),
          'modules': SchemaField(
            type: FieldType.array,
            required: true,
            validators: [
              ArrayValidator(minItems: 1, itemValidator: StringValidator()),
            ],
          ),
          'premium': SchemaField(type: FieldType.boolean),
        },
        metadataSchema: {
          'clientName': SchemaField(
            type: FieldType.string,
            required: true,
            validators: [StringValidator(minLength: 3)],
          ),
          'deviceHash': SchemaField(type: FieldType.string),
        },
        allowUnknownFeatures: allowUnknownFeatures,
        allowUnknownMetadata: allowUnknownMetadata,
      );
    }

    // Фабричный метод для создания тестовой лицензии
    License createTestLicense({
      Map<String, dynamic>? features,
      Map<String, dynamic>? metadata,
    }) {
      return License(
        id: 'test-id',
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(
          Duration(days: TestConstants.defaultLicenseDuration),
        ),
        createdAt: DateTime.now(),
        signature: 'test-signature',
        features: features ?? validFeatures,
        metadata: metadata ?? validMetadata,
      );
    }

    setUp(() {
      // Инициализация SUT перед каждым тестом
      sut = createTestSchema();
    });

    test('схема подтверждает корректные поля features', () {
      // Arrange
      final features = validFeatures;

      // Act
      final result = sut.validateFeatures(features);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isNull);
    });

    test('схема отклоняет поля features с неправильным типом данных', () {
      // Arrange
      final features = {
        'maxUsers': 'not-a-number', // Неправильный тип
        'modules': ['reporting', 'export'],
        'premium': true,
      };

      // Act
      final result = sut.validateFeatures(features);

      // Assert
      expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('maxUsers'), isTrue);
    });

    test('схема отклоняет числовые значения ниже минимума', () {
      // Arrange
      final features = {
        'maxUsers': 2, // Ниже минимума 5
        'modules': ['reporting', 'export'],
        'premium': true,
      };

      // Act
      final result = sut.validateFeatures(features);

      // Assert
      expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('maxUsers'), isTrue);
    });

    test('схема отклоняет числовые значения выше максимума', () {
      // Arrange
      final features = {
        'maxUsers': 200, // Выше максимума 100
        'modules': ['reporting', 'export'],
        'premium': true,
      };

      // Act
      final result = sut.validateFeatures(features);

      // Assert
      expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('maxUsers'), isTrue);
    });

    test('схема отклоняет пустые массивы, если установлен minItems', () {
      // Arrange
      final features = {
        'maxUsers': 50,
        'modules': [], // Пустой массив
        'premium': true,
      };

      // Act
      final result = sut.validateFeatures(features);

      // Assert
      expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('modules'), isTrue);
    });

    test(
      'схема отклоняет неизвестные поля, если allowUnknownFeatures=false',
      () {
        // Arrange
        final features = {
          'maxUsers': 50,
          'modules': ['reporting', 'export'],
          'premium': true,
          'unknownFeature': 'value', // Неизвестное поле
        };

        // Act
        final result = sut.validateFeatures(features);

        // Assert
        expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
        expect(result.errors, isNotNull);
        expect(result.errors!.containsKey('unknownFeature'), isTrue);
      },
    );

    test(
      'схема разрешает неизвестные поля, если allowUnknownFeatures=true',
      () {
        // Arrange
        final customSut = createTestSchema(allowUnknownFeatures: true);
        final features = {
          'maxUsers': 50,
          'modules': ['reporting', 'export'],
          'premium': true,
          'unknownFeature': 'value', // Неизвестное поле
        };

        // Act
        final result = customSut.validateFeatures(features);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isNull);
      },
    );

    test('схема отклоняет отсутствующие обязательные поля', () {
      // Arrange
      final features = {
        // 'maxUsers' отсутствует (обязательное)
        'modules': ['reporting', 'export'],
        'premium': true,
      };

      // Act
      final result = sut.validateFeatures(features);

      // Assert
      expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('maxUsers'), isTrue);
    });

    test('схема подтверждает корректные metadata', () {
      // Arrange
      final metadata = validMetadata;

      // Act
      final result = sut.validateMetadata(metadata);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isNull);
    });

    test('схема отклоняет слишком короткие строки в metadata', () {
      // Arrange
      final metadata = {
        'clientName': 'AB', // Слишком короткая строка
        'deviceHash': 'device-123',
      };

      // Act
      final result = sut.validateMetadata(metadata);

      // Assert
      expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('clientName'), isTrue);
    });

    test('схема по умолчанию разрешает неизвестные поля в metadata', () {
      // Arrange
      final metadata = {
        'clientName': 'Example Corp',
        'deviceHash': 'device-123',
        'unknownField': 'value', // Неизвестное поле
      };

      // Act
      final result = sut.validateMetadata(metadata);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isNull);
    });

    test(
      'схема отклоняет неизвестные поля в metadata, если allowUnknownMetadata=false',
      () {
        // Arrange
        final customSut = createTestSchema(allowUnknownMetadata: false);
        final metadata = {
          'clientName': 'Example Corp',
          'deviceHash': 'device-123',
          'unknownField': 'value', // Неизвестное поле
        };

        // Act
        final result = customSut.validateMetadata(metadata);

        // Assert
        expect(result.isValid, isFalse); // Данные невалидны, ожидаем false
        expect(result.errors, isNotNull);
        expect(result.errors!.containsKey('unknownField'), isTrue);
      },
    );

    test('схема обрабатывает null metadata как валидное значение', () {
      // Arrange - setup in setUp

      // Act
      final result = sut.validateMetadata(null);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isNull);
    });

    test('validateLicense подтверждает лицензию с валидными полями', () {
      // Arrange
      final license = createTestLicense();

      // Act
      final result = sut.validateLicense(license);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isNull);
    });

    test('validateLicense отклоняет лицензию с невалидными features', () {
      // Arrange
      final license = createTestLicense(
        features: {
          'maxUsers': 0, // Невалидное значение
          'modules': [], // Невалидное значение
        },
      );

      // Act
      final result = sut.validateLicense(license);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('features'), isTrue);
    });

    test('validateLicense отклоняет лицензию с невалидными metadata', () {
      // Arrange
      final license = createTestLicense(
        metadata: {
          'clientName': 'A', // Слишком короткая строка
        },
      );

      // Act
      final result = sut.validateLicense(license);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors, isNotNull);
      expect(result.errors!.containsKey('metadata'), isTrue);
    });
  });
}
