import 'dart:js_interop';
import 'package:web/web.dart' as web;

web.EventListener? _beforeUnloadListener;

void updateWebUnloadGuard(bool hasUnsavedChanges) {
  if (hasUnsavedChanges) {
    if (_beforeUnloadListener == null) {
      _beforeUnloadListener = ((web.Event event) {
        event.preventDefault();
        try {
          if (event.isA<web.BeforeUnloadEvent>()) {
            (event as web.BeforeUnloadEvent).returnValue = '';
          }
        } catch (_) {}
      }).toJS;
      web.window.addEventListener('beforeunload', _beforeUnloadListener!);
    }
  } else {
    if (_beforeUnloadListener != null) {
      web.window.removeEventListener('beforeunload', _beforeUnloadListener!);
      _beforeUnloadListener = null;
    }
  }
}
