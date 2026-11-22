import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

web.EventListener? _keyListener;
web.HTMLStyleElement? _printStyleElement;

/// Installs web listeners and print protection styles.
void setupWebScreenshotGuards() {
  try {
    // 1. Inject print-blocking CSS to prevent Print / Save as PDF
    if (_printStyleElement == null) {
      final style = web.document.createElement('style') as web.HTMLStyleElement;
      style.textContent = '''
@media print {
  body {
    display: none !important;
    visibility: hidden !important;
  }
}
''';
      web.document.head?.appendChild(style);
      _printStyleElement = style;
    }

    // 2. Keyboard listener for PrintScreen, Ctrl+P, Meta+P, and screenshot shortcuts
    if (_keyListener == null) {
      _keyListener = ((web.Event event) {
        if (event.isA<web.KeyboardEvent>()) {
          final kEvent = event as web.KeyboardEvent;
          final key = kEvent.key;
          final code = kEvent.code;
          final isPrintScreen = key == 'PrintScreen' || code == 'PrintScreen';
          final isPrintShortcut =
              (key.toLowerCase() == 'p') && (kEvent.ctrlKey || kEvent.metaKey);
          final isScreenshotShortcut =
              (kEvent.ctrlKey || kEvent.metaKey) &&
              kEvent.shiftKey &&
              (key.toLowerCase() == 's' || key == '3' || key == '4');

          if (isPrintScreen || isPrintShortcut || isScreenshotShortcut) {
            kEvent.preventDefault();
            kEvent.stopPropagation();
            debugPrint(
              '[ScreenshotProtection] Screenshot/Print shortcut blocked on Web.',
            );
          }
        }
      }).toJS;

      web.window.addEventListener('keydown', _keyListener);
    }
  } catch (e) {
    debugPrint('[ScreenshotProtectionWeb] setup error: $e');
  }
}

/// Removes web listeners and print protection styles.
void tearDownWebScreenshotGuards() {
  try {
    if (_keyListener != null) {
      web.window.removeEventListener('keydown', _keyListener);
      _keyListener = null;
    }
    if (_printStyleElement != null) {
      _printStyleElement?.remove();
      _printStyleElement = null;
    }
  } catch (e) {
    debugPrint('[ScreenshotProtectionWeb] tearDown error: $e');
  }
}
