import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing session persistence configuration:
/// - On Web: Configures [FirebaseAuth.instance.setPersistence] to [Persistence.LOCAL]
///   (when rememberMe == true) or [Persistence.SESSION] (when rememberMe == false).
/// - On Mobile: Persists the `auth_remember_me` flag in local storage, and clears the session
///   upon app termination/restart if rememberMe was false.
class SessionPersistenceService {
  static const String keyRememberMe = 'auth_remember_me';

  final FirebaseAuth? _customAuth;

  SessionPersistenceService({FirebaseAuth? auth}) : _customAuth = auth;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Reads whether the user selected "Remember Me" (defaults to true).
  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyRememberMe) ?? true;
    } catch (e) {
      debugPrint('[SessionPersistenceService] getRememberMe error: $e');
      return true;
    }
  }

  /// Sets the "Remember Me" flag in local storage.
  Future<void> setRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyRememberMe, value);
    } catch (e) {
      debugPrint('[SessionPersistenceService] setRememberMe error: $e');
    }
  }

  /// Applies persistence settings across Web (Firebase Auth) and Mobile (local preference).
  Future<void> applyPersistence(bool rememberMe) async {
    await setRememberMe(rememberMe);

    if (kIsWeb) {
      try {
        if (Firebase.apps.isNotEmpty) {
          await _auth.setPersistence(
            rememberMe ? Persistence.LOCAL : Persistence.SESSION,
          );
        }
      } catch (e) {
        debugPrint('[SessionPersistenceService] setPersistence error: $e');
      }
    }
  }

  /// Verifies on startup whether a non-persistent session on mobile needs to be cleared.
  /// If the user did not check "Remember Me" on mobile, the session is terminated on app launch.
  Future<void> checkAndClearNonPersistentSessionOnStartup() async {
    if (kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) return;
      final rememberMe = await getRememberMe();
      if (!rememberMe) {
        if (_auth.currentUser != null) {
          debugPrint(
            '[SessionPersistenceService] Clearing non-persistent mobile session on app launch',
          );
          await _auth.signOut();
        }
      }
    } catch (e) {
      debugPrint(
        '[SessionPersistenceService] checkAndClearNonPersistentSessionOnStartup error: $e',
      );
    }
  }
}

final sessionPersistenceServiceProvider =
    Provider<SessionPersistenceService>((ref) {
  return SessionPersistenceService();
});
