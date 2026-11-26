import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/notification_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/email_verification_gate.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_provider.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_screen.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/kyc_verification_section.dart';
import 'package:stylemorph/features/stylist/presentation/widgets/stylist_chat_sheet.dart';

class _RecordingNotificationService extends NotificationService {
  int emailVerificationNotifCalls = 0;
  String? lastUid;
  String? lastEmail;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> createEmailVerificationNotification({
    required String uid,
    required String email,
    required String title,
    required String body,
  }) async {
    emailVerificationNotifCalls++;
    lastUid = uid;
    lastEmail = email;
    lastTitle = title;
    lastBody = body;
  }
}

class _FakeEmailVerificationNotifier extends EmailVerificationNotifier {
  _FakeEmailVerificationNotifier(super.ref, EmailVerificationState initial) {
    state = initial;
  }
}

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }
}

Widget _wrapWithApp(
  Widget child, {
  required EmailVerificationState verificationState,
  String localeCode = 'en',
  bool advancedMode = false,
}) {
  return ProviderScope(
    overrides: [
      emailVerifiedOverrideProvider.overrideWith(
        (ref) => verificationState.isVerified,
      ),
      emailVerificationProvider.overrideWith(
        (ref) => _FakeEmailVerificationNotifier(ref, verificationState),
      ),
      if (advancedMode)
        appStateProvider.overrideWith(
          (ref) => _TestAppStateNotifier(
            const AppState(preferences: UserPreferences(appMode: 'advanced')),
          ),
        ),
    ],
    child: MaterialApp(
      locale: Locale(localeCode),
      theme: AppTheme.buildTheme(
        palette: AppPalette.white,
        isDark: false,
        localeCode: localeCode,
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

  group('Batch 2 - Notification & Localization Policy', () {
    test(
      'createEmailVerificationNotification records uid, email, and Spam/Junk reminder',
      () async {
        final service = _RecordingNotificationService();
        final strings = const AppStrings('en');

        await service.createEmailVerificationNotification(
          uid: 'user_123',
          email: 'mina@example.com',
          title: strings.notifEmailVerifyTitle,
          body: strings.notifEmailVerifyBody('mina@example.com'),
        );

        expect(service.emailVerificationNotifCalls, 1);
        expect(service.lastUid, 'user_123');
        expect(service.lastEmail, 'mina@example.com');
        expect(service.lastBody, contains('mina@example.com'));
        expect(service.lastBody, contains('Spam/Junk'));
        expect(
          NotificationService.eventEmailVerification,
          'email_verification',
        );
      },
    );

    test(
      'all 4 locales provide verification notification & KYC lock strings',
      () {
        for (final code in const ['fa', 'en', 'ar', 'tr']) {
          final s = AppStrings(code);
          expect(s.notifEmailVerifyTitle, isNotEmpty);
          expect(s.notifEmailVerifyBody('a@b.com'), contains('a@b.com'));
          expect(s.kycEmailVerificationRequiredHint, isNotEmpty);
        }
      },
    );
  });

  group('Batch 2 - EmailVerificationGate', () {
    testWidgets(
      'blocks unverified user and shows Resend, Check, and Go to Profile actions',
      (tester) async {
        bool? gateResult;
        const strings = AppStrings('en');

        await tester.pumpWidget(
          _wrapWithApp(
            Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () {
                  gateResult = EmailVerificationGate.checkVerified(
                    context,
                    ref,
                  );
                },
                child: const Text('Trigger'),
              ),
            ),
            verificationState: const EmailVerificationState(isVerified: false),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(gateResult, isFalse);
        expect(
          find.text(strings.emailVerificationSoftGateTitle),
          findsOneWidget,
        );
        expect(find.text(strings.emailVerificationGoToProfile), findsOneWidget);
        expect(find.text(strings.authEmailResendBtn), findsOneWidget);
        expect(find.text(strings.authEmailCheckBtn), findsOneWidget);
      },
    );

    testWidgets('allows verified user without showing modal', (tester) async {
      bool? gateResult;
      const strings = AppStrings('en');

      await tester.pumpWidget(
        _wrapWithApp(
          Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () {
                gateResult = EmailVerificationGate.checkVerified(context, ref);
              },
              child: const Text('Trigger'),
            ),
          ),
          verificationState: const EmailVerificationState(isVerified: true),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(gateResult, isTrue);
      expect(find.text(strings.emailVerificationSoftGateTitle), findsNothing);
    });
  });

  group('Batch 2 - Identity, KYC & Read-Only Module Gates', () {
    testWidgets(
      'KycVerificationSection shows email verification lock hint when unverified',
      (tester) async {
        const strings = AppStrings('en');

        await tester.pumpWidget(
          _wrapWithApp(
            const SingleChildScrollView(child: KycVerificationSection()),
            verificationState: const EmailVerificationState(isVerified: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(strings.kycEmailVerificationRequiredHint),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'KycVerificationSection hides email verification lock hint when verified',
      (tester) async {
        const strings = AppStrings('en');

        await tester.pumpWidget(
          _wrapWithApp(
            const SingleChildScrollView(child: KycVerificationSection()),
            verificationState: const EmailVerificationState(isVerified: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(strings.kycEmailVerificationRequiredHint),
          findsNothing,
        );
      },
    );

    testWidgets(
      'IdentitySubTab keeps Change Email open for unverified and Mobile Coming Soon',
      (tester) async {
        const strings = AppStrings('en');

        await tester.pumpWidget(
          _wrapWithApp(
            const SingleChildScrollView(child: IdentitySubTab()),
            verificationState: const EmailVerificationState(isVerified: false),
            advancedMode: true,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(strings.idChangeEmail), findsOneWidget);
        expect(find.text(strings.commonComingSoon), findsWidgets);
      },
    );

    testWidgets(
      'StylistChatSheet gates AI message send when email is unverified',
      (tester) async {
        const strings = AppStrings('en');

        await tester.pumpWidget(
          _wrapWithApp(
            const StylistChatSheet(),
            verificationState: const EmailVerificationState(isVerified: false),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Style me');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(
          find.text(strings.emailVerificationSoftGateTitle),
          findsOneWidget,
        );
      },
    );
  });
}
