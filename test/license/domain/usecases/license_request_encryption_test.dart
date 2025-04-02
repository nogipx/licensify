// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';

void main() {
  group('Криптографическая система с ECDSA ключами (p256)', () {
    late LicensifyKeyPair keyPair;
    late String appId;
    late String deviceHash;

    setUp(() {
      // Подготовка: генерируем ключевую пару
      keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p256);
      appId = 'com.example.testapp';

      // Используем фиксированный хеш устройства для предсказуемости тестов
      deviceHash =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    });

    test('Запрос лицензии имеет ожидаемый формат и структуру', () async {
      final generator = keyPair.publicKey.licenseRequestGenerator();
      // Генерируем байты запроса
      final requestBytes = generator(deviceHash: deviceHash, appId: appId);

      // Проверяем формат:

      // 1. Начинается с магического заголовка
      expect(utf8.decode(requestBytes.sublist(0, 4)), equals('MLRQ'));

      // 2. Имеет версию формата (байты 4-8)
      final versionData = ByteData.view(
        Uint8List.fromList(requestBytes.sublist(4, 8)).buffer,
      );
      final version = versionData.getUint32(0, Endian.little);
      expect(version, equals(1));

      // 3. Содержит тип ключа (байт 8)
      final keyType =
          requestBytes[8] == 0 ? LicensifyKeyType.rsa : LicensifyKeyType.ecdsa;
      expect(keyType, equals(LicensifyKeyType.ecdsa));

      // 4. Имеет достаточный размер для содержания данных
      expect(requestBytes.length > 9, isTrue);
    });

    test(
      'Запрос лицензии можно расшифровать с использованием LicenseRequestDecoder',
      () async {
        // Подготовка:
        // 1. Создаем запрос с известными данными
        final generator = keyPair.publicKey.licenseRequestGenerator();
        final requestBytes = generator(deviceHash: deviceHash, appId: appId);

        // 2. Создаем декодер с приватным ключом
        final decoder = keyPair.privateKey.licenseRequestDecoder();

        // 3. Расшифровываем запрос
        final licenseRequest = decoder(requestBytes);

        // Проверяем данные запроса
        expect(licenseRequest.deviceHash, equals(deviceHash));
        expect(licenseRequest.appId, equals(appId));
        expect(
          licenseRequest.expiresAt.isAfter(licenseRequest.createdAt),
          isTrue,
        );

        // Проверяем время жизни запроса (48 часов по умолчанию)
        final duration = licenseRequest.expiresAt.difference(
          licenseRequest.createdAt,
        );
        expect(duration.inHours, equals(48));
      },
    );
  });

  group('Криптографическая система с ECDSA ключами (p521)', () {
    late LicensifyKeyPair keyPair;
    late String appId;
    late String deviceHash;

    setUp(() {
      // Подготовка: генерируем ключевую пару с кривой p521
      keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: EcCurve.p521);
      appId = 'com.example.testapp';

      // Используем фиксированный хеш устройства для предсказуемости тестов
      deviceHash =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    });

    test('Шифрование и расшифровка запроса лицензии с кривой p521', () async {
      // Подготовка:
      // 1. Создаем запрос с настраиваемыми параметрами
      final generator = keyPair.publicKey.licenseRequestGenerator(
        aesKeySize: 192, // Используем 192-битный AES ключ
        hkdfDigest: SHA384Digest(), // Используем SHA-384 для HKDF
        hkdfSalt: 'CUSTOM-SALT-VALUE',
        hkdfInfo: 'CUSTOM-INFO-VALUE',
      );

      final requestBytes = generator(deviceHash: deviceHash, appId: appId);

      // 2. Создаем декодер с такими же параметрами
      final decoder = keyPair.privateKey.licenseRequestDecoder(
        aesKeySize: 192,
        hkdfDigest: SHA384Digest(),
        hkdfSalt: 'CUSTOM-SALT-VALUE',
        hkdfInfo: 'CUSTOM-INFO-VALUE',
      );

      // 3. Расшифровываем запрос
      final licenseRequest = decoder(requestBytes);

      // Проверяем данные запроса
      expect(licenseRequest.deviceHash, equals(deviceHash));
      expect(licenseRequest.appId, equals(appId));

      // Проверяем время жизни запроса
      final duration = licenseRequest.expiresAt.difference(
        licenseRequest.createdAt,
      );
      expect(duration.inHours, equals(48));
    });

    test('Ошибка при несоответствии параметров шифрования', () async {
      // 1. Создаем запрос с одними параметрами
      final generator = keyPair.publicKey.licenseRequestGenerator(
        hkdfSalt: 'SALT-A',
        hkdfInfo: 'INFO-A',
      );

      final requestBytes = generator(deviceHash: deviceHash, appId: appId);

      // 2. Пытаемся расшифровать с другими параметрами
      final decoder = keyPair.privateKey.licenseRequestDecoder(
        hkdfSalt: 'SALT-B', // Другая соль
        hkdfInfo: 'INFO-B', // Другая информация
      );

      // 3. Ожидаем ошибку при расшифровке (неверный AES ключ)
      expect(() => decoder(requestBytes), throwsA(isA<Exception>()));
    });
  });
}

/// Расшифровывает запрос лицензии, используя приватный ключ
///
/// Это тестовая версия, эмулирующая серверную расшифровку
String decryptLicenseRequest(
  Uint8List requestBytes,
  LicensifyPrivateKey privateKey,
) {
  // Проверяем заголовок
  final header = utf8.decode(requestBytes.sublist(0, 4));
  if (header != 'MLRQ') {
    throw Exception('Некорректный формат запроса: неверный заголовок');
  }

  // Проверяем версию формата
  final versionData = ByteData.view(requestBytes.sublist(4, 8).buffer);
  final version = versionData.getUint32(0, Endian.little);
  if (version != 1) {
    throw Exception('Неподдерживаемая версия формата: $version');
  }

  // Проверяем тип ключа
  final keyType =
      requestBytes[8] == 0 ? LicensifyKeyType.rsa : LicensifyKeyType.ecdsa;

  // Получаем зашифрованные данные
  final encryptedData = requestBytes.sublist(9);

  // Расшифровываем зависимо от типа ключа
  if (keyType == LicensifyKeyType.rsa) {
    return decryptWithRsa(encryptedData, privateKey.content);
  } else {
    return decryptWithEcdh(encryptedData, privateKey.content);
  }
}

/// Расшифровывает данные с помощью ECDH
String decryptWithEcdh(Uint8List encryptedData, String privateKeyPem) {
  // Извлекаем размер ключа
  final keyLength = (encryptedData[0] << 8) + encryptedData[1];

  // Извлекаем ephemeral публичный ключ
  final ephemeralPublicKeyBytes = encryptedData.sublist(2, 2 + keyLength);

  // Извлекаем IV (16 байт)
  final ivStart = 2 + keyLength;
  final iv = encryptedData.sublist(ivStart, ivStart + 16);

  // Извлекаем зашифрованные данные
  final ciphertextStart = ivStart + 16;
  final ciphertext = encryptedData.sublist(ciphertextStart);

  // Загружаем приватный ключ
  final privateKey = CryptoUtils.ecPrivateKeyFromPem(privateKeyPem);

  // Десериализуем ephemeral публичный ключ
  final ephemeralPublicKey = deserializeEcPublicKey(ephemeralPublicKeyBytes);

  // Вычисляем общий секрет
  final sharedSecret = computeSharedSecret(privateKey, ephemeralPublicKey);

  // Выводим AES ключ из секрета
  final aesKey = deriveAesKey(sharedSecret);

  // Расшифровываем данные
  final decryptedData = decryptWithAes(ciphertext, aesKey, iv);

  // Преобразуем байты в строку JSON
  return utf8.decode(decryptedData);
}

/// Десериализует публичный ключ из формата X9.63
ECPublicKey deserializeEcPublicKey(Uint8List bytes) {
  if (bytes[0] != 0x04) {
    throw Exception('Неподдерживаемый формат ключа: ${bytes[0]}');
  }

  final halfLength = (bytes.length - 1) ~/ 2;
  final xBytes = bytes.sublist(1, 1 + halfLength);
  final yBytes = bytes.sublist(1 + halfLength);

  final x = bytesToBigInt(xBytes);
  final y = bytesToBigInt(yBytes);

  final domain = ECDomainParameters('secp256r1');
  return ECPublicKey(domain.curve.createPoint(x, y), domain);
}

/// Вычисляет общий секрет по алгоритму ECDH
Uint8List computeSharedSecret(ECPrivateKey privateKey, ECPublicKey publicKey) {
  final agreement = ECDHBasicAgreement();
  agreement.init(privateKey);
  final sharedSecret = agreement.calculateAgreement(publicKey);
  return bigIntToBytes(sharedSecret);
}

/// Выводит AES ключ из общего секрета с помощью HKDF
Uint8List deriveAesKey(Uint8List sharedSecret) {
  // Используем готовый HKDFKeyDerivator из PointyCastle
  final hkdf = HKDFKeyDerivator(SHA256Digest());

  // Параметры для HKDF
  final salt = Uint8List.fromList(utf8.encode('LICENSIFY-ECDH-Salt'));
  final info = Uint8List.fromList(utf8.encode('LICENSIFY-ECDH-AES'));
  final params = HkdfParameters(
    sharedSecret,
    32,
    salt,
    info,
  ); // 32 байта = 256 бит

  hkdf.init(params);

  // Получаем вывод HKDF
  final output = Uint8List(32);
  hkdf.deriveKey(null, 0, output, 0);

  return output;
}

/// Расшифровывает данные с помощью AES в режиме CBC
Uint8List decryptWithAes(Uint8List data, Uint8List key, Uint8List iv) {
  final aesKey = KeyParameter(key);
  final params = ParametersWithIV(aesKey, iv);
  final aesCipher = CBCBlockCipher(AESEngine())..init(false, params);

  final result = Uint8List(data.length);

  // Расшифровываем блоки
  for (var offset = 0; offset < data.length; offset += aesCipher.blockSize) {
    aesCipher.processBlock(data, offset, result, offset);
  }

  // Удаляем PKCS7 padding
  final padLength = result[result.length - 1];
  if (padLength > 0 && padLength <= aesCipher.blockSize) {
    final unpaddedLength = result.length - padLength;
    return result.sublist(0, unpaddedLength);
  }

  return result;
}

/// Расшифровывает данные с помощью RSA
String decryptWithRsa(Uint8List encryptedData, String privateKeyPem) {
  final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

  // Проверяем, это прямое шифрование или гибридная схема
  final isHybrid =
      encryptedData.length > 2 &&
      (encryptedData[0] > 0 || encryptedData[1] > 0);

  if (!isHybrid) {
    // Прямое RSA шифрование
    final decrypter = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decryptedBytes = decrypter.process(encryptedData);
    return utf8.decode(decryptedBytes);
  } else {
    // Гибридная схема RSA + AES
    final keyLength = (encryptedData[0] << 8) + encryptedData[1];
    final encryptedKey = encryptedData.sublist(2, 2 + keyLength);
    final encryptedContent = encryptedData.sublist(2 + keyLength);

    // Расшифровываем AES ключ
    final decrypter = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final keyData = decrypter.process(encryptedKey);

    // Извлекаем ключ и IV
    final aesKey = keyData.sublist(0, 32);
    final aesIv = keyData.sublist(32, 48);

    // Расшифровываем контент
    final decryptedContent = decryptWithAes(encryptedContent, aesKey, aesIv);
    return utf8.decode(decryptedContent);
  }
}

/// Преобразует байты в BigInt
BigInt bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.zero;
  for (int i = 0; i < bytes.length; i++) {
    result = (result << 8) | BigInt.from(bytes[i]);
  }
  return result;
}

/// Преобразует BigInt в байты
Uint8List bigIntToBytes(BigInt number) {
  // Получаем строку в шестнадцатеричном формате
  // Для кривых с большим размером поля (например, p521)
  // необходимо обеспечить достаточную длину
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
