class SessionLocalStorage {
  static Future<String?> getSessionId() async => null;
  static Future<void> setSessionId(String id) async {}

  static Future<String?> getDeviceId() async => null;
  static Future<void> setDeviceId(String id) async {}

  static String? getUserAgent() => null;

  static Future<bool> getBiometricLockEnabled() async => false;
  static Future<void> setBiometricLockEnabled(bool enabled) async {}
}
