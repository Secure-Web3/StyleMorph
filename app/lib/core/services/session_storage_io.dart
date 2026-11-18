import 'dart:io';

class SessionLocalStorage {
  static File _getFile() {
    return File('${Directory.systemTemp.path}/.sm_session_id');
  }

  static Future<String?> getSessionId() async {
    try {
      final file = _getFile();
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isNotEmpty) return content;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> setSessionId(String id) async {
    try {
      final file = _getFile();
      await file.writeAsString(id);
    } catch (_) {}
  }
}
