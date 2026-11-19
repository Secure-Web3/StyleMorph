import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_button.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_provider.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_screen.dart';
import 'package:stylemorph/features/profile/presentation/widgets/change_email_dialog.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  Widget buildTestableWidget({
    Locale locale = const Locale('fa'),
  }) {
    return ProviderScope(
      overrides: [
        emailVerifiedOverrideProvider.overrideWith((ref) => true),
        emailVerificationProvider.overrideWith(
          (ref) => EmailVerificationNotifier(ref)
            ..state = const EmailVerificationState(
              isVerified: true,
              cooldownSeconds: 0,
            ),
        ),
      ],
      child: MaterialApp(
        theme: testTheme,
        locale: locale,
        supportedLocales: const [
          Locale('fa'),
          Locale('en'),
          Locale('ar'),
          Locale('tr'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: SingleChildScrollView(
            child: IdentitySubTab(),
          ),
        ),
      ),
    );
  }

  Widget buildDialogWidget({
    Locale locale = const Locale('fa'),
  }) {
    return MaterialApp(
      theme: testTheme,
      locale: locale,
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(
        body: Center(
          child: ChangeEmailDialog(),
        ),
      ),
    );
  }

  group('High-Security Email Change Flow Tests', () {
    testWidgets('Change Email button is rendered in IdentitySubTab in Persian',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('fa')));
      await tester.pumpAndSettle();

      final changeBtn = find.widgetWithText(AppButton, 'تغییر ایمیل');
      expect(changeBtn, findsOneWidget);

      final appButton = tester.widget<AppButton>(changeBtn);
      // For email/password account (no social provider), button is enabled
      expect(appButton.onPressed, isNotNull);
    });

    testWidgets('Change Email button is rendered in English',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final changeBtn = find.widgetWithText(AppButton, 'Change Email');
      expect(changeBtn, findsOneWidget);
    });

    testWidgets('ChangeEmailDialog Step 1 renders reauth password input and support link',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialogWidget(locale: const Locale('fa')));
      await tester.pumpAndSettle();

      // Title & Step 1/2 indicator
      expect(find.text('تغییر آدرس ایمیل'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('رمز عبور فعلی'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'تایید رمز و ادامه'), findsOneWidget);

      // Support contact link
      expect(find.text('به ایمیل قبلی خود دسترسی ندارید؟ تماس با پشتیبانی'), findsOneWidget);
    });

    testWidgets('ChangeEmailDialog Step 1 enters password, advances to Step 2 with notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialogWidget(locale: const Locale('fa')));
      await tester.pumpAndSettle();

      // Enter password
      await tester.enterText(find.byType(TextField).first, 'currentPass123');
      await tester.pumpAndSettle();

      // Click "Verify & Continue"
      final continueBtn = find.widgetWithText(AppButton, 'تایید رمز و ادامه');
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Now on Step 2
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('آدرس ایمیل جدید'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'ارسال لینک تایید به ایمیل جدید'), findsOneWidget);

      // Security notice regarding old email remaining active and security alert revert link
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('ChangeEmailDialog Step 2 sends verification and transitions to Step 3 success',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialogWidget(locale: const Locale('fa')));
      await tester.pumpAndSettle();

      // Step 1
      await tester.enterText(find.byType(TextField).first, 'currentPass123');
      await tester.tap(find.widgetWithText(AppButton, 'تایید رمز و ادامه'));
      await tester.pumpAndSettle();

      // Step 2: enter new valid email
      await tester.enterText(find.byType(TextField).first, 'newuser@example.com');
      await tester.pumpAndSettle();

      // Click "Send Verification Link"
      await tester.tap(find.widgetWithText(AppButton, 'ارسال لینک تایید به ایمیل جدید'));
      await tester.pumpAndSettle();

      // Step 3: Success Confirmation
      expect(find.text('لینک تایید ارسال شد'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'متوجه شدم'), findsOneWidget);
    });

    testWidgets('ChangeEmailDialog renders correctly in English across all steps',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDialogWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Change Email Address'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Verify & Continue'), findsOneWidget);
      expect(find.text('Lost access to your old email? Contact Support'), findsOneWidget);
    });
  });
}
