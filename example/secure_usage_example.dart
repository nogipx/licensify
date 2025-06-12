// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'package:licensify/licensify.dart';

/// 🔐 Примеры безопасного использования Licensify
///
/// Демонстрирует различные подходы к защите ключей в памяти
/// и автоматической очистке после использования.
void main() async {
  print('🔐 SECURE LICENSIFY USAGE EXAMPLES');
  print('===================================\n');

  await basicSecureUsage();
  await automaticKeyCleanup();
  await manualKeyManagement();
  await bestPracticesDemo();
}

/// 1. Базовое безопасное использование
Future<void> basicSecureUsage() async {
  print('1️⃣ BASIC SECURE USAGE');
  print('======================\n');

  // ✅ РЕКОМЕНДУЕМЫЙ способ - автоматическая генерация и очистка ключей
  final result = await Licensify.createLicenseWithKeys(
    appId: 'com.example.secure',
    expirationDate: DateTime.now().add(const Duration(days: 30)),
    type: LicenseType.pro,
    features: {
      'max_users': 100,
      'advanced_features': true,
    },
  );

  print('✅ License generated securely');
  print('   Token: ${result.license.token.substring(0, 40)}...');
  print('   🔒 Private key automatically zeroed after generation');
  print('   📦 Public key bytes: ${result.publicKeyBytes.length} bytes\n');
}

/// 2. Автоматическая очистка ключей
Future<void> automaticKeyCleanup() async {
  print('2️⃣ AUTOMATIC KEY CLEANUP');
  print('=========================\n');

  // Симметричное шифрование с автоочисткой
  final encryptResult = await Licensify.encryptDataWithKey(
    data: {
      'customer_id': 'ultra-secret-12345',
      'api_key': 'sk-super-secret-api-key',
      'internal_token': 'internal-system-token-xyz',
    },
  );

  print('✅ Data encrypted securely');
  print('   Token: ${encryptResult.encryptedToken.substring(0, 40)}...');
  print('   🔒 Symmetric key automatically zeroed');
  print('   📦 Key bytes: ${encryptResult.keyBytes.length} bytes\n');

  // Валидация с автоочисткой публичного ключа
  final keyPair = await LicensifyKey.generatePublicKeyPair();

  // Создаем лицензию для тестирования
  final testLicense = await Licensify.createLicense(
    privateKey: keyPair.privateKey,
    appId: 'com.test.validation',
    expirationDate: DateTime.now().add(const Duration(days: 7)),
  );

  // Валидируем с автоматической очисткой через байты ключа
  final publicKeyBytes = Uint8List.fromList(keyPair.publicKey.keyBytes);
  final result = await Licensify.validateLicenseWithKeyBytes(
    license: testLicense,
    publicKeyBytes: publicKeyBytes,
  );

  print('✅ License validated: ${result.isValid}');
  print('   Message: ${result.message}');
  print('   🔒 Public key automatically zeroed\n');

  // Очищаем оставшиеся ключи
  keyPair.privateKey.dispose();
  keyPair.publicKey.dispose();
}

/// 3. Ручное управление ключами (продвинутый уровень)
Future<void> manualKeyManagement() async {
  print('3️⃣ MANUAL KEY MANAGEMENT');
  print('==========================\n');

  LicensifyKeyPair? keyPair;
  LicensifySymmetricKey? symmetricKey;

  try {
    // Генерируем ключи
    keyPair = await LicensifyKey.generatePublicKeyPair();
    symmetricKey = LicensifyKey.generateLocalKey();

    print('✅ Keys generated');
    print('   Private key disposed: ${keyPair.privateKey.isDisposed}');
    print('   Public key disposed: ${keyPair.publicKey.isDisposed}');
    print('   Symmetric key disposed: ${symmetricKey.isDisposed}');

    // Безопасный доступ к ключам через унифицированное API
    final testLicense = await Licensify.createLicense(
      privateKey: keyPair.privateKey,
      appId: 'com.test.manual',
      expirationDate: DateTime.now().add(const Duration(days: 1)),
    );

    print('✅ License generated with secure key access');

    // Безопасное шифрование
    final encryptedData = await Licensify.encryptData(
      data: {
        'secret': 'information',
        'timestamp': DateTime.now().toIso8601String(),
      },
      encryptionKey: symmetricKey,
    );

    print('✅ Data encrypted with secure key access');
    print('   Token: ${encryptedData.substring(0, 40)}...');

    // Валидация лицензии
    final validationResult = await Licensify.validateLicense(
      license: testLicense,
      publicKey: keyPair.publicKey,
    );

    print('✅ License validation: ${validationResult.isValid}');
    print('   🔒 All temporary key copies automatically zeroed');
  } finally {
    // ВСЕГДА очищаем ключи в блоке finally
    keyPair?.privateKey.dispose();
    keyPair?.publicKey.dispose();
    symmetricKey?.dispose();

    print('\n🔒 All keys manually disposed');
    print(
        '   Private key disposed: ${keyPair?.privateKey.isDisposed ?? 'null'}');
    print('   Public key disposed: ${keyPair?.publicKey.isDisposed ?? 'null'}');
    print('   Symmetric key disposed: ${symmetricKey?.isDisposed ?? 'null'}');
  }
}

/// 4. Демонстрация лучших практик безопасности
Future<void> bestPracticesDemo() async {
  print('\n4️⃣ SECURITY BEST PRACTICES');
  print('============================\n');

  print(
      '✅ DO - Используйте Licensify.createLicenseWithKeys() для автоматической очистки');
  print(
      '✅ DO - Используйте Licensify.encryptDataWithKey() для одноразового шифрования');
  print(
      '✅ DO - Используйте Licensify.validateLicenseWithKeyBytes() для валидации');
  print(
      '✅ DO - Всегда вызывайте dispose() в блоке finally при ручном управлении');
  print('✅ DO - Минимизируйте время жизни ключей в памяти');
  print('✅ DO - Проверяйте isDisposed перед использованием ключей');

  print('\n❌ DON\'T - Не храните байты ключей в переменных без необходимости');
  print('❌ DON\'T - Не передавайте keyBytes между функциями без обнуления');
  print('❌ DON\'T - Не забывайте вызывать dispose()');
  print('❌ DON\'T - Не используйте ключи после dispose()');
  print('❌ DON\'T - Не используйте приватные классы напрямую');

  print('\n🛡️ ЗАЩИТА ОТ АТАК:');
  print('   • Memory dump attacks - ключи автоматически обнуляются');
  print('   • Key reuse - каждая операция создает временные копии');
  print('   • Accidental exposure - defensive copying предотвращает утечки');
  print('   • Lifecycle management - автоматическая и ручная очистка');
  print('   • API misuse - приватные классы недоступны извне');

  print('\n⚠️ ОГРАНИЧЕНИЯ В DART:');
  print('   • Нет native secure memory как в C/C++');
  print('   • GC может перемещать данные в памяти');
  print('   • Нет гарантий немедленной очистки памяти');
  print('   • Но наша реализация значительно снижает риски!');

  print('\n📖 ДОПОЛНИТЕЛЬНЫЕ РЕКОМЕНДАЦИИ:');
  print('   • Используйте HTTPS для передачи токенов');
  print('   • Храните приватные ключи в secure storage');
  print('   • Применяйте короткие сроки действия токенов');
  print('   • Логируйте попытки использования недействительных ключей');
  print(
      '   • Рассмотрите возможность использования HSM для критических приложений');
  print(
      '   • Используйте только публичное API Licensify для максимальной безопасности');

  print('\n🎯 ПРИМЕРЫ БЕЗОПАСНЫХ ПАТТЕРНОВ:');

  // Паттерн 1: Одноразовое шифрование
  print('\n   📦 Паттерн 1: Одноразовое шифрование');
  await Licensify.encryptDataWithKey(
    data: {'temp': 'data'},
  );
  print('      ✅ Ключ автоматически сгенерирован и очищен');
  print('      📝 Сохраните keyBytes безопасно для расшифровки');

  // Паттерн 2: Быстрая валидация
  print('\n   🔍 Паттерн 2: Быстрая валидация с байтами ключа');
  final quickLicense = await Licensify.createLicenseWithKeys(
    appId: 'com.example.quick',
    expirationDate: DateTime.now().add(const Duration(hours: 1)),
  );

  final quickValidation = await Licensify.validateLicenseWithKeyBytes(
    license: quickLicense.license,
    publicKeyBytes: quickLicense.publicKeyBytes,
  );
  print('      ✅ Валидация: ${quickValidation.isValid}');
  print('      🔒 Все ключи автоматически очищены');

  print('\n🚀 Используйте эти паттерны для максимальной безопасности!');
}
