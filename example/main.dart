// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

import 'dart:typed_data';
import 'package:licensify/licensify.dart';

/// 🔐 Пример использования унифицированного API Licensify
///
/// Демонстрирует основные возможности библиотеки:
/// - Создание и валидацию лицензий
/// - Шифрование и расшифровку данных
/// - Автоматическую безопасную работу с ключами
Future<void> main() async {
  print('🚀 Licensify Unified API Examples');
  print('=' * 50);

  // ========================================
  // 📝 Базовый workflow с лицензиями
  // ========================================
  await basicLicensingWorkflow();

  print('\n${'=' * 50}');

  // ========================================
  // 🔒 Шифрование данных
  // ========================================
  await dataEncryptionExample();

  print('\n${'=' * 50}');

  // ========================================
  // 🛡️ Продвинутые secure операции
  // ========================================
  await advancedSecureOperations();

  print('\n${'=' * 50}');

  // ========================================
  // 🎯 Лучшие практики безопасности
  // ========================================
  await securityBestPractices();
}

/// Базовый пример создания и валидации лицензий
Future<void> basicLicensingWorkflow() async {
  print('📝 Базовый workflow с лицензиями');
  print('-' * 30);

  // 1. Генерируем ключи
  final keys = await Licensify.generateSigningKeys();

  try {
    print('✅ Ключи сгенерированы');
    print('   Приватный ключ: ${keys.privateKey.keyLength} байт');
    print('   Публичный ключ: ${keys.publicKey.keyLength} байт');

    // 2. Создаем лицензию
    final license = await Licensify.createLicense(
      privateKey: keys.privateKey,
      appId: 'com.example.awesome-app',
      expirationDate: DateTime.now().add(Duration(days: 365)),
      type: LicenseType.pro,
      features: {
        'max_users': 100,
        'api_access': true,
        'premium_support': true,
        'custom_branding': true,
      },
      metadata: {
        'customer': 'Acme Corporation',
        'purchase_order': 'PO-2025-001',
        'sales_rep': 'john.doe@example.com',
      },
    );

    print('✅ Лицензия создана');
    print('   App ID: ${await license.appId}');
    print('   Тип: ${(await license.type).name}');
    print('   Срок: ${await license.expirationDate}');
    print('   Пробная: ${await license.isTrial}');
    print('   Токен: ${license.token.substring(0, 50)}...');

    // 2a. 🎯 НОВЫЙ API: Восстановление лицензии из токена
    print('\n💡 Демонстрация нового API fromToken()...');

    // Эмулируем ситуацию: у разработчика есть только токен и публичный ключ
    final storedToken = license.token; // Токен, который хранится в приложении

    try {
      // Создаем объект License прямо из токена с валидацией
      final restoredLicense = await Licensify.fromToken(
        token: storedToken,
        publicKey: keys.publicKey,
      );

      print('✅ Лицензия восстановлена из токена!');
      print('   Restored ID: ${await restoredLicense.id}');
      print('   Restored App: ${await restoredLicense.appId}');
      print('   Restored Type: ${(await restoredLicense.type).name}');
      print('   Restored Features: ${await restoredLicense.features}');

      // Теперь можно работать с объектом лицензии
      if (await restoredLicense.isExpired) {
        print('   ⚠️ Лицензия истекла!');
      } else {
        print(
            '   ✅ Лицензия действительна ещё ${await restoredLicense.remainingDays} дней');
      }
    } catch (e) {
      print('   ❌ Ошибка восстановления лицензии: $e');
    }

    // 2b. Альтернативный способ с байтами ключа
    final publicKeyBytes = keys.publicKey.keyBytes;
    try {
      final restoredLicense2 = await Licensify.fromTokenWithKeyBytes(
        token: storedToken,
        publicKeyBytes: publicKeyBytes,
      );

      print('✅ Лицензия восстановлена с байтами ключа!');
      print('   Customer: ${(await restoredLicense2.metadata)?['customer']}');
    } catch (e) {
      print('   ❌ Ошибка восстановления с байтами: $e');
    }

    // 3. Быстрая проверка подписи
    final signatureResult = await Licensify.validateSignature(
      license: license,
      publicKey: keys.publicKey,
    );

    print(
        '✅ Подпись ${signatureResult.isValid ? 'действительна' : 'недействительна'}');

    // 4. Полная проверка лицензии (создаем новый ключ из байтов)
    final validationResult = await Licensify.validateLicense(
      license: license,
      publicKey: keys.publicKey,
    );

    if (validationResult.isValid) {
      print('✅ Лицензия действительна!');
      print('   Особенности: ${await license.features}');
      print('   Метаданные: ${await license.metadata}');
    } else {
      print('❌ Ошибка валидации: ${validationResult.message}');
    }
  } finally {
    // 🛡️ Важно! Очищаем ключи
    keys.privateKey.dispose();
    keys.publicKey.dispose();
  }
}

/// Пример шифрования конфиденциальных данных
Future<void> dataEncryptionExample() async {
  print('🔒 Шифрование данных');
  print('-' * 20);

  // 1. Подготавливаем конфиденциальные данные
  final sensitiveData = {
    'user_id': 'user_12345',
    'api_key': 'sk-1234567890abcdef1234567890abcdef',
    'permissions': ['read', 'write', 'admin'],
    'session_data': {
      'login_time': DateTime.now().toIso8601String(),
      'ip_address': '192.168.1.100',
      'user_agent': 'MyApp/1.0.0',
    },
    'secret_config': {
      'database_url': 'postgresql://user:pass@localhost:5432/mydb',
      'redis_url': 'redis://localhost:6379',
      'jwt_secret': 'super-secret-jwt-key-12345',
    },
  };

  // 2. Шифруем данные с явным созданием ключа (максимально безопасно)
  final encryptionKey = Licensify.generateEncryptionKey();
  try {
    final encryptedToken = await Licensify.encryptData(
      data: sensitiveData,
      encryptionKey: encryptionKey,
      footer: 'app_version=1.0.0',
    );

    print('✅ Данные зашифрованы с явным созданием ключа');
    print('   Токен: ${encryptedToken.substring(0, 50)}...');
    print('   Ключ: ${encryptionKey.keyLength} байт');

    // 3. Расшифровываем данные тем же ключом
    final decryptedData = await Licensify.decryptData(
      encryptedToken: encryptedToken,
      encryptionKey: encryptionKey,
    );

    print('✅ Данные расшифрованы');
    print('   User ID: ${decryptedData['user_id']}');
    print('   API Key: ${decryptedData['api_key']}');
    print('   Permissions: ${decryptedData['permissions']}');
  } finally {
    // 🛡️ Важно! Очищаем ключ
    encryptionKey.dispose();
  }
}

/// Продвинутые secure операции с автоматическим управлением ключами
Future<void> advancedSecureOperations() async {
  print('🛡️ Продвинутые secure операции');
  print('-' * 33);

  // 1. Создание лицензии с явным созданием ключей
  print('🔑 Создание лицензии с явным созданием ключей...');

  final keys = await Licensify.generateSigningKeys();
  try {
    final license = await Licensify.createLicense(
      privateKey: keys.privateKey,
      appId: 'com.example.secure-app',
      expirationDate: DateTime.now().add(Duration(days: 30)),
      type: LicenseType('enterprise'),
      features: {
        'unlimited_users': true,
        'custom_integrations': true,
        'priority_support': true,
        'white_labeling': true,
      },
      metadata: {
        'enterprise_tier': 'platinum',
        'contract_id': 'ENT-2025-001',
      },
    );

    print('✅ Лицензия создана с явным созданием ключей');
    print('   App ID: ${await license.appId}');
    print('   Тип: ${(await license.type).name}');
    print('   Публичный ключ: ${keys.publicKey.keyLength} байт');

    // 2. Валидация с байтами ключа
    final publicKeyBytes = Uint8List.fromList(keys.publicKey.keyBytes);
    final validationResult = await Licensify.validateLicenseWithKeyBytes(
      license: license,
      publicKeyBytes: publicKeyBytes,
    );

    print(
        '✅ Валидация с байтами ключа: ${validationResult.isValid ? 'успешна' : 'провалена'}');
  } finally {
    keys.privateKey.dispose();
    keys.publicKey.dispose();
  }

  // 2. Шифрование с явным созданием ключа
  print('🔐 Шифрование с явным созданием ключа...');

  final encryptionKey2 = Licensify.generateEncryptionKey();
  try {
    final encryptedToken = await Licensify.encryptData(
      data: {
        'license_server_config': {
          'endpoint': 'https://api.example.com/licenses',
          'api_token': 'token_abcdef123456',
          'webhook_secret': 'webhook_secret_xyz789',
        },
        'feature_flags': {
          'advanced_analytics': true,
          'multi_tenant': true,
          'custom_themes': true,
        },
      },
      encryptionKey: encryptionKey2,
      footer: 'config_version=2.1.0',
    );

    print('✅ Данные зашифрованы с явным созданием ключа');
    print('   Токен: ${encryptedToken.substring(0, 50)}...');
    print('   Ключ: ${encryptionKey2.keyLength} байт');

    // 3. Расшифровка с тем же ключом
    final decryptedConfig = await Licensify.decryptData(
      encryptedToken: encryptedToken,
      encryptionKey: encryptionKey2,
    );

    print('✅ Конфиг расшифрован');
    print(
        '   Endpoint: ${decryptedConfig['license_server_config']['endpoint']}');
    print('   Feature flags: ${decryptedConfig['feature_flags']}');
  } finally {
    encryptionKey2.dispose();
  }
}

/// Демонстрация лучших практик безопасности
Future<void> securityBestPractices() async {
  print('🎯 Лучшие практики безопасности');
  print('-' * 34);

  // 1. Работа с временными ключами
  print('⏱️  Работа с временными ключами...');

  // Создаем короткоживущие ключи для одноразовых операций
  for (int i = 1; i <= 3; i++) {
    final tempKeys = await Licensify.generateSigningKeys();
    try {
      final tempLicense = await Licensify.createLicense(
        privateKey: tempKeys.privateKey,
        appId: 'com.example.temp-$i',
        expirationDate:
            DateTime.now().add(Duration(minutes: 5)), // Короткий срок
        type: LicenseType('trial'),
        isTrial: true,
        features: {'limited_access': true},
      );

      print('   ✅ Временная лицензия $i создана');
      print('      Срок действия: ${await tempLicense.expirationDate}');
    } finally {
      // Сразу очищаем ключи после использования
      tempKeys.privateKey.dispose();
      tempKeys.publicKey.dispose();
    }
  }

  // 2. Безопасное хранение ключей (пример)
  print('💾 Пример безопасного хранения ключей...');

  final masterKeys = await Licensify.generateSigningKeys();
  try {
    // В реальном приложении эти байты должны храниться зашифрованными
    final keyStorage = masterKeys.asBytes;
    print('   📦 Ключи сохранены для хранения:');
    print('      Приватный: ${keyStorage.privateKeyBytes.length} байт');
    print('      Публичный: ${keyStorage.publicKeyBytes.length} байт');

    // Восстановление ключей из хранилища
    final restoredKeys = Licensify.keysFromBytes(
      privateKeyBytes: keyStorage.privateKeyBytes,
      publicKeyBytes: keyStorage.publicKeyBytes,
    );

    try {
      print('   🔄 Ключи восстановлены из хранилища');

      // Проверяем что ключи работают
      final testLicense = await Licensify.createLicense(
        privateKey: restoredKeys.privateKey,
        appId: 'com.example.restored-key-test',
        expirationDate: DateTime.now().add(Duration(days: 1)),
        type: LicenseType.standard,
      );

      final validation = await Licensify.validateLicense(
        license: testLicense,
        publicKey: restoredKeys.publicKey,
      );

      print('   ✅ Восстановленные ключи работают: ${validation.isValid}');
    } finally {
      restoredKeys.privateKey.dispose();
      restoredKeys.publicKey.dispose();
    }
  } finally {
    masterKeys.privateKey.dispose();
    masterKeys.publicKey.dispose();
  }

  // 3. Рекомендации по безопасности
  print('📋 Рекомендации по безопасности:');
  print('   🔐 Всегда вызывайте dispose() для ключей после использования');
  print('   💾 Храните приватные ключи в зашифрованном виде');
  print('   ⏰ Используйте короткие сроки действия для пробных лицензий');
  print('   🔄 Регулярно ротируйте ключи в production');
  print('   📊 Логируйте все операции с лицензиями для аудита');
  print('   🚫 Никогда не передавайте приватные ключи по сети в открытом виде');
  print(
      '   ✅ Всегда проверяйте результаты валидации перед предоставлением доступа');
}
