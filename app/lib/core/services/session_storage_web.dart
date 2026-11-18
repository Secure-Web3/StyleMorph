import 'dart:js_interop';

@JS('window.localStorage.getItem')
external JSString? _localStorageGetItem(JSString key);

@JS('window.localStorage.setItem')
external void _localStorageSetItem(JSString key, JSString value);

class SessionLocalStorage {
  static Future<String?> getSessionId() async {
    try {
      final val = _localStorageGetItem('sm_session_id'.toJS);
      return val?.toDart;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setSessionId(String id) async {
    try {
      _localStorageSetItem('sm_session_id'.toJS, id.toJS);
    } catch (_) {}
  }
}
