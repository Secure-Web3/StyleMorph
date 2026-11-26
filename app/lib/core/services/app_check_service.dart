import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Callback signature for activating Firebase App Check (injectable for testing).
typedef AppCheckActivator =
    Future<void> Function({
      required AndroidAppCheckProvider providerAndroid,
      required AppleAppCheckProvider providerApple,
    });

/// Callback signature for enabling App Check token auto-refresh.
typedef AppCheckAutoRefreshSetter = Future<void> Function(bool enabled);

/// Native-mobile-only Firebase App Check initializer.
///
/// Web continues using Cloudflare Turnstile + Math Fallback untouched.
class AppCheckService {
  AppCheckService._();

  static bool _isInitialized = false;

  /// Whether [initialize] has completed on a non-Web platform.
  static bool get isInitialized => _isInitialized;

  /// Resets initialization state (for unit tests only).
  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
  }

  /// Activates Firebase App Check on Android (Play Integrity / Debug) and
  /// iOS (App Attest / Debug) inside a non-blocking try/catch.
  ///
  /// On Web (`kIsWeb`), this is a safe no-op.
  static Future<void> initialize({
    bool? isWebOverride,
    bool? isDebugOverride,
    AppCheckActivator? activator,
    AppCheckAutoRefreshSetter? autoRefreshSetter,
  }) async {
    final runningOnWeb = isWebOverride ?? kIsWeb;
    if (runningOnWeb) return;

    final useDebugProvider = isDebugOverride ?? kDebugMode;
    final androidProvider = useDebugProvider
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider();
    final appleProvider = useDebugProvider
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider();

    try {
      if (activator != null) {
        await activator(
          providerAndroid: androidProvider,
          providerApple: appleProvider,
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: androidProvider,
          providerApple: appleProvider,
        );
      }

      if (autoRefreshSetter != null) {
        await autoRefreshSetter(true);
      } else {
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[AppCheckService] Initialization notice: $e');
    }
  }
}
