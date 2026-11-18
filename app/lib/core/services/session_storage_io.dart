import 'dart:io';

class SessionLocalStorage {
  static File _getFile(String filename) {
    return File('${Directory.systemTemp.path}/$filename');
  }

  static Future<String?> getSessionId() async {
    try {
      final file = _getFile('.sm_session_id');
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isNotEmpty) return content;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> setSessionId(String id) async {
    try {
      final file = _getFile('.sm_session_id');
      await file.writeAsString(id);
    } catch (_) {}
  }

  static Future<String?> getDeviceId() async {
    try {
      final file = _getFile('.sm_device_id');
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isNotEmpty) return content;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> setDeviceId(String id) async {
    try {
      final file = _getFile('.sm_device_id');
      await file.writeAsString(id);
    } catch (_) {}
  }

  static String? getUserAgent() {
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> getBiometricLockEnabled() async {
    try {
      final file = _getFile('.sm_biometric_lock');
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        return content == 'true';
      }
    } catch (_) {}
    return false;
  }

  static Future<void> setBiometricLockEnabled(bool enabled) async {
    try {
      final file = _getFile('.sm_biometric_lock');
      await file.writeAsString(enabled ? 'true' : 'false');
    } catch (_) {}
  }
}
