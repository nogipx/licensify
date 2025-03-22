// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';
import 'package:pointycastle/export.dart';

/// Реализация валидатора лицензии
class LicenseValidator implements ILicenseValidator {
  /// Публичный ключ для проверки подписи
  final String _publicKey;

  /// Конструктор
  const LicenseValidator({required String publicKey}) : _publicKey = publicKey;

  @override
  bool validateSignature(License license) {
    try {
      // Получаем округленную дату истечения лицензии
      final roundedExpirationDate = license.expirationDate.roundToMinutes();

      // Cериализуем features и metadata для проверки подписи
      final featuresJson = jsonEncode(license.features);
      final metadataJson = license.metadata != null ? jsonEncode(license.metadata) : '';

      // Формируем данные для проверки подписи (включая все поля)
      final dataToVerify =
          '${license.id}:${license.appId}:${roundedExpirationDate.toIso8601String()}:${license.type.name}:$featuresJson:$metadataJson';

      // Подготавливаем публичный ключ
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(_publicKey);

      // Декодируем подпись из Base64
      final signatureBytes = base64Decode(license.signature);

      // Проверяем подпись с помощью RSA-SHA512
      final verifier = RSASigner(SHA512Digest(), '0609608648016503040203');
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      final signatureParams = Uint8List.fromList(utf8.encode(dataToVerify));
      return verifier.verifySignature(signatureParams, RSASignature(signatureBytes));
    } catch (e) {
      print('Ошибка проверки подписи: $e');
      return false;
    }
  }

  @override
  bool validateExpiration(License license) {
    // Лицензия действительна, если дата истечения еще не наступила
    return !license.isExpired;
  }

  @override
  bool validateLicense(License license) {
    // Лицензия валидна, если подпись верна и срок действия не истек
    return validateSignature(license) && validateExpiration(license);
  }
}
