// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:test/test.dart';
import 'package:licensify/licensify.dart';
import 'dart:convert';

void main() {
  group('EcdsaParamsConverter', () {
    // Фиксированные тестовые данные для P-256 (secp256r1) кривой
    const privateScalar =
        'd1b71758e219652b8c4ff3edd77a337d536c65a4278c93a41887d132b1cb8673';
    const publicX =
        '4f922fc516273ff6c790fcba308c3f39f4648aabb5daea5d1f1af9a20e46c373';
    const publicY =
        '928babd689f2e39c7bfb76e599f7263c50c50a1a5679f10dbaaa49eca7d55b4c';
    const curveName = 'prime256v1';

    test(
      'publicKeyFromCoordinates создает валидный PEM формат для публичного ключа',
      () {
        // Act
        final pemString = EcdsaParamsConverter.publicKeyFromCoordinates(
          x: publicX,
          y: publicY,
          curveName: curveName,
        );

        // Assert
        expect(pemString, contains('-----BEGIN PUBLIC KEY-----'));
        expect(pemString, contains('-----END PUBLIC KEY-----'));

        // Дополнительная проверка - должен парситься PointyCastle
        expect(
          () => CryptoUtils.ecPublicKeyFromPem(pemString),
          isNot(throwsException),
        );
      },
    );

    test(
      'privateKeyFromScalar создает валидный PEM формат для приватного ключа',
      () {
        // Act
        final pemString = EcdsaParamsConverter.privateKeyFromScalar(
          d: privateScalar,
          curveName: curveName,
        );

        // Assert
        expect(pemString, contains('-----BEGIN EC PRIVATE KEY-----'));
        expect(pemString, contains('-----END EC PRIVATE KEY-----'));

        // Дополнительная проверка - должен парситься PointyCastle
        expect(
          () => CryptoUtils.ecPrivateKeyFromPem(pemString),
          isNot(throwsException),
        );
      },
    );

    test(
      'derivePublicKeyCoordinates корректно вычисляет публичный ключ из приватного',
      () {
        // Act
        final coordinates = EcdsaParamsConverter.derivePublicKeyCoordinates(
          d: privateScalar,
          curveName: curveName,
        );

        // Assert
        expect(coordinates, isA<Map<String, String>>());
        expect(coordinates.keys, containsAll(['x', 'y']));
        expect(coordinates['x'], isNotEmpty);
        expect(coordinates['y'], isNotEmpty);
      },
    );

    test(
      'полный цикл преобразования - приватный ключ -> координаты -> публичный ключ',
      () {
        // Act - Шаг 1: Получаем координаты из приватного ключа
        final coordinates = EcdsaParamsConverter.derivePublicKeyCoordinates(
          d: privateScalar,
          curveName: curveName,
        );

        // Act - Шаг 2: Создаем публичный ключ из координат
        final publicKeyPem = EcdsaParamsConverter.publicKeyFromCoordinates(
          x: coordinates['x']!,
          y: coordinates['y']!,
          curveName: curveName,
        );

        // Act - Шаг 3: Создаем приватный ключ из скаляра
        final privateKeyPem = EcdsaParamsConverter.privateKeyFromScalar(
          d: privateScalar,
          curveName: curveName,
        );

        // Преобразуем в PointyCastle ключи для проверки
        final ecPrivateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);
        final ecPublicKey = CryptoUtils.ecPublicKeyFromPem(publicKeyPem);

        // Assert - проверяем, что публичный ключ правильно вычислен из приватного
        // Проверяем на null для безопасного обращения к свойствам
        expect(ecPrivateKey.parameters, isNotNull);
        expect(ecPrivateKey.d, isNotNull);
        expect(ecPublicKey.Q, isNotNull);

        final Q = ecPrivateKey.parameters!.G * ecPrivateKey.d!;

        expect(Q, isNotNull);
        expect(ecPublicKey.Q, isNotNull);

        // Безопасное обращение к свойствам
        final qX = ecPublicKey.Q?.x;
        final qY = ecPublicKey.Q?.y;
        final derivedX = Q?.x;
        final derivedY = Q?.y;

        expect(qX, isNotNull);
        expect(qY, isNotNull);
        expect(derivedX, isNotNull);
        expect(derivedY, isNotNull);

        expect(qX?.toBigInteger(), equals(derivedX?.toBigInteger()));
        expect(qY?.toBigInteger(), equals(derivedY?.toBigInteger()));
      },
    );

    test('работает с ключами с префиксом 0x', () {
      // Act
      final pemString = EcdsaParamsConverter.publicKeyFromCoordinates(
        x: '0x$publicX',
        y: '0x$publicY',
        curveName: curveName,
      );

      // Assert
      expect(pemString, contains('-----BEGIN PUBLIC KEY-----'));

      // Проверка что может быть прочитан PointyCastle
      expect(
        () => CryptoUtils.ecPublicKeyFromPem(pemString),
        isNot(throwsException),
      );
    });

    test('поддерживает различные типы кривых', () {
      final curves = [
        'prime256v1',
        'secp256r1',
        'p-256',
        'secp256k1',
        'secp384r1',
        'p-384',
        'secp521r1',
        'p-521',
      ];

      for (final curve in curves) {
        // Act - создаем приватный ключ
        final privateKeyPem = EcdsaParamsConverter.privateKeyFromScalar(
          d: privateScalar,
          curveName: curve,
        );

        // Assert - проверяем формат и возможность парсинга
        expect(privateKeyPem, contains('-----BEGIN EC PRIVATE KEY-----'));
        expect(
          () => CryptoUtils.ecPrivateKeyFromPem(privateKeyPem),
          isNot(throwsException),
        );
      }
    });

    test('выбрасывает исключение при неизвестной кривой', () {
      // Assert
      expect(
        () => EcdsaParamsConverter.publicKeyFromCoordinates(
          x: publicX,
          y: publicY,
          curveName: 'unknown_curve',
        ),
        throwsArgumentError,
      );

      expect(
        () => EcdsaParamsConverter.privateKeyFromScalar(
          d: privateScalar,
          curveName: 'unknown_curve',
        ),
        throwsArgumentError,
      );
    });

    group('Base64 методы', () {
      // Подготовка base64 данных для тестов
      late String privateScalarBase64;
      late String publicXBase64;
      late String publicYBase64;

      setUp(() {
        // Конвертируем hex в base64
        privateScalarBase64 = base64.encode(_hexToBytes(privateScalar));
        publicXBase64 = base64.encode(_hexToBytes(publicX));
        publicYBase64 = base64.encode(_hexToBytes(publicY));
      });

      test('publicKeyFromBase64Coordinates создает валидный PEM формат', () {
        // Act
        final pemString = EcdsaParamsConverter.publicKeyFromBase64Coordinates(
          xBase64: publicXBase64,
          yBase64: publicYBase64,
          curveName: curveName,
        );

        // Assert
        expect(pemString, contains('-----BEGIN PUBLIC KEY-----'));
        expect(pemString, contains('-----END PUBLIC KEY-----'));

        // Должен корректно парситься
        expect(
          () => CryptoUtils.ecPublicKeyFromPem(pemString),
          isNot(throwsException),
        );
      });

      test('privateKeyFromBase64Scalar создает валидный PEM формат', () {
        // Act
        final pemString = EcdsaParamsConverter.privateKeyFromBase64Scalar(
          dBase64: privateScalarBase64,
          curveName: curveName,
        );

        // Assert
        expect(pemString, contains('-----BEGIN EC PRIVATE KEY-----'));
        expect(pemString, contains('-----END EC PRIVATE KEY-----'));

        // Должен корректно парситься
        expect(
          () => CryptoUtils.ecPrivateKeyFromPem(pemString),
          isNot(throwsException),
        );
      });

      test(
        'derivePublicKeyBase64Coordinates корректно вычисляет координаты',
        () {
          // Act
          final coordinates =
              EcdsaParamsConverter.derivePublicKeyBase64Coordinates(
                dBase64: privateScalarBase64,
                curveName: curveName,
              );

          // Assert
          expect(coordinates, isA<Map<String, String>>());
          expect(coordinates.keys, containsAll(['x', 'y']));
          expect(coordinates['x'], isNotEmpty);
          expect(coordinates['y'], isNotEmpty);

          // Проверяем, что base64 данные корректны
          expect(
            () => base64.decode(coordinates['x']!),
            isNot(throwsException),
          );
          expect(
            () => base64.decode(coordinates['y']!),
            isNot(throwsException),
          );
        },
      );

      test('согласованность между hex и base64 методами', () {
        // Act - получаем координаты обоими способами
        final hexCoordinates = EcdsaParamsConverter.derivePublicKeyCoordinates(
          d: privateScalar,
          curveName: curveName,
        );

        final base64Coordinates =
            EcdsaParamsConverter.derivePublicKeyBase64Coordinates(
              dBase64: privateScalarBase64,
              curveName: curveName,
            );

        // Преобразуем координаты обратно для сравнения
        final hexX = BigInt.parse(hexCoordinates['x']!, radix: 16);
        final hexY = BigInt.parse(hexCoordinates['y']!, radix: 16);

        final base64X = _bytesToBigInt(base64.decode(base64Coordinates['x']!));
        final base64Y = _bytesToBigInt(base64.decode(base64Coordinates['y']!));

        // Assert
        expect(hexX, equals(base64X));
        expect(hexY, equals(base64Y));
      });

      test('полный цикл с base64 методами', () {
        // Act - Шаг 1: Получаем координаты из приватного ключа
        final coordinates =
            EcdsaParamsConverter.derivePublicKeyBase64Coordinates(
              dBase64: privateScalarBase64,
              curveName: curveName,
            );

        // Act - Шаг 2: Создаем публичный ключ из координат
        final publicKeyPem =
            EcdsaParamsConverter.publicKeyFromBase64Coordinates(
              xBase64: coordinates['x']!,
              yBase64: coordinates['y']!,
              curveName: curveName,
            );

        // Act - Шаг 3: Создаем приватный ключ из скаляра
        final privateKeyPem = EcdsaParamsConverter.privateKeyFromBase64Scalar(
          dBase64: privateScalarBase64,
          curveName: curveName,
        );

        // Преобразуем в готовые объекты ключей Licensify
        final privateKey = LicensifyPrivateKey.ecdsa(privateKeyPem);
        final publicKey = LicensifyPublicKey.ecdsa(publicKeyPem);

        // Используем для подписи/проверки через правильные классы
        final testData = 'test data for signing';
        final signDataUseCase = SignDataUseCase();
        final verifySignatureUseCase = VerifySignatureUseCase();

        final signature = signDataUseCase(
          data: testData,
          privateKey: privateKey,
        );

        final isValid = verifySignatureUseCase(
          data: testData,
          signature: signature,
          publicKey: publicKey,
        );

        expect(isValid, isTrue);
      });

      test('обработка некорректных base64 данных', () {
        // Неверный base64
        final invalidBase64 = 'ThisIsNotBase64!@';

        // Assert
        expect(
          () => EcdsaParamsConverter.privateKeyFromBase64Scalar(
            dBase64: invalidBase64,
            curveName: curveName,
          ),
          throwsFormatException,
        );

        expect(
          () => EcdsaParamsConverter.publicKeyFromBase64Coordinates(
            xBase64: invalidBase64,
            yBase64: publicYBase64,
            curveName: curveName,
          ),
          throwsFormatException,
        );

        expect(
          () => EcdsaParamsConverter.derivePublicKeyBase64Coordinates(
            dBase64: invalidBase64,
            curveName: curveName,
          ),
          throwsFormatException,
        );
      });
    });
  });
}

// Вспомогательные функции для тестов
List<int> _hexToBytes(String hex) {
  final cleanHex = hex.startsWith('0x') ? hex.substring(2) : hex;
  final result = <int>[];

  for (int i = 0; i < cleanHex.length; i += 2) {
    final byteHex = cleanHex.substring(i, i + 2);
    result.add(int.parse(byteHex, radix: 16));
  }

  return result;
}

BigInt _bytesToBigInt(List<int> bytes) {
  BigInt result = BigInt.zero;
  for (int i = 0; i < bytes.length; i++) {
    result = result << 8;
    result = result | BigInt.from(bytes[i]);
  }
  return result;
}
