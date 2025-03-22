# Licensify

Продвинутое решение для лицензирования Flutter/Dart приложений с надежной защитой и гибкими опциями.

## Описание

`licensify` - это легковесная, но мощная библиотека для внедрения системы лицензирования в ваши Flutter и Dart приложения. Библиотека предоставляет защищенный механизм проверки лицензий с использованием криптографических подписей и гибкую систему настройки типов лицензий.

### Основные возможности

- 🔒 **Надежная защита**: Использование HMAC-SHA256 для проверки подлинности лицензий
- 🕒 **Управление сроками**: Автоматическая проверка срока действия лицензий
- 🔄 **Разные типы лицензий**: Поддержка trial, standard, pro и других типов
- 📋 **Расширяемые данные**: Возможность добавления custom-параметров в лицензии
- 💾 **Гибкое хранение**: Поддержка файлового хранилища и хранилища в памяти
- 📲 **Простое внедрение**: Легкая интеграция в любое Dart/Flutter приложение

## Установка

Добавьте `licensify` в ваш `pubspec.yaml`:

```yaml
dependencies:
  licensify: ^1.0.0
```

И запустите:

```bash
dart pub get
```

Для Flutter проектов:

```bash
flutter pub get
```

## Использование

### Генерация новой лицензии

```dart
import 'package:licensify/licensify.dart';

// Создание генератора лицензий с приватным ключом
final generator = GenerateLicenseUseCase(signatureKey: yourPrivateKey);

// Генерация новой лицензии
final license = generator.generateLicense(
  appId: 'com.your.app',
  expirationDate: DateTime.now().add(const Duration(days: 30)),
  type: LicenseType.pro,
  features: {'maxUsers': 10, 'canExport': true},
);

// Экспорт в байты для сохранения в файл
final licenseBytes = generator.licenseToBytes(license);
```

### Проверка лицензии

```dart
import 'package:licensify/licensify.dart';

// Создание репозитория и валидатора
final storage = LicenseStorage();
final repository = LicenseRepository(storage: storage);
final validator = LicenseValidator(publicKey: yourPublicKey);

// Создание юзкейса для проверки
final licenseChecker = CheckLicenseUseCase(
  repository: repository,
  validator: validator,
);

// Проверка текущей лицензии
final licenseStatus = await licenseChecker.checkCurrentLicense();

if (licenseStatus.isActive) {
  // Лицензия действительна
  final activeLicense = (licenseStatus as ActiveLicenseStatus).license;
  print('Лицензия активна до: ${activeLicense.expirationDate}');
  print('Осталось дней: ${activeLicense.remainingDays}');
} else if (licenseStatus.isExpired) {
  // Лицензия просрочена
  print('Срок действия лицензии истек');
} else if (licenseStatus.isInvalid) {
  // Лицензия недействительна
  print('Лицензия недействительна (неверная подпись)');
} else if (licenseStatus.isNoLicense) {
  // Лицензия отсутствует
  print('Лицензия не установлена');
} else if (licenseStatus.isError) {
  // Ошибка при проверке
  print('Произошла ошибка при проверке лицензии');
}
```

### Сохранение и загрузка лицензий

```dart
// Сохранение лицензии из файла
final success = await repository.saveLicenseFromFile('path/to/license.dat');

// Сохранение лицензии из байтов
final licenseBytes = readLicenseBytes(); // ваша функция чтения байтов
final savedFromBytes = await repository.saveLicenseFromBytes(licenseBytes);

// Удаление лицензии
final removed = await repository.removeLicense();
```

### Различные типы хранилищ

#### Файловое хранилище (по умолчанию)

```dart
final directoryProvider = DefaultLicenseDirectoryProvider();
final storage = FileLicenseStorage(
  directoryProvider: directoryProvider,
  licenseFileName: 'license.dat',
);
final repository = LicenseRepository(storage: storage);
```

#### Хранилище в памяти

```dart
// Пустое хранилище в памяти
final storage = InMemoryLicenseStorage();

// Или хранилище с предварительно загруженными данными
final licenseData = Uint8List.fromList([/* данные лицензии */]);
final storage = InMemoryLicenseStorage.withData(licenseData);

final repository = LicenseRepository(storage: storage);
```

## Архитектура

Библиотека построена на принципах Clean Architecture:

- **Domain Layer**: Бизнес-логика и основные сущности
  - Entities: License, LicenseStatus
  - Repositories: ILicenseRepository
  - UseCases: CheckLicenseUseCase, GenerateLicenseUseCase

- **Data Layer**: Реализация репозиториев и источников данных
  - Repositories: LicenseRepository
  - Data Sources: 
    - FileLicenseStorage - хранилище лицензий в файловой системе
    - InMemoryLicenseStorage - хранилище лицензий в памяти 
  - Validators: LicenseValidator

## Формат лицензии

Лицензия в `licensify` представляет собой защищенную структуру данных, которая содержит всю необходимую информацию для проверки прав на использование вашего приложения.

### Структура лицензии

```json
{
  "appId": "com.example.myapp",
  "created": "2024-07-25T14:30:00Z",
  "expires": "2025-07-25T14:30:00Z",
  "type": "pro",
  "features": {
    "maxUsers": 50,
    "canExport": true,
    "modules": ["analytics", "reporting", "admin"]
  },
  "signature": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"
}
```

Поля лицензии:
- `appId` - уникальный идентификатор приложения
- `created` - дата создания лицензии в формате ISO 8601
- `expires` - дата окончания срока действия в формате ISO 8601
- `type` - тип лицензии (trial, standard, pro и т.д.)
- `features` - дополнительные параметры лицензии (могут быть любыми JSON-совместимыми типами)
- `signature` - криптографическая подпись для проверки подлинности

### Формат файла лицензии

Лицензия сохраняется в бинарном формате со следующей структурой:

1. **Заголовок** (8 байт) - содержит магическую последовательность 'LCSF' (License File) и версию формата
2. **Метаданные** - JSON-структура, содержащая:
   - `appId`: идентификатор приложения
   - `created`: дата создания в формате ISO 8601
   - `expires`: дата окончания в формате ISO 8601
   - `type`: тип лицензии (число или строка)
   - `features`: объект с дополнительными параметрами
3. **Подпись** - HMAC-SHA256 подпись метаданных, обеспечивающая защиту от подделки

Для создания и проверки лицензий используется пара ключей:
- **Приватный ключ** - используется только на стороне разработчика для создания лицензий
- **Публичный ключ** - встраивается в приложение для проверки подлинности лицензий

### Примечания по безопасности

- Храните приватный ключ в безопасном месте и не включайте его в код приложения
- Для повышения безопасности рекомендуется использовать обфускацию кода
- Механизм HMAC-SHA256 обеспечивает защиту от изменения содержимого лицензии
- В случае особых требований к безопасности рассмотрите возможность дополнительной серверной проверки лицензий

## Лицензия

```
SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
SPDX-License-Identifier: LGPL-3.0-or-later
```

Этот пакет распространяется под лицензией LGPL-3.0. Подробности в файле LICENSE.

---

Создано с ❤️ by nogipx
