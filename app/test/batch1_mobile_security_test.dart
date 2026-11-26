import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/services/app_check_service.dart';
import 'package:stylemorph/core/services/biometric_service.dart';
import 'package:stylemorph/core/services/screenshot_protection_service.dart';

class _FakeLocalAuth extends LocalAuthentication {
  final bool supported;
  final bool canCheck;
  final List<BiometricType> biometrics;
  final bool authResult;
  final bool throwOnCheck;

  _FakeLocalAuth({
    this.supported = true,
    this.canCheck = true,
    this.biometrics = const [BiometricType.fingerprint],
    this.authResult = true,
    this.throwOnCheck = false,
  });

  @override
  Future<bool> isDeviceSupported() async {
    if (throwOnCheck) throw PlatformException(code: 'unavailable');
    return supported;
  }

  @override
  Future<bool> get canCheckBiometrics async {
    if (throwOnCheck) throw PlatformException(code: 'unavailable');
    return canCheck;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (throwOnCheck) throw PlatformException(code: 'unavailable');
    return biometrics;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object?> authMessages = const <Never>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    return authResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 1 - Screenshot Protection QA Toggle', () {
    test('kEnableScreenshotProtection is temporarily disabled for QA', () {
      expect(ScreenshotProtectionService.kEnableScreenshotProtection, isFalse);
    });

    test('enableProtection remains disabled when QA toggle is false', () {
      final service = ScreenshotProtectionService();
      service.disableProtection();
      service.enableProtection();
      expect(service.isProtectionEnabled, isFalse);
    });
  });

  group('Batch 1 - BiometricService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'isBiometricAvailable returns true when device supports biometrics',
      () async {
        final service = BiometricService(auth: _FakeLocalAuth());
        final available = await service.isBiometricAvailable();
        expect(available, isTrue);
      },
    );

    test('isBiometricAvailable returns false when unsupported', () async {
      final service = BiometricService(
        auth: _FakeLocalAuth(
          supported: false,
          canCheck: false,
          biometrics: const [],
        ),
      );
      final available = await service.isBiometricAvailable();
      expect(available, isFalse);
    });

    test(
      'isBiometricAvailable returns false safely on platform exception',
      () async {
        final service = BiometricService(
          auth: _FakeLocalAuth(throwOnCheck: true),
        );
        final available = await service.isBiometricAvailable();
        expect(available, isFalse);
      },
    );

    test('persists biometric lock preference in SharedPreferences', () async {
      final service = BiometricService(auth: _FakeLocalAuth());
      expect(await service.isBiometricLockEnabled(), isFalse);

      await service.setBiometricLockEnabled(true);
      expect(await service.isBiometricLockEnabled(), isTrue);

      await service.setBiometricLockEnabled(false);
      expect(await service.isBiometricLockEnabled(), isFalse);
    });

    test('authenticate returns result from LocalAuthentication', () async {
      final successService = BiometricService(
        auth: _FakeLocalAuth(authResult: true),
      );
      expect(
        await successService.authenticate(localizedReason: 'Verify identity'),
        isTrue,
      );

      final failService = BiometricService(
        auth: _FakeLocalAuth(authResult: false),
      );
      expect(
        await failService.authenticate(localizedReason: 'Verify identity'),
        isFalse,
      );
    });
  });

  group('Batch 1 - AppCheckService', () {
    setUp(() {
      AppCheckService.resetForTesting();
    });

    test(
      'is a safe no-op on Web without activating native providers',
      () async {
        var called = false;
        await AppCheckService.initialize(
          isWebOverride: true,
          activator:
              ({required providerAndroid, required providerApple}) async {
                called = true;
              },
        );
        expect(called, isFalse);
        expect(AppCheckService.isInitialized, isFalse);
      },
    );

    test('activates debug providers on mobile in debug mode', () async {
      AndroidAppCheckProvider? capturedAndroid;
      AppleAppCheckProvider? capturedApple;
      var autoRefreshEnabled = false;

      await AppCheckService.initialize(
        isWebOverride: false,
        isDebugOverride: true,
        activator: ({required providerAndroid, required providerApple}) async {
          capturedAndroid = providerAndroid;
          capturedApple = providerApple;
        },
        autoRefreshSetter: (enabled) async {
          autoRefreshEnabled = enabled;
        },
      );

      expect(capturedAndroid, isA<AndroidDebugProvider>());
      expect(capturedApple, isA<AppleDebugProvider>());
      expect(autoRefreshEnabled, isTrue);
      expect(AppCheckService.isInitialized, isTrue);
    });

    test('activates Play Integrity and App Attest in release mode', () async {
      AndroidAppCheckProvider? capturedAndroid;
      AppleAppCheckProvider? capturedApple;

      await AppCheckService.initialize(
        isWebOverride: false,
        isDebugOverride: false,
        activator: ({required providerAndroid, required providerApple}) async {
          capturedAndroid = providerAndroid;
          capturedApple = providerApple;
        },
        autoRefreshSetter: (_) async {},
      );

      expect(capturedAndroid, isA<AndroidPlayIntegrityProvider>());
      expect(capturedApple, isA<AppleAppAttestProvider>());
      expect(AppCheckService.isInitialized, isTrue);
    });

    test('never throws when activation fails (fail-safe startup)', () async {
      await AppCheckService.initialize(
        isWebOverride: false,
        activator: ({required providerAndroid, required providerApple}) async {
          throw Exception('Play Services unavailable');
        },
      );
      expect(AppCheckService.isInitialized, isFalse);
    });
  });
}
