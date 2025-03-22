// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

/// Сценарий использования для генерации лицензии
class GenerateLicenseUseCase {
  /// Приватный ключ для подписи лицензии
  final String _privateKey;

  /// Конструктор
  const GenerateLicenseUseCase({required String privateKey}) : _privateKey = privateKey;

  /// Генерирует новую лицензию
  License generateLicense({
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.trial,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
  }) {
    final id = const Uuid().v4();

    // Округляем время создания до минут
    final createdAt = DateTime.now().toUtc().roundToMinutes();

    // Преобразуем дату истечения в UTC и округляем до минут
    final utcExpirationDate = expirationDate.roundToMinutes();

    // Формируем данные для подписи
    final dataToSign = '$id:$appId:${utcExpirationDate.toIso8601String()}:${type.name}';

    // Создаем RSA подпись с приватным ключом
    final privateKey = CryptoUtils.rsaPrivateKeyFromPem(_privateKey);
    final signer = RSASigner(SHA512Digest(), '0609608648016503040203');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final signatureBytes = signer.generateSignature(Uint8List.fromList(utf8.encode(dataToSign)));
    final signature = base64Encode(signatureBytes.bytes);

    // Создаем лицензию
    return License(
      id: id,
      appId: appId,
      expirationDate: utcExpirationDate,
      createdAt: createdAt,
      signature: signature,
      type: type,
      features: features,
      metadata: metadata,
    );
  }

  /// Преобразует лицензию в бинарные данные
  Uint8List licenseToBytes(License license) {
    // Преобразуем в JSON
    final Map<String, dynamic> jsonData = {
      'id': license.id,
      'appId': license.appId,
      'expirationDate': license.expirationDate.toIso8601String(),
      'createdAt': license.createdAt.toIso8601String(),
      'signature': license.signature,
      'type': license.type.name,
      'features': license.features,
      'metadata': license.metadata,
    };

    // Сериализуем в строку JSON
    final jsonString = jsonEncode(jsonData);

    // Преобразуем в бинарные данные
    return utf8.encode(jsonString);
  }
}
