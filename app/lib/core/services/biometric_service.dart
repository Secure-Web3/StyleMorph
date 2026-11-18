import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'session_storage_stub.dart'
    if (dart.library.io) 'session_storage_io.dart'
    if (dart.library.js_interop) 'session_storage_web.dart';

/// Service managing device biometric authentication and biometric app lock preference.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if biometrics (Fingerprint / Face ID) are supported and enrolled on this device.
  /// Safely returns false on Web without throwing errors.
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('[BiometricService] isBiometricAvailable notice: $e');
      return false;
    }
  }

  /// Checks whether the user has toggled biometric app lock ON in settings.
  Future<bool> isBiometricLockEnabled() async {
    if (kIsWeb) return false;
    return await SessionLocalStorage.getBiometricLockEnabled();
  }

  /// Saves the user preference for biometric lock.
  Future<void> setBiometricLockEnabled(bool enabled) async {
    await SessionLocalStorage.setBiometricLockEnabled(enabled);
  }

  /// Triggers biometric prompt (Face ID / Fingerprint / Passcode fallback).
  Future<bool> authenticate({required String localizedReason}) async {
    if (kIsWeb) return true;
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (e) {
      debugPrint('[BiometricService] authenticate error: $e');
      return false;
    }
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
