// SPDX-FileCopyrightText: 2025 Karim "nogipx" Mamatkazin <nogipx@gmail.com>
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import 'dart:js_interop';

/// WebAssembly implementation for js_interop
///
/// This provides browser APIs access through dart:js_interop
/// for WebAssembly platform.
class JsInterop {
  /// Access to the window object in browser
  JSObject get window => globalThis;

  /// Creates a new instance of JsInterop
  JsInterop();
}

/// Reference to the globalThis object in JS
@JS()
external JSObject get globalThis;

/// Extension for localStorage methods
extension StorageExtension on JSObject {
  /// Gets the localStorage object from window
  @JS('localStorage')
  external JSStorage get localStorage;
}

/// JavaScript Storage interface for localStorage
@JS()
class JSStorage {
  /// Default constructor
  external JSStorage();

  /// Gets an item from storage
  @JS('getItem')
  external JSString? getItem(JSString key);

  /// Sets an item in storage
  @JS('setItem')
  external void setItem(JSString key, JSString value);

  /// Removes an item from storage
  @JS('removeItem')
  external void removeItem(JSString key);
}
