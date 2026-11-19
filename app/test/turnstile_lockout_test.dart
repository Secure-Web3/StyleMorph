import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_button.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/auth/presentation/widgets/turnstile_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  group('Turnstile & Brute-Force Lockout Cooldown Tests', () {
    test('Cloudflare Turnstile production site key matches requirement', () {
      expect(kTurnstileSiteKey, equals('0x4AAAAAAGILAS7YQZalDE3k'));
    });

    test('TurnstileController reset executes without throwing', () {
      final controller = TurnstileController();
      expect(() => controller.reset(), returnsNormally);
    });

    test('AppStrings formats authLockoutCooldown and authLockoutBtn for all locales', () {
      // English
      final en = AppStrings('en');
      expect(en.authLockoutCooldown(30), contains('30'));
      expect(en.authLockoutBtn(30), contains('30'));

      // Persian
      final fa = AppStrings('fa');
      expect(fa.authLockoutCooldown(30), contains('۳۰'));
      expect(fa.authLockoutBtn(30), contains('۳۰'));

      // Arabic uses Eastern Arabic numerals (\u0663\u0660)
      final ar = AppStrings('ar');
      expect(ar.authLockoutCooldown(30), contains('٣٠'));
      expect(ar.authLockoutBtn(30), contains('٣٠'));

      // Turkish
      final tr = AppStrings('tr');
      expect(tr.authLockoutCooldown(30), contains('30'));
      expect(tr.authLockoutBtn(30), contains('30'));
    });

    testWidgets('AuthScreen renders login form with button enabled on non-web platform',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(
              body: AuthScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find primary login button
      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsWidgets);

      final loginBtn = tester.widget<AppButton>(buttonFinder.first);
      // On non-web (mobile/desktop test runner), Turnstile is bypassed so onPressed is enabled
      expect(loginBtn.onPressed, isNotNull);
    });
  });
}
