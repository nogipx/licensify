// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/licensify.dart';

void main() async {
  // Генерируем пару RSA ключей
  print('Генерация RSA ключей...');
  final keys = RsaKeyGenerator.generateKeyPairAsPem(bitLength: 2048);

  print('Публичный ключ:');
  print(keys.publicKey);
  print('\nПриватный ключ:');
  print(keys.privateKey);

  // Генерируем лицензию с приватным ключом
  print('\nГенерация тестовой лицензии...');
  final license = GenerateLicenseUseCase(privateKey: keys.privateKey).generateLicense(
    appId: 'com.example.app',
    expirationDate: DateTime.now().add(Duration(days: 30)),
    type: LicenseType.trial,
  );

  print('Сгенерирована лицензия:');
  print('ID: ${license.id}');
  print('Срок действия: ${license.expirationDate}');
  print('Подпись: ${license.signature}');

  // Проверяем лицензию с публичным ключом
  print('\nПроверка лицензии...');
  final validator = LicenseValidator(publicKey: keys.publicKey);

  final isSignatureValid = validator.validateSignature(license);
  print('Подпись валидна: $isSignatureValid');

  final isExpirationValid = validator.validateExpiration(license);
  print('Срок действия валиден: $isExpirationValid');

  final isLicenseValid = validator.validateLicense(license);
  print('Лицензия валидна: $isLicenseValid');

  // Создаем некорректную лицензию для демонстрации проверки
  print('\nПроверка некорректной лицензии...');
  final invalidLicense = License(
    id: license.id,
    appId: license.appId,
    // Изменяем срок действия, что делает подпись недействительной
    expirationDate: license.expirationDate.add(Duration(days: 1)),
    createdAt: license.createdAt,
    signature: license.signature,
    type: license.type,
    features: license.features,
    metadata: license.metadata,
  );

  final isInvalidSignatureValid = validator.validateSignature(invalidLicense);
  print('Подпись некорректной лицензии валидна: $isInvalidSignatureValid');
}
