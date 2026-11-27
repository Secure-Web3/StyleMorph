import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_storage_stub.dart'
    if (dart.library.io) 'session_storage_io.dart'
    if (dart.library.js_interop) 'session_storage_web.dart';

/// Service managing device biometric authentication and biometric app lock preference.
class BiometricService {
  static const String _biometricLockPrefsKey = 'biometric_lock_enabled';
  static const String screenLockChannelName =
      'com.stylemorph.stylemorph/screen_lock';
  static const MethodChannel _screenLockChannel = MethodChannel(
    screenLockChannelName,
  );
  static bool? _cachedEnabled;

  /// Synchronous in-memory cache of the biometric lock preference.
  /// Returns `null` until [isBiometricLockEnabled] or [setBiometricLockEnabled] runs.
  static bool? get cachedEnabled => _cachedEnabled;

  @visibleForTesting
  static void resetCacheForTest() => _cachedEnabled = null;

  final LocalAuthentication _auth;
  bool _isAuthenticating = false;

  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  /// Whether an OS biometric prompt is currently active.
  bool get isAuthenticating => _isAuthenticating;

  /// Alias for [isBiometricAvailable] to check device biometric/credential support.
  Future<bool> isAvailable() => isBiometricAvailable();

  /// Checks if biometrics or device credentials are supported on this device.
  /// Safely returns false on Web without throwing errors.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      var hasAvailableBiometrics = false;
      try {
        final available = await _auth.getAvailableBiometrics();
        hasAvailableBiometrics = available.isNotEmpty;
      } catch (e) {
        debugPrint('[BiometricService] getAvailableBiometrics notice: $e');
      }
      return isSupported || canCheck || hasAvailableBiometrics;
    } catch (e) {
      debugPrint('[BiometricService] isBiometricAvailable notice: $e');
      return false;
    }
  }

  /// Checks whether the user has toggled biometric app lock ON in settings.
  Future<bool> isBiometricLockEnabled() async {
    if (kIsWeb) {
      _cachedEnabled = false;
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_biometricLockPrefsKey)) {
        final enabled = prefs.getBool(_biometricLockPrefsKey) ?? false;
        _cachedEnabled = enabled;
        return enabled;
      }
      final legacyEnabled = await SessionLocalStorage.getBiometricLockEnabled();
      if (legacyEnabled) {
        await prefs.setBool(_biometricLockPrefsKey, true);
      }
      _cachedEnabled = legacyEnabled;
      return legacyEnabled;
    } catch (e) {
      debugPrint('[BiometricService] isBiometricLockEnabled notice: $e');
      final fallback = await SessionLocalStorage.getBiometricLockEnabled();
      _cachedEnabled = fallback;
      return fallback;
    }
  }

  /// Saves the user preference for biometric lock.
  Future<void> setBiometricLockEnabled(bool enabled) async {
    if (kIsWeb) return;
    _cachedEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricLockPrefsKey, enabled);
    } catch (e) {
      debugPrint('[BiometricService] setBiometricLockEnabled notice: $e');
    }
    await SessionLocalStorage.setBiometricLockEnabled(enabled);
  }

  /// Triggers biometric prompt (Face ID / Fingerprint / Passcode fallback).
  Future<bool> authenticate({required String localizedReason}) async {
    if (kIsWeb) return true;
    _isAuthenticating = true;
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (e) {
      debugPrint('[BiometricService] authenticate error: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Registers a native OS screen-lock listener (Android ACTION_SCREEN_OFF,
  /// iOS protectedDataWillBecomeUnavailable) and returns a cleanup callback.
  /// Safely no-ops on Web (`kIsWeb`).
  VoidCallback registerScreenLockListener(VoidCallback onScreenLocked) {
    if (kIsWeb) return () {};
    _screenLockChannel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenLocked') {
        onScreenLocked();
      }
    });
    return () {
      _screenLockChannel.setMethodCallHandler(null);
    };
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Watches the persistent biometric lock user preference.
final biometricLockEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.isBiometricLockEnabled();
});

/// Tracks whether the app has been unlocked via biometrics for the current runtime session.
final biometricUnlockedProvider = StateProvider<bool>((ref) => false);
