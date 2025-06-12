// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

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

  // ✅ РЕКОМЕНДУЕМЫЙ способ - автоматическая очистка
  final license = await SecureLicensifyOperations.generateLicenseSecurely(
    operation: (generator) async {
      return await generator.call(
        appId: 'com.example.secure',
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        type: LicenseType.pro,
        features: {
          'max_users': 100,
          'advanced_features': true,
        },
      );
    },
  );

  print('✅ License generated securely');
  print('   Token: ${license.token.substring(0, 40)}...');
  print('   🔒 Keys automatically zeroed after generation\n');
}

/// 2. Автоматическая очистка ключей
Future<void> automaticKeyCleanup() async {
  print('2️⃣ AUTOMATIC KEY CLEANUP');
  print('=========================\n');

  // Симметричное шифрование с автоочисткой
  final encryptedData = await SecureLicensifyOperations.encryptSecurely(
    operation: (crypto) async {
      final sensitiveData = {
        'customer_id': 'ultra-secret-12345',
        'api_key': 'sk-super-secret-api-key',
        'internal_token': 'internal-system-token-xyz',
      };

      return await crypto.encrypt(sensitiveData);
    },
  );

  print('✅ Data encrypted securely');
  print('   Token: ${encryptedData.substring(0, 40)}...');
  print('   🔒 Symmetric key automatically zeroed\n');

  // Валидация с автоочисткой публичного ключа
  final keyPair = await LicensifyKey.generatePublicKeyPair();

  // Создаем лицензию для тестирования
  final testLicense = await keyPair.privateKey.licenseGenerator.call(
    appId: 'com.test.validation',
    expirationDate: DateTime.now().add(const Duration(days: 7)),
  );

  // Валидируем с автоматической очисткой
  final result = await SecureLicensifyOperations.validateLicenseSecurely(
    license: testLicense,
    publicKey: keyPair.publicKey, // Будет автоматически очищен
  );

  print('✅ License validated: ${result.isValid}');
  print('   Message: ${result.message}');
  print('   🔒 Public key automatically zeroed\n');

  // Очищаем оставшийся приватный ключ
  keyPair.privateKey.dispose();
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

    // Безопасный доступ к ключам через лицензию
    final testLicense = await keyPair.privateKey.licenseGenerator.call(
      appId: 'com.test.manual',
      expirationDate: DateTime.now().add(const Duration(days: 1)),
    );

    print('✅ License generated with secure key access');

    // Безопасное шифрование
    final encryptedData = await symmetricKey.crypto.encrypt({
      'secret': 'information',
      'timestamp': DateTime.now().toIso8601String(),
    });

    print('✅ Data encrypted with secure key access');

    print('✅ Data encrypted with temporary key bytes');
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
      '✅ DO - Используйте SecureLicensifyOperations для автоматической очистки');
  print(
      '✅ DO - Всегда вызывайте dispose() в блоке finally при ручном управлении');
  print('✅ DO - Используйте executeWithKeyBytes() для временного доступа');
  print('✅ DO - Минимизируйте время жизни ключей в памяти');
  print('✅ DO - Проверяйте isDisposed перед использованием ключей');

  print('\n❌ DON\'T - Не храните байты ключей в переменных');
  print('❌ DON\'T - Не передавайте keyBytes между функциями без обнуления');
  print('❌ DON\'T - Не забывайте вызывать dispose()');
  print('❌ DON\'T - Не используйте ключи после dispose()');

  print('\n🛡️ ЗАЩИТА ОТ АТАК:');
  print('   • Memory dump attacks - ключи автоматически обнуляются');
  print('   • Key reuse - каждая операция создает временные копии');
  print('   • Accidental exposure - defensive copying предотвращает утечки');
  print('   • Lifecycle management - автоматическая и ручная очистка');

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
}
