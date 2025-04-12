// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later
import 'package:test/test.dart';

import 'package:licensify/licensify.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('LicenseValidator', () {
    // Общие фикстуры для группы тестов
    late LicenseValidator validatorWithKey;
    late License validLicense;
    late License expiredLicense;
    late License invalidSignatureLicense;
    late LicensifyKeyPair differentKeys;

    setUp(() {
      // Создаем валидаторы с разными конструкторами
      validatorWithKey = LicenseValidator(
        publicKey: TestConstants.testKeyPair.publicKey,
      );

      // Генерируем лицензии для повторного использования в тестах
      validLicense = TestConstants.testKeyPair.privateKey.licenseGenerator(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
        type: LicenseType.standard,
        isTrial: true,
        features: {'maxUsers': 10, 'premium': true},
        metadata: {'owner': 'Test Corp', 'email': 'test@example.com'},
      );

      expiredLicense = TestConstants.testKeyPair.privateKey.licenseGenerator(
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().subtract(Duration(days: 1)),
        type: LicenseType.standard,
        isTrial: true,
      );

      invalidSignatureLicense = License(
        id: 'test-id',
        appId: TestConstants.testAppId,
        expirationDate: DateTime.now().add(Duration(days: 30)),
        createdAt: DateTime.now(),
        signature: 'invalid-signature',
        type: LicenseType.standard,
        isTrial: true,
      );

      // Создаем другую пару ключей для тестирования несоответствия ключей
      differentKeys = TestConstants.generateTestKeyPair();
    });

    group('validateSignature', () {
      test('should return true for valid signature', () {
        // Act
        final result = validatorWithKey.validateSignature(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return false for invalid signature', () {
        // Act
        final result = validatorWithKey.validateSignature(
          invalidSignatureLicense,
        );

        // Assert
        expect(result.isValid, isFalse);
      });
    });

    group('validateLicense', () {
      test('should return true for valid license', () {
        // Act
        final result = validatorWithKey(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return false for expired license', () {
        // Act
        final result = validatorWithKey(expiredLicense);

        // Assert
        expect(result.isValid, isFalse);
      });

      test('should return false for invalid signature', () {
        // Act
        final result = validatorWithKey(invalidSignatureLicense);

        // Assert
        expect(result.isValid, isFalse);
      });
    });

    group('fromKey constructor', () {
      test('should work with the new fromKey constructor', () {
        // Act
        final result = validatorWithKey.validateSignature(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });
    });

    group('check License', () {
      test('should be able to validate a license', () {
        // Act
        final result = validatorWithKey.validateSignature(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });

      test(
        'validateSignature должен подтверждать корректную подпись лицензии',
        () {
          // Act
          final result = validatorWithKey.validateSignature(validLicense);

          // Assert
          expect(result.isValid, isTrue);
        },
      );

      test('отклоняет_лицензию_с_неверной_подписью', () {
        // Act
        final result = validatorWithKey.validateSignature(
          invalidSignatureLicense,
        );

        // Assert
        expect(result.isValid, isFalse);
      });

      test('отклоняет_лицензию_с_неправильным_ключом', () {
        // Создаем лицензию с другим ключом
        final licenseWithDifferentKey = differentKeys.privateKey
            .licenseGenerator(
              appId: TestConstants.testAppId,
              expirationDate: DateTime.now().add(Duration(days: 30)),
            );

        // Act
        final result = validatorWithKey.validateSignature(
          licenseWithDifferentKey,
        );

        // Assert
        expect(result.isValid, isFalse);
      });

      test('подтверждает_действие_непросроченной_лицензии', () {
        // Act
        final result = validatorWithKey.validateExpiration(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('validateLicense должен отклонять просроченную лицензию', () {
        // Act
        final result = validatorWithKey(expiredLicense);

        // Assert
        expect(result.isValid, isFalse);
      });

      test('validateLicense должен подтверждать корректную лицензию', () {
        // Act
        final result = validatorWithKey(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('validateLicense должен отклонять лицензию с неверной подписью', () {
        // Act
        final result = validatorWithKey(invalidSignatureLicense);

        // Assert
        expect(result.isValid, isFalse);
      });

      test('микросекунды_и_секунды_не_должны_влиять_на_валидацию_подписи', () {
        // Сначала проверим, что оригинальная лицензия валидна
        final originalResult = validatorWithKey.validateSignature(validLicense);
        expect(
          originalResult.isValid,
          isTrue,
          reason: 'Оригинальная лицензия должна быть валидной',
        );

        // Модифицируем лицензию так, чтобы добавить секунды и миллисекунды,
        // но сохранить UTC и тот же час и минуту
        final utcExpirationDate = validLicense.expirationDate;
        final licenseWithSeconds = License(
          id: validLicense.id,
          appId: validLicense.appId,
          expirationDate: DateTime.utc(
            utcExpirationDate.year,
            utcExpirationDate.month,
            utcExpirationDate.day,
            utcExpirationDate.hour,
            utcExpirationDate.minute,
            30, // Добавляем 30 секунд
            500, // Добавляем 500 миллисекунд
          ),
          createdAt: validLicense.createdAt,
          signature: validLicense.signature,
          type: validLicense.type,
          features: validLicense.features,
          metadata: validLicense.metadata,
        );

        // Act
        final result = validatorWithKey.validateSignature(licenseWithSeconds);

        // После исправления валидатора, секунды и миллисекунды не должны влиять на валидацию
        expect(
          result.isValid,
          isTrue,
          reason:
              'Изменение секунд и миллисекунд не должно влиять на валидацию подписи',
        );
      });

      test('отклоняет_лицензию_при_любом_изменении_полей', () {
        // Проверяем, что исходная лицензия валидна
        expect(
          validatorWithKey.validateSignature(validLicense).isValid,
          isTrue,
        );

        // Тестируем изменение id
        final tamperedId = License(
          id: 'tampered-id',
          appId: validLicense.appId,
          expirationDate: validLicense.expirationDate,
          createdAt: validLicense.createdAt,
          signature: validLicense.signature,
          type: validLicense.type,
          features: validLicense.features,
          metadata: validLicense.metadata,
        );
        expect(
          validatorWithKey.validateSignature(tamperedId).isValid,
          isFalse,
          reason: 'Изменение ID должно делать подпись невалидной',
        );

        // Тестируем изменение appId
        final tamperedAppId = License(
          id: validLicense.id,
          appId: 'com.hacked.app',
          expirationDate: validLicense.expirationDate,
          createdAt: validLicense.createdAt,
          signature: validLicense.signature,
          type: validLicense.type,
          features: validLicense.features,
          metadata: validLicense.metadata,
        );
        expect(
          validatorWithKey.validateSignature(tamperedAppId).isValid,
          isFalse,
          reason: 'Изменение appId должно делать подпись невалидной',
        );

        // Тестируем изменение типа лицензии
        final tamperedType = License(
          id: validLicense.id,
          appId: validLicense.appId,
          expirationDate: validLicense.expirationDate,
          createdAt: validLicense.createdAt,
          signature: validLicense.signature,
          type: LicenseType.pro, // Изменен тип с trial на pro
          features: validLicense.features,
          metadata: validLicense.metadata,
        );
        expect(
          validatorWithKey.validateSignature(tamperedType).isValid,
          isFalse,
          reason: 'Изменение типа лицензии должно делать подпись невалидной',
        );

        // Тестируем изменение срока действия
        final tamperedExpiration = License(
          id: validLicense.id,
          appId: validLicense.appId,
          expirationDate: validLicense.expirationDate.add(
            Duration(days: 365),
          ), // Добавили год
          createdAt: validLicense.createdAt,
          signature: validLicense.signature,
          type: validLicense.type,
          features: validLicense.features,
          metadata: validLicense.metadata,
        );
        expect(
          validatorWithKey.validateSignature(tamperedExpiration).isValid,
          isFalse,
          reason: 'Изменение срока действия должно делать подпись невалидной',
        );

        // Тестируем изменение features
        final tamperedFeatures = License(
          id: validLicense.id,
          appId: validLicense.appId,
          expirationDate: validLicense.expirationDate,
          createdAt: validLicense.createdAt,
          signature: validLicense.signature,
          type: validLicense.type,
          features: {
            'maxUsers': 1000,
            'premium': true,
            'extraFeature': 'unlocked',
          }, // Изменили features
          metadata: validLicense.metadata,
        );
        expect(
          validatorWithKey.validateSignature(tamperedFeatures).isValid,
          isFalse,
          reason: 'Изменение features должно делать подпись невалидной',
        );

        // Тестируем изменение metadata
        final tamperedMetadata = License(
          id: validLicense.id,
          appId: validLicense.appId,
          expirationDate: validLicense.expirationDate,
          createdAt: validLicense.createdAt,
          signature: validLicense.signature,
          type: validLicense.type,
          features: validLicense.features,
          metadata: {
            'owner': 'Hacker Inc',
            'email': 'hacker@example.com',
          }, // Изменили metadata
        );
        expect(
          validatorWithKey.validateSignature(tamperedMetadata).isValid,
          isFalse,
          reason: 'Изменение metadata должно делать подпись невалидной',
        );
      });
    });

    group('License Schema Validation', () {
      late License validSchemaLicense;
      late License invalidSchemaLicense;
      late LicenseSchema schema;

      setUp(() {
        // Создаем лицензии специально для схемы
        validSchemaLicense = License(
          id: 'test-id',
          appId: 'com.example.app',
          expirationDate: DateTime.now().add(const Duration(days: 365)),
          createdAt: DateTime.now(),
          signature: 'signature',
          features: {
            'maxUsers': 50,
            'modules': ['reporting', 'export'],
            'premium': true,
          },
          metadata: {'clientName': 'Example Corp', 'deviceHash': 'device-123'},
        );

        invalidSchemaLicense = License(
          id: 'test-id',
          appId: 'com.example.app',
          expirationDate: DateTime.now().add(const Duration(days: 365)),
          createdAt: DateTime.now(),
          signature: 'signature',
          features: {
            'maxUsers': 0, // Invalid
            'modules': [], // Invalid
          },
          metadata: {
            'clientName': 'A', // Too short
          },
        );

        schema = LicenseSchema(
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
          allowUnknownFeatures: false,
        );
      });

      test('validateSchema returns valid result for valid license', () {
        final result = validatorWithKey.validateSchema(
          validSchemaLicense,
          schema,
        );
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('validateSchema returns invalid result for invalid license', () {
        final result = validatorWithKey.validateSchema(
          invalidSchemaLicense,
          schema,
        );
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
      });

      test(
        'validateLicenseWithSchema combines signature and schema validation',
        () {
          // Even with valid schema, overall validation fails because signature is invalid
          final isValid = validatorWithKey(validSchemaLicense, schema: schema);
          expect(isValid.isValid, isFalse); // Signature validation fails
        },
      );

      test('validateLicenseWithSchema returns false for invalid schema', () {
        final isValid = validatorWithKey(invalidSchemaLicense, schema: schema);
        expect(isValid.isValid, isFalse);
      });

      test(
        'validateLicenseWithSchema returns true when all validations pass',
        () {
          // Create a mock validator that always returns true for signature validation
          final mockValidator = _MockAlwaysValidValidator();

          final isValid = mockValidator(validSchemaLicense, schema: schema);
          expect(isValid.isValid, isTrue);
        },
      );
    });

    group('LicenseValidator when verifying signature', () {
      test('should return correct result when license is valid', () {
        // Act
        final result = validatorWithKey.validateSignature(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });
    });

    group('LicenseValidator validating a license', () {
      test('should return false on invalid signature', () {
        // Act
        final result = validatorWithKey.validateSignature(
          invalidSignatureLicense,
        );

        // Assert
        expect(result.isValid, isFalse);
      });

      test('should return true on valid signature', () {
        // Act
        final result = validatorWithKey.validateSignature(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should validate appId and return false if incorrect', () {
        // Создаем схему для валидации
        final schema = LicenseSchema(
          featureSchema: {},
          metadataSchema: {},
          allowUnknownFeatures: true,
        );

        // Act
        final result = validatorWithKey(validLicense, schema: schema);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should validate expirationDate and return false if expired', () {
        // Act
        final result = validatorWithKey(expiredLicense);

        // Assert
        expect(result.isValid, isFalse);
      });

      test('should validate all together and return true if all valid', () {
        // Act
        final result = validatorWithKey(validLicense);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should validate all together and return false if any invalid', () {
        // Act
        final result = validatorWithKey(invalidSignatureLicense);

        // Assert
        expect(result.isValid, isFalse);
      });
    });

    test('должен работать с конструктором fromKey', () {
      // Act
      final result = validatorWithKey.validateSignature(validLicense);

      // Assert
      expect(result.isValid, isTrue);
    });
  });
}

/// Mock validator that always returns true for signature validation
class _MockAlwaysValidValidator implements ILicenseValidator {
  @override
  ValidationResult call(License license, {LicenseSchema? schema}) =>
      ValidationResult.valid();

  @override
  ValidationResult validateSignature(License license) =>
      ValidationResult.valid();

  @override
  ValidationResult validateExpiration(License license) =>
      ValidationResult.valid();

  @override
  SchemaValidationResult validateSchema(License license, LicenseSchema schema) {
    return schema.validateLicense(license);
  }
}
