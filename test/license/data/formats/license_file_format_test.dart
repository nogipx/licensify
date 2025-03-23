// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:licensify/licensify.dart';

void main() {
  group('LicenseFileFormat', () {
    test('encodeToBytes_добавляет_заголовок_и_версию', () {
      // Arrange
      final jsonData = {
        'id': '12345',
        'appId': 'com.test.app',
        'type': 'standard',
      };

      // Act
      final result = LicenseEncoder.encodeToBytes(jsonData);

      // Assert
      expect(
        result.length,
        greaterThan(8),
      ); // Минимальная длина: заголовок + версия
      expect(
        utf8.decode(result.sublist(0, 4)),
        equals('LCSF'),
      ); // Проверка заголовка

      // Проверка версии
      final versionData = ByteData.view(
        result.buffer,
        result.offsetInBytes + 4,
        4,
      );
      final version = versionData.getUint32(0, Endian.little);
      expect(version, equals(LicenseEncoder.formatVersion));
    });

    test('decodeFromBytes_возвращает_корректные_данные', () {
      // Arrange
      final originalData = {
        'id': '12345',
        'appId': 'com.test.app',
        'signature': 'test-signature',
        'type': 'pro',
        'features': <String, dynamic>{'maxUsers': 10},
      };
      final encodedData = LicenseEncoder.encodeToBytes(originalData);

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(encodedData);

      // Assert
      expect(decodedData, isNotNull);
      expect(decodedData!['id'], equals(originalData['id']));
      expect(decodedData['appId'], equals(originalData['appId']));
      expect(decodedData['signature'], equals(originalData['signature']));
      expect(decodedData['type'], equals(originalData['type']));
      expect(
        (decodedData['features'] as Map<String, dynamic>)['maxUsers'],
        equals((originalData['features'] as Map<String, dynamic>)['maxUsers']),
      );
    });

    test('decodeFromBytes_возвращает_null_при_неверном_заголовке', () {
      // Arrange: создаем данные с неправильным заголовком
      final jsonData = utf8.encode(jsonEncode({'id': '12345'}));
      final invalidHeader = utf8.encode('XXXX'); // Неправильный заголовок

      final versionBytes = Uint8List(4);
      final versionData = ByteData.view(versionBytes.buffer);
      versionData.setUint32(0, LicenseEncoder.formatVersion, Endian.little);

      final result =
          BytesBuilder()
            ..add(invalidHeader)
            ..add(versionBytes)
            ..add(jsonData);

      final invalidData = result.toBytes();

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(invalidData);

      // Assert
      expect(decodedData, isNull);
    });

    test('decodeFromBytes_возвращает_null_при_неверной_версии', () {
      // Arrange: создаем данные с неправильной версией
      final jsonData = utf8.encode(jsonEncode({'id': '12345'}));
      final header = utf8.encode(LicenseEncoder.magicHeader);

      final versionBytes = Uint8List(4);
      final versionData = ByteData.view(versionBytes.buffer);
      versionData.setUint32(0, 999, Endian.little); // Неправильная версия

      final result =
          BytesBuilder()
            ..add(header)
            ..add(versionBytes)
            ..add(jsonData);

      final invalidData = result.toBytes();

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(invalidData);

      // Assert
      expect(decodedData, isNull);
    });

    test('decodeFromBytes_возвращает_null_при_неверном_размере', () {
      // Arrange: создаем данные с недостаточной длиной
      final tooShortData = Uint8List(4);

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(tooShortData);

      // Assert
      expect(decodedData, isNull);
    });

    test('decodeFromBytes_возвращает_null_при_некорректном_JSON', () {
      // Arrange: создаем данные с неправильным JSON
      final invalidJson = utf8.encode('{ this is not valid json');
      final header = utf8.encode(LicenseEncoder.magicHeader);

      final versionBytes = Uint8List(4);
      final versionData = ByteData.view(versionBytes.buffer);
      versionData.setUint32(0, LicenseEncoder.formatVersion, Endian.little);

      final result =
          BytesBuilder()
            ..add(header)
            ..add(versionBytes)
            ..add(invalidJson);

      final invalidData = result.toBytes();

      // Act
      final decodedData = LicenseEncoder.decodeFromBytes(invalidData);

      // Assert
      expect(decodedData, isNull);
    });

    test('isValidLicenseFile_возвращает_true_для_корректных_данных', () {
      // Arrange
      final jsonData = {'id': '12345'};
      final encodedData = LicenseEncoder.encodeToBytes(jsonData);

      // Act
      final isValid = LicenseEncoder.isValidLicenseFile(encodedData);

      // Assert
      expect(isValid, isTrue);
    });

    test('isValidLicenseFile_возвращает_false_для_некорректных_данных', () {
      // Arrange: случай 1 - слишком короткие данные
      final tooShortData = Uint8List(4);

      // Arrange: случай 2 - неправильный заголовок
      final jsonData = utf8.encode(jsonEncode({'id': '12345'}));
      final invalidHeader = utf8.encode('XXXX');

      final versionBytes = Uint8List(4);
      final versionData = ByteData.view(versionBytes.buffer);
      versionData.setUint32(0, LicenseEncoder.formatVersion, Endian.little);

      final invalidHeaderData =
          BytesBuilder()
            ..add(invalidHeader)
            ..add(versionBytes)
            ..add(jsonData);

      // Act
      final isValidShort = LicenseEncoder.isValidLicenseFile(tooShortData);
      final isValidWrongHeader = LicenseEncoder.isValidLicenseFile(
        invalidHeaderData.toBytes(),
      );

      // Assert
      expect(isValidShort, isFalse);
      expect(isValidWrongHeader, isFalse);
    });
  });
}
