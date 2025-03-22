// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'package:licensify/src/license/data/datasources/web/interop/js_interop.dart'
    as wasm_interop;
import 'package:licensify/src/license/data/datasources/web/storage/web_license_storage.dart';

/// Factory for creating web storage instances
///
/// This class provides a consistent way to create license storage implementations
/// for WebAssembly platform.
class WebStorageFactory {
  /// Creates a license storage implementation for WebAssembly platform
  ///
  /// Parameters:
  /// - [storageKey]: The key used to store license data in localStorage
  ///
  /// Returns a [WebLicenseStorage] instance configured for WebAssembly
  static WebLicenseStorage createStorage({required String storageKey}) {
    // Create WASM-specific JS interop
    final jsInterop = wasm_interop.JsInterop();

    // Create and return web storage with WASM interop
    return WebLicenseStorage(storageKey: storageKey, jsInterop: jsInterop);
  }
}
