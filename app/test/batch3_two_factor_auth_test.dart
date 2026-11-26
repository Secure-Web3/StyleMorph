import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/totp_helper.dart';
import 'package:stylemorph/core/services/two_factor_service.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_provider.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_screen.dart';
import 'package:stylemorph/features/auth/presentation/widgets/two_factor_verify_screen.dart';
import 'package:stylemorph/features/profile/presentation/widgets/two_factor_setup_dialog.dart';

class _FakeEmailOtpDispatcher implements EmailOtpDispatcher {
  String? lastCode;
  String? lastEmail;

  @override
  Future<bool> dispatchOtp({
    required String uid,
    required String email,
    required String code,
  }) async {
    lastCode = code;
    lastEmail = email;
    return true;
  }
}

class _FakeEmailVerificationNotifier extends EmailVerificationNotifier {
  _FakeEmailVerificationNotifier(super.ref, EmailVerificationState initial) {
    state = initial;
  }
}

Widget _wrapWithApp(
  Widget child, {
  TwoFactorService? twoFactorService,
  bool isEmailVerified = true,
}) {
  return ProviderScope(
    overrides: [
      if (twoFactorService != null)
        twoFactorServiceProvider.overrideWithValue(twoFactorService),
      emailVerifiedOverrideProvider.overrideWith((ref) => isEmailVerified),
      emailVerificationProvider.overrideWith(
        (ref) => _FakeEmailVerificationNotifier(
          ref,
          EmailVerificationState(isVerified: isEmailVerified),
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      theme: AppTheme.buildTheme(
        palette: AppPalette.white,
        isDark: false,
        localeCode: 'en',
      ),
      builder: (context, inner) => ShadTheme(
        data: AppTheme.buildShadTheme(palette: AppPalette.white, isDark: false),
        child: inner ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 3 - TotpHelper (RFC 6238 & Base32)', () {
    // Standard RFC 6238 SHA-1 test secret ("12345678901234567890" in Base32)
    const rfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    test('matches RFC 6238 SHA-1 test vector at T=59s (counter 1)', () {
      final ts = DateTime.fromMillisecondsSinceEpoch(59 * 1000, isUtc: true);
      final code = TotpHelper.generateCode(rfcSecret, timestamp: ts);
      // RFC 6238 8-digit vector is 94287082 -> 6-digit modulo is 287082
      expect(code, '287082');
      expect(TotpHelper.verifyCode(rfcSecret, '287082', timestamp: ts), isTrue);
    });

    test(
      'verifies ±1 time-step window drift and rejects distant/invalid codes',
      () {
        final t0 = DateTime.fromMillisecondsSinceEpoch(
          1700000010 * 1000,
          isUtc: true,
        );
        final prevCode = TotpHelper.generateCode(
          rfcSecret,
          timestamp: t0.subtract(const Duration(seconds: 30)),
        );
        final nextCode = TotpHelper.generateCode(
          rfcSecret,
          timestamp: t0.add(const Duration(seconds: 30)),
        );
        final staleCode = TotpHelper.generateCode(
          rfcSecret,
          timestamp: t0.subtract(const Duration(seconds: 90)),
        );

        expect(
          TotpHelper.verifyCode(rfcSecret, prevCode, timestamp: t0),
          isTrue,
        );
        expect(
          TotpHelper.verifyCode(rfcSecret, nextCode, timestamp: t0),
          isTrue,
        );
        expect(
          TotpHelper.verifyCode(rfcSecret, staleCode, timestamp: t0),
          isFalse,
        );
        expect(
          TotpHelper.verifyCode(rfcSecret, '12345', timestamp: t0),
          isFalse,
        );
      },
    );

    test('generates valid Base32 secret and otpauth:// URI', () {
      final secret = TotpHelper.generateSecret();
      expect(secret.length, 32);
      expect(RegExp(r'^[A-Z2-7]+$').hasMatch(secret), isTrue);

      final uri = TotpHelper.buildOtpAuthUri(
        accountLabel: 'mina@stylemorph.style',
        secret: secret,
      );
      expect(uri, startsWith('otpauth://totp/'));
      expect(uri, contains('secret=$secret'));
      expect(uri, contains('issuer=StyleMorph'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
    });
  });

  group('Batch 3 - TwoFactorService', () {
    test(
      'enrollTotp rejects invalid code and accepts valid TOTP code',
      () async {
        final service = TwoFactorService();
        final secret = TotpHelper.generateSecret();
        final validCode = TotpHelper.generateCode(secret);

        expect(
          await service.enrollTotp(uid: 'u1', secret: secret, code: '000000'),
          isFalse,
        );
        expect(
          await service.enrollTotp(uid: 'u1', secret: secret, code: validCode),
          isTrue,
        );
      },
    );

    test(
      'Email OTP respects 60s cooldown, 5-min TTL expiry, and single-use verification',
      () async {
        var now = DateTime.utc(2026, 11, 26, 12, 0, 0);
        final dispatcher = _FakeEmailOtpDispatcher();
        final service = TwoFactorService(
          emailDispatcher: dispatcher,
          nowProvider: () => now,
        );

        final first = await service.requestEmailOtp(
          uid: 'u1',
          email: 'mina@stylemorph.style',
        );
        expect(first.sent, isTrue);
        expect(dispatcher.lastCode, isNotNull);
        final code = dispatcher.lastCode!;

        // Immediate resend hits 60s cooldown
        final tooSoon = await service.requestEmailOtp(
          uid: 'u1',
          email: 'mina@stylemorph.style',
        );
        expect(tooSoon.sent, isFalse);
        expect(tooSoon.cooldownRemainingSeconds, greaterThan(0));

        // Expired after 5m 1s
        now = now.add(const Duration(minutes: 5, seconds: 1));
        expect(service.verifyEmailOtp(uid: 'u1', code: code), isFalse);

        // Fresh request succeeds and is single-use
        final second = await service.requestEmailOtp(
          uid: 'u1',
          email: 'mina@stylemorph.style',
        );
        expect(second.sent, isTrue);
        final freshCode = dispatcher.lastCode!;
        expect(service.verifyEmailOtp(uid: 'u1', code: freshCode), isTrue);
        expect(service.verifyEmailOtp(uid: 'u1', code: freshCode), isFalse);
      },
    );

    test('disableTwoFactor clears pending OTPs cleanly', () async {
      final dispatcher = _FakeEmailOtpDispatcher();
      final service = TwoFactorService(emailDispatcher: dispatcher);

      await service.requestEmailOtp(uid: 'u1', email: 'mina@stylemorph.style');
      final code = dispatcher.lastCode!;
      await service.disableTwoFactor('u1');
      expect(service.verifyEmailOtp(uid: 'u1', code: code), isFalse);
    });

    test(
      'extractSixDigitOtp sanitizes spaces, hyphens, and Persian/Arabic digits',
      () {
        expect(TwoFactorService.extractSixDigitOtp('123 456'), '123456');
        expect(TwoFactorService.extractSixDigitOtp('۱۲۳-۴۵۶'), '123456');
        expect(TwoFactorService.extractSixDigitOtp('١٢٣ ٤٥٦'), '123456');
        expect(TwoFactorService.extractSixDigitOtp('Code: 987654'), '987654');
        expect(TwoFactorService.extractSixDigitOtp('12345'), isNull);
        expect(TwoFactorService.extractSixDigitOtp('1234567'), isNull);
        expect(TwoFactorService.extractSixDigitOtp('abcdef'), isNull);
        expect(TwoFactorService.extractSixDigitOtp(''), isNull);
      },
    );
  });

  group('Batch 3 - TwoFactorSetupDialog & TwoFactorVerifyScreen UI', () {
    testWidgets(
      'TwoFactorSetupDialog switches between Authenticator QR and Email OTP',
      (tester) async {
        const strings = AppStrings('en');
        const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

        await tester.pumpWidget(
          _wrapWithApp(
            const TwoFactorSetupDialog(
              currentConfig: TwoFactorConfig(),
              initialTotpSecret: secret,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially shows QR code and copyable Base32 key
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text(secret), findsOneWidget);

        // Switch to Email Verification Code
        await tester.tap(find.text(strings.twoFaMethodEmail));
        await tester.pumpAndSettle();

        expect(find.byType(QrImageView), findsNothing);
        expect(find.text(strings.twoFaSendEmailCodeBtn), findsOneWidget);
      },
    );

    testWidgets(
      'TwoFactorVerifyScreen verifies valid TOTP code and marks session verified',
      (tester) async {
        const strings = AppStrings('en');
        const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
        final validCode = TotpHelper.generateCode(secret);

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          _wrapWithApp(
            Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const TwoFactorVerifyScreen(
                  uid: 'u1',
                  email: 'mina@stylemorph.style',
                  config: TwoFactorConfig(
                    enabled: true,
                    method: TwoFactorMethod.totp,
                    totpSecret: secret,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(strings.twoFaLoginTitle), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, validCode);
        await tester.tap(find.text(strings.twoFaVerifyContinueBtn));
        await tester.pumpAndSettle();

        expect(capturedRef.read(twoFactorSessionVerifiedProvider), isTrue);
      },
    );

    testWidgets(
      'TwoFactorSetupDialog hides QR/Enable on active TOTP tab and shows Switch CTA on Email tab',
      (tester) async {
        const strings = AppStrings('en');
        const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

        await tester.pumpWidget(
          _wrapWithApp(
            const TwoFactorSetupDialog(
              currentConfig: TwoFactorConfig(
                enabled: true,
                method: TwoFactorMethod.totp,
                totpSecret: secret,
              ),
              initialTotpSecret: secret,
              uidOverride: 'u1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Active TOTP tab shows Active status card + Disable 2FA, hides QR/secret/Enable
        expect(find.text(strings.twoFaActiveCardTitle), findsOneWidget);
        expect(find.text(strings.twoFaDisableBtn), findsOneWidget);
        expect(find.byType(QrImageView), findsNothing);
        expect(find.text(secret), findsNothing);
        expect(find.text(strings.twoFaActivateBtn), findsNothing);

        // Switch to inactive Email tab -> hides Disable 2FA, shows Send Code
        await tester.tap(find.text(strings.twoFaMethodEmail));
        await tester.pumpAndSettle();

        expect(find.text(strings.twoFaDisableBtn), findsNothing);
        expect(find.text(strings.twoFaSendEmailCodeBtn), findsOneWidget);

        // Send email code -> shows Switch to Email Code CTA + auto-replacement note
        await tester.tap(find.text(strings.twoFaSendEmailCodeBtn));
        await tester.pumpAndSettle();

        expect(find.text(strings.twoFaSwitchToEmailBtn), findsOneWidget);
        expect(find.text(strings.twoFaSwitchAutoReplaceNote), findsOneWidget);
        expect(find.text(strings.twoFaDisableBtn), findsNothing);
      },
    );

    testWidgets(
      'TwoFactorSetupDialog hides Disable 2FA on inactive TOTP tab when Email is active',
      (tester) async {
        const strings = AppStrings('en');
        const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

        await tester.pumpWidget(
          _wrapWithApp(
            const TwoFactorSetupDialog(
              currentConfig: TwoFactorConfig(
                enabled: true,
                method: TwoFactorMethod.email,
              ),
              initialTotpSecret: secret,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Active Email tab shows Active status card + Disable 2FA
        expect(find.text(strings.twoFaActiveCardTitle), findsOneWidget);
        expect(find.text(strings.twoFaDisableBtn), findsOneWidget);

        // Switch to inactive TOTP tab -> hides Disable 2FA, shows Switch to Authenticator + note
        await tester.tap(find.text(strings.twoFaMethodTotp));
        await tester.pumpAndSettle();

        expect(find.text(strings.twoFaDisableBtn), findsNothing);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text(strings.twoFaSwitchToTotpBtn), findsOneWidget);
        expect(find.text(strings.twoFaSwitchAutoReplaceNote), findsOneWidget);
      },
    );

    testWidgets(
      'TwoFactorVerifyScreen shows Email Recovery fallback for verified TOTP users and verifies email OTP',
      (tester) async {
        const strings = AppStrings('en');
        const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
        final dispatcher = _FakeEmailOtpDispatcher();
        final service = TwoFactorService(emailDispatcher: dispatcher);

        late WidgetRef capturedRef;
        await tester.pumpWidget(
          _wrapWithApp(
            Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const TwoFactorVerifyScreen(
                  uid: 'u1',
                  email: 'mina@stylemorph.style',
                  config: TwoFactorConfig(
                    enabled: true,
                    method: TwoFactorMethod.totp,
                    totpSecret: secret,
                  ),
                );
              },
            ),
            twoFactorService: service,
            isEmailVerified: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(strings.twoFaLostAccessEmailBtn), findsOneWidget);

        // Switch to Email Recovery mode
        await tester.tap(find.text(strings.twoFaLostAccessEmailBtn));
        await tester.pumpAndSettle();

        expect(find.text(strings.twoFaRecoveryModeDesc), findsOneWidget);
        expect(find.text(strings.twoFaUseTotpInsteadBtn), findsOneWidget);
        expect(dispatcher.lastCode, isNotNull);

        await tester.enterText(
          find.byType(TextField).first,
          dispatcher.lastCode!,
        );
        await tester.tap(find.text(strings.twoFaVerifyContinueBtn));
        await tester.pumpAndSettle();

        expect(capturedRef.read(twoFactorSessionVerifiedProvider), isTrue);
      },
    );

    test(
      'Latin locales (en, tr) contain zero Persian ۲ numeral in 2FA strings',
      () {
        for (final locale in ['en', 'tr']) {
          final strings = AppStrings(locale);
          final values = [
            strings.twoFaTitle,
            strings.twoFaDesc,
            strings.twoFaChooseMethod,
            strings.twoFaActivateBtn,
            strings.twoFaDisableBtn,
            strings.twoFaVerifyEmailFirst,
            strings.twoFaActiveCardTitle,
            strings.twoFaActiveCardDesc,
            strings.twoFaSwitchAutoReplaceNote,
            strings.twoFaRecoverySuccessNotice,
          ];
          for (final v in values) {
            expect(
              v.contains('۲'),
              isFalse,
              reason: '$locale had Persian ۲: $v',
            );
          }
        }
      },
    );
  });
}
