import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/services/screenshot_protection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScreenshotProtectionService Tests', () {
    late ScreenshotProtectionService service;

    setUp(() {
      service = ScreenshotProtectionService();
      service.disableProtection();
    });

    tearDown(() {
      service.disableProtection();
    });

    test('is a singleton instance', () {
      final s1 = ScreenshotProtectionService();
      final s2 = ScreenshotProtectionService();
      expect(identical(s1, s2), isTrue);
    });

    test('starts with protection disabled', () {
      expect(service.isProtectionEnabled, isFalse);
    });

    test('respects kEnableScreenshotProtection flag on enableProtection', () {
      service.enableProtection();
      expect(
        service.isProtectionEnabled,
        ScreenshotProtectionService.kEnableScreenshotProtection,
      );

      // Calling again should not throw and remain consistent with the flag
      service.enableProtection();
      expect(
        service.isProtectionEnabled,
        ScreenshotProtectionService.kEnableScreenshotProtection,
      );
    });

    test('disables protection correctly', () {
      service.enableProtection();
      expect(
        service.isProtectionEnabled,
        ScreenshotProtectionService.kEnableScreenshotProtection,
      );

      service.disableProtection();
      expect(service.isProtectionEnabled, isFalse);

      // Calling again should not throw and remain disabled
      service.disableProtection();
      expect(service.isProtectionEnabled, isFalse);
    });

    test('provided via Riverpod provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedService = container.read(
        screenshotProtectionServiceProvider,
      );
      expect(providedService, isNotNull);
      expect(identical(providedService, service), isTrue);
    });
  });
}
