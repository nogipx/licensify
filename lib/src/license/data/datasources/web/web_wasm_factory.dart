// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

// This file is a conditional import for the WebAssembly platform
// It should not be imported directly, but through web_factory.dart

import 'package:licensify/src/license/data/datasources/web/storage/web_license_storage.dart';
import 'package:licensify/src/license/data/datasources/web/interop/js_interop.dart'
    as wasm_interop;

/// Factory for creating web implementations for WebAssembly platform
///
/// This class provides platform-specific implementations for the WebAssembly platform.
class WebFactory {
  /// Creates a license storage implementation for WebAssembly platform
  ///
  /// Parameters:
  /// - [storageKey]: The key used to store license data in localStorage
  ///
  /// Returns a [WebLicenseStorage] instance configured for WebAssembly platform
  static WebLicenseStorage createStorage({required String storageKey}) {
    // Create WebAssembly-specific interop
    final jsInterop = wasm_interop.JsInterop();

    // Create and return web storage with WebAssembly-specific interop
    return WebLicenseStorage(storageKey: storageKey, jsInterop: jsInterop);
  }
}
