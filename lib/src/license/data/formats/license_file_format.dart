// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

/// Утилиты для работы с бинарным форматом файла лицензии
class LicenseFileFormat {
  /// Магическая последовательность для идентификации файлов лицензий
  static const String magicHeader = 'LCSF';

  /// Текущая версия формата файла
  static const int formatVersion = 1;

  /// Преобразует данные лицензии в бинарный формат файла
  ///
  /// Структура файла:
  /// - [0-3] Магическая последовательность 'LCSF'
  /// - [4-7] Версия формата (uint32)
  /// - [8+]  Сериализованный JSON с данными лицензии
  static Uint8List encodeToBytes(Map<String, dynamic> licenseData) {
    // Сериализуем данные лицензии в JSON
    final jsonData = utf8.encode(jsonEncode(licenseData));

    // Создаем буфер для бинарных данных
    final result = BytesBuilder();

    // Добавляем магическую последовательность
    result.add(utf8.encode(magicHeader));

    // Добавляем версию формата (4 байта, little-endian)
    final versionBytes = Uint8List(4);
    final versionData = ByteData.view(versionBytes.buffer);
    versionData.setUint32(0, formatVersion, Endian.little);
    result.add(versionBytes);

    // Добавляем данные лицензии
    result.add(jsonData);

    return result.toBytes();
  }

  /// Декодирует бинарные данные файла лицензии и проверяет формат
  ///
  /// Возвращает null, если формат файла неверный
  static Map<String, dynamic>? decodeFromBytes(Uint8List bytes) {
    try {
      // Проверяем минимальную длину файла (8 байт для заголовка)
      if (bytes.length < 8) {
        return null;
      }

      // Проверяем магическую последовательность
      final headerBytes = bytes.sublist(0, 4);
      final header = utf8.decode(headerBytes);
      if (header != magicHeader) {
        return null;
      }

      // Получаем версию формата
      final versionData = ByteData.view(bytes.buffer, bytes.offsetInBytes + 4, 4);
      final version = versionData.getUint32(0, Endian.little);

      // Проверяем версию (пока поддерживаем только версию 1)
      if (version != formatVersion) {
        return null;
      }

      // Извлекаем JSON данные
      final jsonBytes = bytes.sublist(8);
      final jsonString = utf8.decode(jsonBytes);

      // Парсим JSON
      return jsonDecode(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Проверяет, имеет ли файл правильный формат лицензии
  static bool isValidLicenseFile(Uint8List bytes) {
    if (bytes.length < 8) {
      return false;
    }

    // Проверяем магическую последовательность
    final headerBytes = bytes.sublist(0, 4);
    final header = utf8.decode(headerBytes);
    return header == magicHeader;
  }
}
