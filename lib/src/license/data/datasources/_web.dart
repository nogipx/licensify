// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

// Export web storage implementation for WASM platform
// This is used conditionally only on Web platforms
export 'web/web_factory.dart' if (dart.library.io) 'web/web_storage_stub.dart';
