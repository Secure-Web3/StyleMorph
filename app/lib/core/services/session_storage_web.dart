import 'package:web/web.dart' as web;

class SessionLocalStorage {
  static Future<String?> getSessionId() async {
    try {
      return web.window.localStorage.getItem('sm_session_id');
    } catch (_) {
      return null;
    }
  }

  static Future<void> setSessionId(String id) async {
    try {
      web.window.localStorage.setItem('sm_session_id', id);
    } catch (_) {}
  }

  static Future<String?> getDeviceId() async {
    try {
      return web.window.localStorage.getItem('sm_device_id');
    } catch (_) {
      return null;
    }
  }

  static Future<void> setDeviceId(String id) async {
    try {
      web.window.localStorage.setItem('sm_device_id', id);
    } catch (_) {}
  }

  static String? getUserAgent() {
    try {
      return web.window.navigator.userAgent;
    } catch (_) {
      return null;
    }
  }
}
