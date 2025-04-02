// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Утилиты для работы с ECDH шифрованием
abstract interface class ECDHCryptoUtils {
  /// Проверяет совместимость параметров домена эллиптической кривой
  static bool areDomainsCompatible(
    ECDomainParameters domain1,
    ECDomainParameters domain2,
  ) {
    // Для совместимости должны совпадать: кривая, точка G, порядок n
    return domain1.curve.a == domain2.curve.a &&
        domain1.curve.b == domain2.curve.b &&
        domain1.curve.fieldSize == domain2.curve.fieldSize &&
        domain1.G.x == domain2.G.x &&
        domain1.G.y == domain2.G.y &&
        domain1.n == domain2.n;
  }

  /// Дополняет или обрезает массив байтов до указанной длины
  static Uint8List padOrTrimBytes(Uint8List bytes, int length) {
    if (bytes.length == length) {
      return bytes;
    } else if (bytes.length > length) {
      // Если массив слишком длинный, обрезаем лишние нули слева
      return bytes.sublist(bytes.length - length);
    } else {
      // Если массив слишком короткий, дополняем нулями слева
      final result = Uint8List(length);
      result.setRange(length - bytes.length, length, bytes);
      return result;
    }
  }

  /// Выводит AES-ключ из общего секрета с использованием HKDF
  static Uint8List deriveAesKey({
    required Uint8List sharedSecret,
    required int aesKeySize,
    required Digest hkdfDigest,
    required String hkdfSalt,
    required String hkdfInfo,
  }) {
    // Используем готовый HKDFKeyDerivator из PointyCastle
    final hkdf = HKDFKeyDerivator(hkdfDigest);

    // Размер ключа в байтах
    final keyLength = aesKeySize ~/ 8;

    // Параметры для HKDF
    final salt = Uint8List.fromList(utf8.encode(hkdfSalt));
    final info = Uint8List.fromList(utf8.encode(hkdfInfo));
    final params = HkdfParameters(sharedSecret, keyLength, salt, info);

    hkdf.init(params);

    // Получаем вывод HKDF
    final output = Uint8List(keyLength);
    hkdf.deriveKey(null, 0, output, 0);

    return output;
  }

  /// Сериализует публичный ECDSA ключ в формат X9.63
  static Uint8List serializeEcPublicKey(ECPublicKey publicKey) {
    final q = publicKey.Q!;

    // Получаем параметры кривой для определения длины байтов
    final curveParameters = publicKey.parameters!;
    final fieldSize = (curveParameters.curve.fieldSize + 7) ~/ 8;

    // Используем CryptoUtils для преобразования BigInt в байты
    final xBytes = padOrTrimBytes(
      _bigIntToBytes(q.x!.toBigInteger()!),
      fieldSize,
    );
    final yBytes = padOrTrimBytes(
      _bigIntToBytes(q.y!.toBigInteger()!),
      fieldSize,
    );

    // X9.63 format: 0x04 | X | Y (uncompressed point)
    return Uint8List.fromList([0x04, ...xBytes, ...yBytes]);
  }

  /// Десериализует публичный ECDSA ключ из формата X9.63
  static ECPublicKey deserializeEcPublicKey(
    Uint8List bytes,
    ECDomainParameters domain,
  ) {
    // Проверяем формат (несжатая точка)
    if (bytes[0] != 0x04) {
      throw ArgumentError('Unsupported key format: ${bytes[0]}');
    }

    // Длина каждой координаты
    final halfLength = (bytes.length - 1) ~/ 2;

    // Если длина координат не соответствует размеру поля кривой, это неправильный формат
    final expectedFieldSize = (domain.curve.fieldSize + 7) ~/ 8;
    if (halfLength != expectedFieldSize) {
      throw ArgumentError(
        'Point coordinates size mismatch: expected $expectedFieldSize bytes, got $halfLength bytes. '
        'This likely indicates that the point was encoded for a different curve.',
      );
    }

    // Извлекаем координаты X и Y
    final xBytes = bytes.sublist(1, 1 + halfLength);
    final yBytes = bytes.sublist(1 + halfLength);

    // Преобразуем байты в BigInt
    final x = _bytesToBigInt(xBytes);
    final y = _bytesToBigInt(yBytes);

    try {
      // Создаем точку на кривой
      final point = domain.curve.createPoint(x, y);
      return ECPublicKey(point, domain);
    } catch (e) {
      throw ArgumentError(
        'Invalid point or incompatible with the curve parameters: ${e.toString()}',
      );
    }
  }

  /// Вычисляет общий секрет с использованием ECDH
  static Uint8List computeSharedSecret(
    ECPrivateKey privateKey,
    ECPublicKey publicKey,
  ) {
    // Проверка совместимости параметров кривых
    final privateParams = privateKey.parameters!;
    final publicParams = publicKey.parameters!;

    // Сначала проверяем, что названия доменов совпадают, если они доступны
    final privateDomainName = privateParams.domainName;
    final publicDomainName = publicParams.domainName;

    if (privateDomainName != publicDomainName) {
      throw ArgumentError(
        'Incompatible curves: private key uses $privateDomainName, public key uses $publicDomainName',
      );
    }

    // Затем проверяем параметры кривых напрямую
    if (!areDomainsCompatible(privateParams, publicParams)) {
      throw ArgumentError(
        'Incompatible EC domain parameters between private and public keys',
      );
    }

    // Размеры полей должны совпадать
    if (privateParams.curve.fieldSize != publicParams.curve.fieldSize) {
      throw ArgumentError(
        'Field size mismatch: private key ${privateParams.curve.fieldSize} bits, '
        'public key ${publicParams.curve.fieldSize} bits',
      );
    }

    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey);
    final sharedSecret = agreement.calculateAgreement(publicKey);

    return _bigIntToBytes(sharedSecret);
  }

  /// Шифрует данные с использованием AES в режиме CBC
  static Uint8List encryptWithAes(Uint8List data, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final params = ParametersWithIV(aesKey, iv);
    final aesCipher = CBCBlockCipher(AESEngine())..init(true, params);

    // Добавляем PKCS7 padding
    final paddedData = _addPkcs7Padding(data, aesCipher.blockSize);

    final result = Uint8List(paddedData.length);

    // Шифруем блоки
    for (
      var offset = 0;
      offset < paddedData.length;
      offset += aesCipher.blockSize
    ) {
      aesCipher.processBlock(paddedData, offset, result, offset);
    }

    return result;
  }

  /// Расшифровывает данные с использованием AES в режиме CBC
  static Uint8List decryptWithAes(Uint8List data, Uint8List key, Uint8List iv) {
    final aesKey = KeyParameter(key);
    final params = ParametersWithIV(aesKey, iv);
    final aesCipher = CBCBlockCipher(AESEngine())..init(false, params);

    final result = Uint8List(data.length);

    // Расшифровываем блоки
    for (var offset = 0; offset < data.length; offset += aesCipher.blockSize) {
      aesCipher.processBlock(data, offset, result, offset);
    }

    // Удаляем PKCS7 padding
    return _removePkcs7Padding(result, aesCipher.blockSize);
  }

  /// Генерирует случайный инициализационный вектор для AES
  static Uint8List generateRandomIv() {
    final secureRandom = FortunaRandom();

    // Инициализируем генератор случайных чисел
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // IV для AES всегда 16 байт (128 бит)
    return secureRandom.nextBytes(16);
  }

  /// Генерирует случайную пару ключей ECDH
  static AsymmetricKeyPair<ECPublicKey, ECPrivateKey> generateEphemeralKeyPair(
    ECDomainParameters domainParams,
  ) {
    final keyGen = KeyGenerator('EC');
    final random = FortunaRandom();

    // Инициализируем генератор случайных чисел
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Параметры для генерации ключей
    final ecParams = ECKeyGeneratorParameters(domainParams);
    final params = ParametersWithRandom(ecParams, random);

    // Генерируем пару ключей
    keyGen.init(params);
    final keyPair = keyGen.generateKeyPair();

    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
      keyPair.publicKey as ECPublicKey,
      keyPair.privateKey as ECPrivateKey,
    );
  }

  // Вспомогательные приватные методы

  /// Конвертирует BigInt в Uint8List
  static Uint8List _bigIntToBytes(BigInt number) {
    // Получаем строку в шестнадцатеричном формате без лишних нулей
    final hexString = number.toRadixString(16);

    // Если длина нечетная, добавляем 0 в начало
    final paddedHexString = hexString.length.isOdd ? '0$hexString' : hexString;

    final bytes = <int>[];

    // Преобразуем каждую пару символов в байт
    for (var i = 0; i < paddedHexString.length; i += 2) {
      final byteStr = paddedHexString.substring(i, i + 2);
      final byte = int.parse(byteStr, radix: 16);
      bytes.add(byte);
    }

    return Uint8List.fromList(bytes);
  }

  /// Конвертирует Uint8List в BigInt
  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  /// Добавляет PKCS7 padding к данным
  static Uint8List _addPkcs7Padding(Uint8List data, int blockSize) {
    final padLength = blockSize - (data.length % blockSize);
    final paddedData = Uint8List(data.length + padLength);

    // Копируем исходные данные
    paddedData.setAll(0, data);

    // Добавляем padding
    paddedData.fillRange(data.length, paddedData.length, padLength);

    return paddedData;
  }

  /// Удаляет PKCS7 padding из данных
  static Uint8List _removePkcs7Padding(Uint8List data, int blockSize) {
    final padLength = data[data.length - 1];

    if (padLength > 0 && padLength <= blockSize) {
      final unpaddedLength = data.length - padLength;
      return data.sublist(0, unpaddedLength);
    }

    return data;
  }
}
