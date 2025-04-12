// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:io';
import 'dart:convert';
import 'package:licensify/licensify.dart';
import '../_base/_index.dart';

/// Command to generate ECDSA key pair
class KeygenCommand extends BaseLicenseCommand {
  @override
  final String name = 'keygen';

  @override
  final String description =
      'Генерация пары ключей ECDSA для создания и проверки лицензий';

  KeygenCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Путь для сохранения ключей',
      defaultsTo: './keys',
    );

    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Базовое имя для файлов ключей',
      defaultsTo: 'ecdsa',
    );

    argParser.addOption(
      'curve',
      help: 'ECDSA кривая (p256, p384, p521)',
      defaultsTo: 'p521',
    );
  }

  @override
  Future<void> run() async {
    final outputDir = argResults!['output'] as String;
    final baseName = argResults!['name'] as String;
    final curveStr = argResults!['curve'] as String;

    // Определение используемой кривой
    EcCurve curve;
    switch (curveStr.toLowerCase()) {
      case 'p384':
        curve = EcCurve.p384;
        break;
      case 'p521':
        curve = EcCurve.p521;
        break;
      case 'p256':
      default:
        curve = EcCurve.p256;
        break;
    }

    try {
      // Создание директории, если не существует
      final directory = Directory(outputDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Генерация ключевой пары
      final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem(curve: curve);

      // Сохранение приватного ключа
      final privateKeyFile = File('$outputDir/$baseName.private.pem');
      await privateKeyFile.writeAsString(keyPair.privateKey.content);

      // Сохранение публичного ключа
      final publicKeyFile = File('$outputDir/$baseName.public.pem');
      await publicKeyFile.writeAsString(keyPair.publicKey.content);

      // Вывод результата в JSON-формате
      final result = {
        'status': 'success',
        'message': 'Пара ключей ECDSA сгенерирована',
        'curve': curveStr,
        'keys': {
          'privateKey': {
            'path': privateKeyFile.path,
            'size': keyPair.privateKey.content.length,
          },
          'publicKey': {
            'path': publicKeyFile.path,
            'size': keyPair.publicKey.content.length,
          },
        },
      };

      print(JsonEncoder.withIndent('  ').convert(result));
    } catch (e) {
      final errorJson = JsonEncoder.withIndent('  ').convert({
        'status': 'error',
        'message': 'Ошибка генерации ключевой пары',
        'error': e.toString(),
      });
      print(errorJson);
    }
  }
}
