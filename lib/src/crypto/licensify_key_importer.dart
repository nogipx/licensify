// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:typed_data';
import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:licensify/licensify.dart';

/// Утилита для импорта криптографических ключей из PEM формата
///
/// Предоставляет удобные методы для создания объектов [LicensifyPrivateKey],
/// [LicensifyPublicKey] и [LicensifyKeyPair] из PEM строк или байтов.
abstract final class LicensifyKeyImporter {
  /// Создает приватный ключ из PEM-строки
  ///
  /// Автоматически определяет тип ключа (RSA или ECDSA) на основе заголовка.
  ///
  /// [pemContent] - содержимое ключа в формате PEM
  ///
  /// Возвращает [LicensifyPrivateKey] с соответствующим типом
  static LicensifyPrivateKey importPrivateKeyFromString(String pemContent) {
    // Проверка содержимого ключа
    _validatePemContent(pemContent);

    // Определение типа ключа
    if (_isRsaPrivateKey(pemContent)) {
      return LicensifyPrivateKey.rsa(pemContent);
    } else if (_isEcdsaPrivateKey(pemContent)) {
      return LicensifyPrivateKey.ecdsa(pemContent);
    }

    throw FormatException(
      'Неподдерживаемый формат приватного ключа. Поддерживаются только RSA и ECDSA ключи',
    );
  }

  /// Создает публичный ключ из PEM-строки
  ///
  /// Автоматически определяет тип ключа (RSA или ECDSA) на основе заголовка.
  ///
  /// [pemContent] - содержимое ключа в формате PEM
  ///
  /// Возвращает [LicensifyPublicKey] с соответствующим типом
  static LicensifyPublicKey importPublicKeyFromString(String pemContent) {
    // Проверка содержимого ключа
    _validatePemContent(pemContent);

    // Определение типа ключа
    if (_isRsaPublicKey(pemContent)) {
      return LicensifyPublicKey.rsa(pemContent);
    } else if (_isEcdsaPublicKey(pemContent)) {
      return LicensifyPublicKey.ecdsa(pemContent);
    }

    throw FormatException(
      'Неподдерживаемый формат публичного ключа. Поддерживаются только RSA и ECDSA ключи',
    );
  }

  /// Создает приватный ключ из байтов в формате PEM
  ///
  /// Автоматически определяет тип ключа (RSA или ECDSA)
  ///
  /// [bytes] - байты содержимого ключа в формате PEM (UTF-8)
  ///
  /// Возвращает [LicensifyPrivateKey] с соответствующим типом
  static LicensifyPrivateKey importPrivateKeyFromBytes(Uint8List bytes) {
    final pemContent = utf8.decode(bytes);
    return importPrivateKeyFromString(pemContent);
  }

  /// Создает публичный ключ из байтов в формате PEM
  ///
  /// Автоматически определяет тип ключа (RSA или ECDSA)
  ///
  /// [bytes] - байты содержимого ключа в формате PEM (UTF-8)
  ///
  /// Возвращает [LicensifyPublicKey] с соответствующим типом
  static LicensifyPublicKey importPublicKeyFromBytes(Uint8List bytes) {
    final pemContent = utf8.decode(bytes);
    return importPublicKeyFromString(pemContent);
  }

  /// Импортирует пару ключей из PEM строк
  ///
  /// [privateKeyPem] - содержимое приватного ключа в формате PEM
  /// [publicKeyPem] - содержимое публичного ключа в формате PEM
  ///
  /// Возвращает [LicensifyKeyPair] с соответствующим типом
  static LicensifyKeyPair importKeyPairFromStrings({
    required String privateKeyPem,
    required String publicKeyPem,
  }) {
    final privateKey = importPrivateKeyFromString(privateKeyPem);
    final publicKey = importPublicKeyFromString(publicKeyPem);

    final keyPair = LicensifyKeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );

    // Проверка совместимости ключей
    if (!keyPair.isConsistent) {
      throw FormatException(
        'Несовместимые типы ключей. Приватный ключ: ${privateKey.keyType}, '
        'публичный ключ: ${publicKey.keyType}',
      );
    }

    return keyPair;
  }

  /// Импортирует пару ключей из байтов в формате PEM
  ///
  /// [privateKeyBytes] - байты приватного ключа в формате PEM (UTF-8)
  /// [publicKeyBytes] - байты публичного ключа в формате PEM (UTF-8)
  ///
  /// Возвращает [LicensifyKeyPair] с соответствующим типом
  static LicensifyKeyPair importKeyPairFromBytes({
    required Uint8List privateKeyBytes,
    required Uint8List publicKeyBytes,
  }) {
    final privateKey = importPrivateKeyFromBytes(privateKeyBytes);
    final publicKey = importPublicKeyFromBytes(publicKeyBytes);

    final keyPair = LicensifyKeyPair(
      privateKey: privateKey,
      publicKey: publicKey,
    );

    // Проверка совместимости ключей
    if (!keyPair.isConsistent) {
      throw FormatException(
        'Несовместимые типы ключей. Приватный ключ: ${privateKey.keyType}, '
        'публичный ключ: ${publicKey.keyType}',
      );
    }

    return keyPair;
  }

  /// Проверяет корректность PEM-содержимого
  static void _validatePemContent(String pemContent) {
    if (pemContent.trim().isEmpty) {
      throw FormatException('Пустое содержимое PEM');
    }

    if (!pemContent.contains('-----BEGIN') ||
        !pemContent.contains('-----END')) {
      throw FormatException(
        'Неверный формат PEM. Отсутствует заголовок или концовка PEM',
      );
    }
  }

  /// Проверяет, является ли ключ RSA приватным ключом
  static bool _isRsaPrivateKey(String pemContent) {
    // Сначала проверяем по заголовку
    if (pemContent.contains('-----BEGIN RSA PRIVATE KEY-----')) {
      return true;
    }

    // Проверяем обычный PKCS#8 приватный ключ
    if (pemContent.contains('-----BEGIN PRIVATE KEY-----')) {
      try {
        // Пытаемся расшифровать как RSA ключ - если получается, это RSA
        CryptoUtils.rsaPrivateKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // Если ошибка, пробуем ECDSA
        try {
          CryptoUtils.ecPrivateKeyFromPem(pemContent);
          return false; // Это ECDSA ключ
        } catch (_) {
          // Не смогли определить тип, предполагаем RSA
          // (так как это более распространенный формат)
          return true;
        }
      }
    }

    return false;
  }

  /// Проверяет, является ли ключ ECDSA приватным ключом
  static bool _isEcdsaPrivateKey(String pemContent) {
    // Сначала проверяем по заголовку
    if (pemContent.contains('-----BEGIN EC PRIVATE KEY-----')) {
      return true;
    }

    // Проверяем обычный PKCS#8 приватный ключ
    if (pemContent.contains('-----BEGIN PRIVATE KEY-----')) {
      try {
        // Пытаемся расшифровать как ECDSA ключ - если получается, это ECDSA
        CryptoUtils.ecPrivateKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // Если ошибка, это не ECDSA ключ
        return false;
      }
    }

    return false;
  }

  /// Проверяет, является ли ключ RSA публичным ключом
  static bool _isRsaPublicKey(String pemContent) {
    // Сначала проверяем по заголовку
    if (pemContent.contains('-----BEGIN RSA PUBLIC KEY-----')) {
      return true;
    }

    // Проверяем обычный PKCS#8 публичный ключ
    if (pemContent.contains('-----BEGIN PUBLIC KEY-----')) {
      try {
        // Пытаемся расшифровать как RSA ключ - если получается, это RSA
        CryptoUtils.rsaPublicKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // Если ошибка, пробуем ECDSA
        try {
          CryptoUtils.ecPublicKeyFromPem(pemContent);
          return false; // Это ECDSA ключ
        } catch (_) {
          // Не смогли определить тип, предполагаем RSA
          return true;
        }
      }
    }

    return false;
  }

  /// Проверяет, является ли ключ ECDSA публичным ключом
  static bool _isEcdsaPublicKey(String pemContent) {
    // Сначала проверяем по заголовку
    if (pemContent.contains('-----BEGIN EC PUBLIC KEY-----')) {
      return true;
    }

    // Проверяем обычный PKCS#8 публичный ключ
    if (pemContent.contains('-----BEGIN PUBLIC KEY-----')) {
      try {
        // Пытаемся расшифровать как ECDSA ключ - если получается, это ECDSA
        CryptoUtils.ecPublicKeyFromPem(pemContent);
        return true;
      } catch (_) {
        // Если ошибка, это не ECDSA ключ
        return false;
      }
    }

    return false;
  }
}
