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
  dynamic get window => _getGlobalThis();

  /// Creates a new instance of JsInterop
  JsInterop();
}

/// External JS function to get the global object
@JS('globalThis')
external Object _getGlobalThis();
