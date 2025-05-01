// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

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
  });
}
