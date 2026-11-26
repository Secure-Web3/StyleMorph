import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screenshot_protection_stub.dart'
    if (dart.library.js_interop) 'screenshot_protection_web.dart'
    as web_guards;

/// Centralized Screenshot Protection Service for StyleMorph.
/// - Android: Protected at the OS window level via `FLAG_SECURE` in MainActivity.
/// - Web: Intercepts `PrintScreen`, `Ctrl+P`, `Meta+P`, and injects `@media print` blockers.
/// - iOS / Desktop: Safe stubs with lifecycle observer support.
class ScreenshotProtectionService with WidgetsBindingObserver {
  /// Temporarily disabled for QA screenshots; flip to `true` for production release.
  static const bool kEnableScreenshotProtection = false;

  static const MethodChannel _channel = MethodChannel(
    'com.stylemorph.stylemorph/screenshot_protection',
  );

  static final ScreenshotProtectionService _instance =
      ScreenshotProtectionService._internal();

  factory ScreenshotProtectionService() => _instance;

  ScreenshotProtectionService._internal();

  bool _isProtectionEnabled = false;
  bool get isProtectionEnabled => _isProtectionEnabled;

  /// Enables screenshot & screen-capture protection app-wide when
  /// [kEnableScreenshotProtection] is `true`; otherwise ensures it is cleared.
  void enableProtection() {
    if (!kEnableScreenshotProtection) {
      _syncNativeSecureFlag(false);
      disableProtection();
      return;
    }
    if (_isProtectionEnabled) return;
    _isProtectionEnabled = true;

    try {
      if (kIsWeb) {
        web_guards.setupWebScreenshotGuards();
      } else {
        _syncNativeSecureFlag(true);
      }
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      debugPrint('[ScreenshotProtectionService] enableProtection notice: $e');
    }
  }

  /// Disables screenshot protection if explicitly allowed.
  void disableProtection() {
    _syncNativeSecureFlag(false);
    if (!_isProtectionEnabled) return;
    _isProtectionEnabled = false;

    try {
      if (kIsWeb) {
        web_guards.tearDownWebScreenshotGuards();
      }
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      debugPrint('[ScreenshotProtectionService] disableProtection notice: $e');
    }
  }

  Future<void> _syncNativeSecureFlag(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecureFlag', {'enabled': enabled});
    } catch (e) {
      debugPrint('[ScreenshotProtectionService] native flag sync notice: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lifecycle hooks for mobile/desktop app switcher protection
  }
}

/// Riverpod provider for [ScreenshotProtectionService].
final screenshotProtectionServiceProvider =
    Provider<ScreenshotProtectionService>((ref) {
      return ScreenshotProtectionService();
    });
