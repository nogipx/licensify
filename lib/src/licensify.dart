// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: MIT

part of 'package:licensify/licensify.dart';

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
  // 🆔 ГЕНЕРАЦИЯ СЛУЧАЙНЫХ ИДЕНТИФИКАТОРОВ
  // ========================================

  /// Генерирует криптографически стойкий идентификатор NanoID.
  ///
  /// Использует алгоритм, совместимый с оригинальной реализацией NanoID,
  /// и [Random.secure] для равномерного распределения символов. Можно
  /// указать собственный [alphabet] и [size], чтобы адаптировать длину или
  /// набор символов идентификатора.
  static String nanoId({
    int size = NanoId.defaultSize,
    String alphabet = NanoId.defaultAlphabet,
  }) {
    return NanoId.generate(size: size, alphabet: alphabet);
  }

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

  /// Детерминированно выводит симметричный ключ из пользовательского [password].
  ///
  /// Используется Argon2id с теми же параметрами, что и `k4.local-pw`, чтобы
  /// можно было хранить только пароль и соль. Передавайте одну и ту же [salt],
  /// когда нужно восстановить идентичный ключ; соль должна храниться рядом с
  /// бэкапом и быть не короче 16 байт. Соль можно сериализовать через
  /// `LicensifySalt.asString()` (например, положить в footer токена) и затем
  /// восстановить `LicensifySalt.fromString()` при расшифровке.
  ///
  /// **Флоу восстановления бэкапа PASETO v4.local:**
  /// 1. Получите пароль пользователя и сохранённую соль (например, из footer
  ///    PASETO токена или из отдельного хранилища метаданных).
  /// 2. Вызовите `Licensify.encryptionKeyFromPassword()` с теми же [password] и
  ///    [salt], чтобы детерминированно получить исходный симметричный ключ.
  /// 3. Передайте полученный ключ в `Licensify.decryptData()` вместе с PASETO
  ///    токеном (`v4.local`) из резервной копии, чтобы расшифровать содержимое.
  /// 4. После восстановления данных обязательно вызовите `dispose()` для
  ///    полученного ключа и очистите пароль/соль из памяти, если они больше не
  ///    нужны.
  /// 5. Если дополнительно храните запечатанный ключ (`k4.seal`), можно
  ///    восстановить его через `Licensify.encryptionKeyFromPaserkSeal()` и
  ///    использовать как резервное копирование ключа на случай смены пароля.
  static Future<LicensifySymmetricKey> encryptionKeyFromPassword({
    required String password,
    required LicensifySalt salt,
    int memoryCost = K4LocalPw.defaultMemoryCost,
    int timeCost = K4LocalPw.defaultTimeCost,
    int parallelism = K4LocalPw.defaultParallelism,
  }) {
    return LicensifySymmetricKey.fromPassword(
      password: password,
      salt: salt,
      memoryCost: memoryCost,
      timeCost: timeCost,
      parallelism: parallelism,
    );
  }

  /// Генерирует криптографически стойкую соль для функций
  /// [encryptionKeyFromPassword] и `k4.local-pw`.
  ///
  /// По умолчанию возвращает [K4LocalPw.saltLength] байт, используя
  /// `Random.secure()`. Можно указать больший [length], если требуется
  /// дополнительная энтропия. Значения меньше [K4LocalPw.saltLength]
  /// отклоняются.
  static LicensifySalt generatePasswordSalt({
    int length = K4LocalPw.saltLength,
  }) {
    return LicensifySalt.random(length: length);
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
  static LicensifySymmetricKey encryptionKeyFromBytes({
    required List<int> keyBytes,
  }) {
    return LicensifySymmetricKey.xchacha20(
      keyBytes: Uint8List.fromList(keyBytes),
    );
  }

  /// Создает ключ шифрования из PASERK k4.local строки
  static LicensifySymmetricKey encryptionKeyFromPaserk({
    required String paserk,
  }) {
    return LicensifySymmetricKey.fromPaserk(paserk: paserk);
  }

  /// Преобразует симметричный ключ в PASERK k4.local строку
  static String encryptionKeyToPaserk({
    required LicensifySymmetricKey key,
  }) {
    return key.toPaserk();
  }

  /// Возвращает PASERK идентификатор (k4.lid) для симметричного ключа
  static String encryptionKeyIdentifier({
    required LicensifySymmetricKey key,
  }) {
    return key.toPaserkIdentifier();
  }

  /// Создает симметричный ключ из PASERK k4.local-pw строки с использованием пароля
  static Future<LicensifySymmetricKey> encryptionKeyFromPaserkPassword({
    required String paserk,
    required String password,
  }) {
    return LicensifySymmetricKey.fromPaserkPassword(
      paserk: paserk,
      password: password,
    );
  }

  /// Преобразует симметричный ключ в PASERK k4.local-pw строку
  static Future<String> encryptionKeyToPaserkPassword({
    required LicensifySymmetricKey key,
    required String password,
    int memoryCost = K4LocalPw.defaultMemoryCost,
    int timeCost = K4LocalPw.defaultTimeCost,
    int parallelism = K4LocalPw.defaultParallelism,
  }) {
    return key.toPaserkPassword(
      password: password,
      memoryCost: memoryCost,
      timeCost: timeCost,
      parallelism: parallelism,
    );
  }

  /// Создает симметричный ключ из PASERK k4.local-wrap.pie строки,
  /// используя другой симметричный [wrappingKey].
  static LicensifySymmetricKey encryptionKeyFromPaserkWrap({
    required String paserk,
    required LicensifySymmetricKey wrappingKey,
  }) {
    return LicensifySymmetricKey.fromPaserkWrap(
      paserk: paserk,
      wrappingKey: wrappingKey,
    );
  }

  /// Преобразует симметричный ключ в PASERK k4.local-wrap.pie строку,
  /// зашифровав его другим симметричным [wrappingKey].
  static String encryptionKeyToPaserkWrap({
    required LicensifySymmetricKey key,
    required LicensifySymmetricKey wrappingKey,
  }) {
    return key.toPaserkWrap(wrappingKey: wrappingKey);
  }

  /// Создает симметричный ключ из PASERK k4.seal строки, используя пару
  /// Ed25519 ключей [keyPair] для расшифровки. Формат можно хранить вместе с
  /// резервными копиями — расшифровать его способен только владелец приватного
  /// ключа.
  static Future<LicensifySymmetricKey> encryptionKeyFromPaserkSeal({
    required String paserk,
    required LicensifyKeyPair keyPair,
  }) {
    return LicensifySymmetricKey.fromPaserkSeal(
      paserk: paserk,
      keyPair: keyPair,
    );
  }

  /// Запечатывает симметричный ключ в PASERK k4.seal строку для владельца
  /// публичного ключа [publicKey].
  static Future<String> encryptionKeyToPaserkSeal({
    required LicensifySymmetricKey key,
    required LicensifyPublicKey publicKey,
  }) {
    return key.toPaserkSeal(publicKey: publicKey);
  }

  /// Создает ключи подписи из PASERK k4.secret строки
  static LicensifyKeyPair signingKeysFromPaserk({
    required String paserk,
  }) {
    return LicensifyKeyPair.fromPaserkSecret(paserk: paserk);
  }

  /// Преобразует ключи подписи в PASERK k4.secret строку
  static String signingKeysToPaserk({
    required LicensifyKeyPair keyPair,
  }) {
    return keyPair.toPaserkSecret();
  }

  /// Возвращает PASERK идентификатор (k4.sid) для секретного ключа
  static String signingKeyIdentifier({
    required LicensifyKeyPair keyPair,
  }) {
    return keyPair.toPaserkSecretIdentifier();
  }

  /// Создает пару ключей из PASERK k4.secret-pw строки с использованием пароля
  static Future<LicensifyKeyPair> signingKeysFromPaserkPassword({
    required String paserk,
    required String password,
  }) {
    return LicensifyKeyPair.fromPaserkSecretPassword(
      paserk: paserk,
      password: password,
    );
  }

  /// Преобразует ключи подписи в PASERK k4.secret-pw строку
  static Future<String> signingKeysToPaserkPassword({
    required LicensifyKeyPair keyPair,
    required String password,
    int memoryCost = K4SecretPw.defaultMemoryCost,
    int timeCost = K4SecretPw.defaultTimeCost,
    int parallelism = K4SecretPw.defaultParallelism,
  }) {
    return keyPair.toPaserkSecretPassword(
      password: password,
      memoryCost: memoryCost,
      timeCost: timeCost,
      parallelism: parallelism,
    );
  }

  /// Восстанавливает пару ключей из PASERK k4.secret-wrap.pie строки,
  /// используя симметричный [wrappingKey].
  static LicensifyKeyPair signingKeysFromPaserkWrap({
    required String paserk,
    required LicensifySymmetricKey wrappingKey,
  }) {
    return LicensifyKeyPair.fromPaserkSecretWrap(
      paserk: paserk,
      wrappingKey: wrappingKey,
    );
  }

  /// Шифрует пару ключей подписи в PASERK k4.secret-wrap.pie строку при
  /// помощи симметричного [wrappingKey].
  static String signingKeysToPaserkWrap({
    required LicensifyKeyPair keyPair,
    required LicensifySymmetricKey wrappingKey,
  }) {
    return keyPair.toPaserkSecretWrap(wrappingKey: wrappingKey);
  }

  /// Создает публичный ключ из PASERK k4.public строки
  ///
  /// Для публичных ключей отсутствуют паролезащищенные варианты PASERK —
  /// формат `k4.public` уже предназначен для безопасного распространения
  /// открытого ключа без дополнительного шифрования.
  static LicensifyPublicKey publicKeyFromPaserk({
    required String paserk,
  }) {
    return LicensifyPublicKey.fromPaserk(paserk: paserk);
  }

  /// Преобразует публичный ключ в PASERK k4.public строку
  ///
  /// Возвращаемое значение можно хранить и передавать в явном виде — оно не
  /// содержит секрета и служит каноничным текстовым представлением публичного
  /// ключа.
  static String publicKeyToPaserk({
    required LicensifyPublicKey key,
  }) {
    return key.toPaserk();
  }

  /// Возвращает PASERK идентификатор (k4.pid) для публичного ключа
  ///
  /// Идентификатор помогает ссылаться на конкретный публичный ключ в логах и
  /// метаданных, не раскрывая дополнительных секретов.
  static String publicKeyIdentifier({
    required LicensifyPublicKey key,
  }) {
    return key.toPaserkIdentifier();
  }

  /// Проверяет, является ли строка PASERK-представлением ключа
  static bool isPaserk({
    required String data,
  }) {
    return PaserkKey.isPaserk(data);
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

  /// Создает объект лицензии из токена с криптографической валидацией
  ///
  /// 🛡️ Безопасный метод: публичный ключ автоматически обнуляется
  /// в памяти после использования.
  ///
  /// Это основной метод для получения объекта `License` из токена.
  /// Выполняет полную криптографическую проверку:
  /// 1. Валидацию цифровой подписи PASETO v4.public
  /// 2. Проверку структуры данных в токене
  /// 3. Проверку срока действия лицензии
  ///
  /// Если любая из проверок не пройдена, выбрасывается исключение.
  /// В случае успеха возвращается готовый к использованию объект `License`.
  ///
  /// Параметры:
  /// - [token] - PASETO токен лицензии для валидации
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
  ///   final license = await Licensify.fromToken(
  ///     token: storedLicenseToken,
  ///     publicKey: publicKey,
  ///   );
  ///
  ///   print('Лицензия ID: ${await license.id}');
  ///   print('Приложение: ${await license.appId}');
  ///   print('Тип: ${await license.type}');
  ///   print('Истекает: ${await license.expirationDate}');
  ///
  ///   // Теперь можно использовать лицензию
  ///   if (await license.isExpired) {
  ///     print('Лицензия истекла!');
  ///   }
  /// } catch (e) {
  ///   print('Ошибка валидации лицензии: $e');
  ///   // Запретить доступ к приложению
  /// } finally {
  ///   publicKey.dispose(); // Очищаем ключ
  /// }
  /// ```
  static Future<License> fromToken({
    required String token,
    required LicensifyPublicKey publicKey,
  }) async {
    return await publicKey.executeWithKeyBytesAsync((keyBytes) async {
      final validator = _LicenseValidator(publicKey: publicKey);
      return await validator.validateToken(token);
    });
  }

  /// Создает объект лицензии из токена используя байты публичного ключа
  ///
  /// 🛡️ Максимально безопасный метод: создает публичный ключ из байтов,
  /// выполняет валидацию и автоматически очищает ключ.
  ///
  /// Пример:
  /// ```dart
  /// final license = await Licensify.fromTokenWithKeyBytes(
  ///   token: storedLicenseToken,
  ///   publicKeyBytes: storedPublicKeyBytes,
  /// );
  /// ```
  static Future<License> fromTokenWithKeyBytes({
    required String token,
    required List<int> publicKeyBytes,
  }) async {
    final publicKey = LicensifyPublicKey.ed25519(
      keyBytes: Uint8List.fromList(publicKeyBytes),
    );
    try {
      return await fromToken(token: token, publicKey: publicKey);
    } finally {
      publicKey.dispose();
    }
  }

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
    final publicKey = LicensifyPublicKey.ed25519(
      keyBytes: Uint8List.fromList(publicKeyBytes),
    );
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
  // 🔐 АСИММЕТРИЧНОЕ ШИФРОВАНИЕ ДАННЫХ
  // ========================================

  /// Шифрует данные на публичный ключ получателя с использованием `k4.seal`
  ///
  /// Метод генерирует одноразовый симметричный ключ, шифрует [data] в
  /// PASETO `v4.local` токен и запечатывает этот ключ в PASERK `k4.seal`
  /// при помощи [publicKey]. Получившийся контейнер можно передать получателю
  /// и расшифровать только парой ключей, в которую входит соответствующий
  /// приватный ключ.
  ///
  /// Возвращаемый PASETO токен содержит `k4.seal` в footer, поэтому его можно
  /// хранить и передавать как обычную строку.
  static Future<String> encryptDataForPublicKey({
    required Map<String, dynamic> data,
    required LicensifyPublicKey publicKey,
    String? footer,
    String? implicitAssertion,
  }) async {
    return await _LicensifyAsymmetricCrypto.encrypt(
      data: data,
      publicKey: publicKey,
      footer: footer,
      implicitAssertion: implicitAssertion,
    );
  }

  /// Расшифровывает данные, зашифрованные на публичный ключ, используя
  /// полноценную пару ключей [keyPair].
  ///
  /// Метод принимает токен, полученный из [encryptDataForPublicKey],
  /// восстанавливает одноразовый симметричный ключ из `k4.seal` внутри footer
  /// и возвращает исходный JSON с `_footer`, если он задавался.
  static Future<Map<String, dynamic>> decryptDataForKeyPair({
    required String encryptedToken,
    required LicensifyKeyPair keyPair,
    String? implicitAssertion,
  }) async {
    return await _LicensifyAsymmetricCrypto.decrypt(
      encryptedToken: encryptedToken,
      keyPair: keyPair,
      implicitAssertion: implicitAssertion,
    );
  }

  // ========================================
  // 🛠️ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ========================================

  /// Получает информацию о версии библиотеки
  static const String version = '4.3.0';

  /// Получает информацию о поддерживаемых версиях PASETO
  static const List<String> supportedPasetoVersions = ['v4.public', 'v4.local'];
}
