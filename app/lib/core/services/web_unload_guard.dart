import 'package:flutter/foundation.dart';
import 'web_unload_guard_stub.dart'
    if (dart.library.js_interop) 'web_unload_guard_web.dart'
    as web_guard;

/// Cross-platform Web unload guard.
/// On Web, prevents accidental tab close or page reload when there are unsaved changes.
/// On Mobile and Desktop, acts as a safe no-op.
class WebUnloadGuard {
  WebUnloadGuard._();

  static void update(bool hasUnsavedChanges) {
    if (kIsWeb) {
      try {
        web_guard.updateWebUnloadGuard(hasUnsavedChanges);
      } catch (e) {
        debugPrint('[WebUnloadGuard] update error: $e');
      }
    }
  }
}
