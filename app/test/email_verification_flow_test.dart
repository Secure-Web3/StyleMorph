import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/email_verification_gate.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_provider.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_screen.dart';
import 'package:stylemorph/features/profile/presentation/widgets/email_verification_banner.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  group('Soft-Gate Email Verification Tests', () {
    test('EmailVerificationState copyWith correctly modifies fields', () {
      const state = EmailVerificationState(
        isVerified: false,
        isChecking: false,
        isResending: false,
        cooldownSeconds: 0,
      );

      final updated = state.copyWith(isVerified: true, cooldownSeconds: 45);

      expect(updated.isVerified, isTrue);
      expect(updated.cooldownSeconds, 45);
      expect(updated.isChecking, isFalse);
    });

    testWidgets('EmailVerificationBanner displays when unverified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emailVerificationProvider.overrideWith(
              (ref) => EmailVerificationNotifier(ref)
                ..state = const EmailVerificationState(
                  isVerified: false,
                  cooldownSeconds: 0,
                ),
            ),
          ],
          child: MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fa')],
            locale: const Locale('fa'),
            home: const Scaffold(body: EmailVerificationBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('fa');
      // Should find banner title and both action buttons
      expect(find.text(strings.emailVerificationBannerTitle), findsOneWidget);
      expect(find.text(strings.authEmailResendBtn), findsOneWidget);
      expect(find.text(strings.authEmailCheckBtn), findsOneWidget);
    });

    testWidgets('EmailVerificationBanner hides when verified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emailVerifiedOverrideProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: testTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fa')],
            locale: const Locale('fa'),
            home: const Scaffold(body: EmailVerificationBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppStrings('fa');
      // Banner should be hidden (SizedBox.shrink)
      expect(find.text(strings.emailVerificationBannerTitle), findsNothing);
    });

    testWidgets(
      'Soft-gate prompt opens when checking email verification gate while unverified',
      (WidgetTester tester) async {
        late BuildContext capturedContext;
        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              emailVerificationProvider.overrideWith(
                (ref) => EmailVerificationNotifier(ref)
                  ..state = const EmailVerificationState(
                    isVerified: false,
                    cooldownSeconds: 0,
                  ),
              ),
            ],
            child: MaterialApp(
              theme: testTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('fa')],
              locale: const Locale('fa'),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    capturedContext = context;
                    capturedRef = ref;
                    return const Text('Test Screen');
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Calling checkEmailVerificationGate with isVerified = false triggers soft gate modal
        final allowed = checkEmailVerificationGate(
          capturedContext,
          capturedRef,
        );
        expect(allowed, isFalse);

        await tester.pumpAndSettle();

        final strings = AppStrings('fa');
        // The soft-gate dialog is shown
        expect(
          find.text(strings.emailVerificationSoftGateTitle),
          findsOneWidget,
        );
        expect(find.text(strings.emailVerificationGoToProfile), findsOneWidget);
        expect(find.text(strings.authEmailCheckBtn), findsOneWidget);
      },
    );
  });
}
