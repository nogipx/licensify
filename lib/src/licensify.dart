// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

part of 'crypto/_index.dart';

/// 🔐 Главный фасад для работы с лицензиями Licensify
///
/// Этот класс предоставляет простой и унифицированный API для всех операций
/// с лицензиями, скрывая сложность внутренней архитектуры.
///
/// 🛡️ Все операции автоматически используют безопасные методы с автоматической
/// очисткой ключей в памяти после использования.
///
/// Основные возможности:
/// - Генерация криптографических ключей
/// - Создание подписанных лицензий
/// - Валидация лицензий
/// - Шифрование данных
/// - Автоматическое управление безопасностью ключей
abstract interface class Licensify {
  Licensify._(); // Приватный конструктор - только статические методы

  // ========================================
  // 🔑 УПРАВЛЕНИЕ КЛЮЧАМИ
  // ========================================

  /// Генерирует новую пару ключей Ed25519 для подписи лицензий
  ///
  /// Возвращает объект с приватным и публичным ключом для создания
  /// и валидации лицензий соответственно.
  ///
  /// Пример:
  /// ```dart
  /// final keys = await Licensify.generateSigningKeys();
  /// print('Приватный ключ: ${keys.privateKeyBytes.length} байт');
  /// print('Публичный ключ: ${keys.publicKeyBytes.length} байт');
  /// // Не забудьте вызвать keys.dispose() после использования!
  /// ```
  static Future<LicensifyKeyPair> generateSigningKeys() async {
    return await LicensifyKey.generatePublicKeyPair();
  }

  /// Генерирует симметричный ключ XChaCha20 для шифрования данных
  ///
  /// Используется для создания зашифрованных PASETO v4.local токенов.
  ///
  /// Пример:
  /// ```dart
  /// final encryptionKey = Licensify.generateEncryptionKey();
  /// print('Ключ шифрования: ${encryptionKey.keyLength} байт');
  /// // Не забудьте вызвать encryptionKey.dispose() после использования!
  /// ```
  static LicensifySymmetricKey generateEncryptionKey() {
    return LicensifyKey.generateLocalKey();
  }

  /// Создает пару ключей из существующих байтов
  ///
  /// Полезно для восстановления ключей из файлов или базы данных.
  static LicensifyKeyPair keysFromBytes({
    required List<int> privateKeyBytes,
    required List<int> publicKeyBytes,
  }) {
    return LicensifyKeyPair.ed25519(
      privateKeyBytes: Uint8List.fromList(privateKeyBytes),
      publicKeyBytes: Uint8List.fromList(publicKeyBytes),
    );
  }

  /// Создает ключ шифрования из существующих байтов
  static LicensifySymmetricKey encryptionKeyFromBytes(List<int> keyBytes) {
    return LicensifySymmetricKey.xchacha20(Uint8List.fromList(keyBytes));
  }

  // ========================================
  // 📝 СОЗДАНИЕ ЛИЦЕНЗИЙ
  // ========================================

  /// Создает новую подписанную лицензию с автоматической очисткой ключей
  ///
  /// 🛡️ Безопасный метод: ключи автоматически обнуляются в памяти после использования.
  ///
  /// Это основной метод для генерации лицензий. Автоматически создает
  /// PASETO v4.public токен с цифровой подписью.
  ///
  /// Параметры:
  /// - [privateKey] - приватный ключ для подписи (из [generateSigningKeys])
  /// - [appId] - уникальный идентификатор приложения
  /// - [expirationDate] - дата истечения лицензии
  /// - [type] - тип лицензии (standard, pro, или кастомный)
  /// - [features] - дополнительные возможности лицензии
  /// - [metadata] - метаданные (информация о клиенте, заказе и т.д.)
  /// - [isTrial] - является ли лицензия пробной
  /// - [footer] - незашифрованные дополнительные данные в токене (опционально)
  ///
  /// Пример:
  /// ```dart
  /// final keys = await Licensify.generateSigningKeys();
  /// try {
  ///   final license = await Licensify.createLicense(
  ///     privateKey: keys.privateKey,
  ///     appId: 'com.example.myapp',
  ///     expirationDate: DateTime.now().add(Duration(days: 365)),
  ///     type: LicenseType.pro,
  ///     features: {
  ///       'max_users': 100,
  ///       'api_access': true,
  ///       'premium_support': true,
  ///     },
  ///     metadata: {
  ///       'customer': 'Acme Corp',
  ///       'purchase_order': 'PO-12345',
  ///     },
  ///     footer: '{"key_id": "prod-key-2025", "version": "1.0"}',
  ///   );
  ///   print('Лицензия создана: ${license.token}');
  /// } finally {
  ///   keys.dispose(); // Важно! Очищаем ключи
  /// }
  /// ```
  static Future<License> createLicense({
    required LicensifyPrivateKey privateKey,
    required String appId,
    required DateTime expirationDate,
    LicenseType type = LicenseType.standard,
    Map<String, dynamic> features = const {},
    Map<String, dynamic>? metadata,
    bool isTrial = false,
    String? footer,
  }) async {
    return await privateKey.executeWithKeyBytesAsync((keyBytes) async {
      final generator = _LicenseGenerator(privateKey: privateKey);
      return await generator.call(
        appId: appId,
        expirationDate: expirationDate,
        type: type,
        features: features,
        metadata: metadata,
        isTrial: isTrial,
        footer: footer,
      );
    });
  }

  // ========================================
  // ✅ ВАЛИДАЦИЯ ЛИЦЕНЗИЙ
  // ========================================

  /// Проверяет валидность лицензии с автоматической очисткой ключей
  ///
  /// 🛡️ Безопасный метод: публичный ключ автоматически обнуляется
  /// в памяти после использования.
  ///
  /// Выполняет полную проверку лицензии:
  /// 1. Валидацию цифровой подписи PASETO
  /// 2. Проверку срока действия
  /// 3. Структурную валидацию данных
  ///
  /// Параметры:
  /// - [license] - лицензия для проверки
  /// - [publicKey] - публичный ключ для верификации подписи
  ///
  /// Пример:
  /// ```dart
  /// final publicKey = Licensify.keysFromBytes(
  ///   privateKeyBytes: privateKeyBytes,
  ///   publicKeyBytes: publicKeyBytes,
  /// ).publicKey;
  ///
  /// try {
  ///   final result = await Licensify.validateLicense(
  ///     license: license,
  ///     publicKey: publicKey,
  ///   );
  ///
  ///   if (result.isValid) {
  ///     print('Лицензия действительна!');
  ///     // Разрешить доступ к приложению
  ///   } else {
  ///     print('Ошибка лицензии: ${result.message}');
  ///     // Запретить доступ
  ///   }
  /// } finally {
  ///   publicKey.dispose(); // Очищаем ключ
  /// }
  /// ```
  static Future<LicenseValidationResult> validateLicense({
    required License license,
    required LicensifyPublicKey publicKey,
  }) async {
    return await _SecureLicensifyOperations.validateLicenseSecurely(
      license: license,
      publicKey: publicKey,
    );
  }

  /// Проверяет лицензию используя байты публичного ключа
  ///
  /// 🛡️ Максимально безопасный метод: создает публичный ключ из байтов,
  /// выполняет валидацию и автоматически очищает ключ.
  ///
  /// Пример:
  /// ```dart
  /// final result = await Licensify.validateLicenseWithKeyBytes(
  ///   license: license,
  ///   publicKeyBytes: storedPublicKeyBytes,
  /// );
  /// ```
  static Future<LicenseValidationResult> validateLicenseWithKeyBytes({
    required License license,
    required List<int> publicKeyBytes,
  }) async {
    final publicKey =
        LicensifyPublicKey.ed25519(Uint8List.fromList(publicKeyBytes));
    try {
      return await validateLicense(license: license, publicKey: publicKey);
    } finally {
      publicKey.dispose();
    }
  }

  /// Быстрая проверка только подписи (без проверки срока действия)
  ///
  /// 🛡️ Безопасный метод с автоматической очисткой ключей.
  ///
  /// Полезно для предварительной проверки или когда нужно проверить
  /// только криптографическую целостность токена.
  static Future<LicenseValidationResult> validateSignature({
    required License license,
    required LicensifyPublicKey publicKey,
  }) async {
    final validator = _LicenseValidator(publicKey: publicKey);
    return await validator.validateSignature(license);
  }

  // ========================================
  // 🔒 ШИФРОВАНИЕ ДАННЫХ
  // ========================================

  /// Шифрует данные симметричным ключом
  ///
  /// 🛡️ Безопасный метод: ключ НЕ очищается автоматически,
  /// разработчик должен сам вызвать dispose() после использования.
  ///
  /// Создает зашифрованный PASETO v4.local токен для безопасной
  /// передачи чувствительных данных.
  ///
  /// Параметры:
  /// - [data] - данные для шифрования (JSON-сериализуемые)
  /// - [encryptionKey] - симметричный ключ шифрования
  /// - [footer] - незашифрованные дополнительные данные (опционально)
  ///
  /// Пример:
  /// ```dart
  /// final encryptionKey = Licensify.generateEncryptionKey();
  /// try {
  ///   final encryptedToken = await Licensify.encryptData(
  ///     data: {
  ///       'user_id': 'user123',
  ///       'secret_key': 'sk-1234567890abcdef',
  ///       'permissions': ['read', 'write', 'admin'],
  ///     },
  ///     encryptionKey: encryptionKey,
  ///     footer: 'metadata:version=1.0',
  ///   );
  ///
  ///   // Используем тот же ключ для расшифровки
  ///   final decryptedData = await Licensify.decryptData(
  ///     encryptedToken: encryptedToken,
  ///     encryptionKey: encryptionKey,
  ///   );
  ///
  ///   print('Зашифрованный токен: $encryptedToken');
  /// } finally {
  ///   encryptionKey.dispose(); // Очищаем ключ вручную
  /// }
  /// ```
  static Future<String> encryptData({
    required Map<String, dynamic> data,
    required LicensifySymmetricKey encryptionKey,
    String? footer,
    String? implicitAssertion,
  }) async {
    final crypto = _LicensifySymmetricCrypto(symmetricKey: encryptionKey);
    return await crypto.encrypt(
      data,
      footer: footer,
      implicitAssertion: implicitAssertion,
    );
  }

  /// Расшифровывает данные симметричным ключом
  ///
  /// 🛡️ Безопасный метод: ключ НЕ очищается автоматически,
  /// разработчик должен сам вызвать dispose() после использования.
  ///
  /// Расшифровывает PASETO v4.local токен и возвращает исходные данные.
  ///
  /// Параметры:
  /// - [encryptedToken] - зашифрованный PASETO токен
  /// - [encryptionKey] - симметричный ключ для расшифровки
  ///
  /// Пример:
  /// ```dart
  /// final encryptionKey = Licensify.encryptionKeyFromBytes(keyBytes);
  /// try {
  ///   final decryptedData = await Licensify.decryptData(
  ///     encryptedToken: encryptedToken,
  ///     encryptionKey: encryptionKey,
  ///   );
  ///
  ///   print('Расшифрованные данные: $decryptedData');
  ///   print('ID пользователя: ${decryptedData['user_id']}');
  /// } finally {
  ///   encryptionKey.dispose(); // Очищаем ключ вручную
  /// }
  /// ```
  static Future<Map<String, dynamic>> decryptData({
    required String encryptedToken,
    required LicensifySymmetricKey encryptionKey,
    String? implicitAssertion,
  }) async {
    final crypto = _LicensifySymmetricCrypto(symmetricKey: encryptionKey);
    return await crypto.decrypt(
      encryptedToken,
      implicitAssertion: implicitAssertion,
    );
  }

  // ========================================
  // 🛠️ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ========================================

  /// Получает информацию о версии библиотеки
  static const String version = '3.0.0';

  /// Получает информацию о поддерживаемых версиях PASETO
  static const List<String> supportedPasetoVersions = ['v4.public', 'v4.local'];
}
