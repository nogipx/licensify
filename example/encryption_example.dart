// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:licensify/licensify.dart';

void main() async {
  // Генерируем пару ключей для примера
  final keyPair = EcdsaKeyGenerator.generateKeyPairAsPem();
  final publicKey = keyPair.publicKey;
  final privateKey = keyPair.privateKey;

  // Создаем шифровальщик с публичным ключом
  final encrypter = EncryptDataUseCase(publicKey: publicKey);

  // Создаем дешифровщик с приватным ключом
  final decrypter = DecryptDataUseCase(privateKey: privateKey);

  // Пример 1: Шифрование строки без заголовка
  final plainText = 'Это секретное сообщение без заголовка';
  print('Исходный текст: $plainText');

  final encrypted1 = encrypter.encryptString(data: plainText);
  print('Зашифрованный текст (hex): ${_bytesToHex(encrypted1)}');

  final decrypted1 = decrypter.decryptToString(encryptedData: encrypted1);
  print('Расшифрованный текст: $decrypted1');
  print('');

  // Пример 2: Шифрование с магическим заголовком
  final secretData = 'Это секретное сообщение с заголовком';
  print('Исходный текст: $secretData');

  final encrypted2 = encrypter.encryptString(
    data: secretData,
    magicHeader: 'TEXT', // Магический заголовок для текста
    formatVersion: 1,
  );
  print('Зашифрованный текст с заголовком (hex): ${_bytesToHex(encrypted2)}');

  // Расшифровка с проверкой магического заголовка
  final decrypted2 = decrypter.decryptToString(
    encryptedData: encrypted2,
    expectedMagicHeader: 'TEXT',
  );
  print('Расшифрованный текст: $decrypted2');
  print('');

  // Пример 3: Шифрование JSON данных
  final jsonData = {
    'name': 'John Doe',
    'age': 30,
    'email': 'john.doe@example.com',
  };

  final jsonString = jsonEncode(jsonData);
  print('Исходный JSON: $jsonString');

  final encrypted3 = encrypter.encryptString(
    data: jsonString,
    magicHeader: 'JSON', // Магический заголовок для JSON
    formatVersion: 1,
  );
  print('Зашифрованный JSON (hex): ${_bytesToHex(encrypted3)}');

  final decrypted3 = decrypter.decryptToString(
    encryptedData: encrypted3,
    expectedMagicHeader: 'JSON',
  );
  print('Расшифрованный JSON: $decrypted3');
  print('Декодированный JSON: ${jsonDecode(decrypted3)}');
}

// Утилита для конвертации байтов в шестнадцатеричную строку
String _bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
