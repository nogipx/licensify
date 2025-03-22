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

    // Cериализуем features и metadata для подписи
    final featuresJson = jsonEncode(features);
    final metadataJson = metadata != null ? jsonEncode(metadata) : '';

    // Формируем данные для подписи (включая все поля)
    final dataToSign =
        '$id:$appId:${utcExpirationDate.toIso8601String()}:${type.name}:$featuresJson:$metadataJson';

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
}
