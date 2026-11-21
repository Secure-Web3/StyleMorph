import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_badge.dart';
import 'package:stylemorph/core/widgets/app_button.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_provider.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_screen.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  Widget buildTestableWidget({
    required bool isVerified,
    Locale locale = const Locale('fa'),
  }) {
    return ProviderScope(
      overrides: [
        emailVerifiedOverrideProvider.overrideWith((ref) => isVerified),
        emailVerificationProvider.overrideWith(
          (ref) => EmailVerificationNotifier(ref)
            ..state = EmailVerificationState(
              isVerified: isVerified,
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
          body: SingleChildScrollView(child: IdentitySubTab()),
        ),
      ),
    );
  }

  group('Smart Email Verification Status in IdentitySubTab Tests', () {
    testWidgets(
      'when emailVerified == true, displays green verified badge and hides verify/check buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(isVerified: true, locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Email field label should exist
        expect(find.text('ایمیل'), findsOneWidget);

        // Clean green verified badge should be visible
        expect(find.widgetWithText(AppBadge, 'تایید شده'), findsOneWidget);

        // Warning badge ("تأیید نشده") should NOT be visible
        expect(find.widgetWithText(AppBadge, 'تأیید نشده'), findsNothing);

        // Verify and Check Status buttons must NOT exist
        expect(find.widgetWithText(AppButton, 'تایید ایمیل'), findsNothing);
        expect(find.widgetWithText(AppButton, 'بررسی تایید'), findsNothing);
      },
    );

    testWidgets(
      'when emailVerified == false, displays warning badge and action buttons in Persian',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(isVerified: false, locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Warning badge ("تأیید نشده") should be visible
        expect(find.widgetWithText(AppBadge, 'تأیید نشده'), findsOneWidget);

        // Verified badge ("تایید شده") must NOT exist
        expect(find.widgetWithText(AppBadge, 'تایید شده'), findsNothing);

        // Active "Verify Email" button must exist
        final verifyBtn = find.widgetWithText(AppButton, 'تایید ایمیل');
        expect(verifyBtn, findsOneWidget);

        // Compact "Check Status" button must exist
        final checkBtn = find.widgetWithText(AppButton, 'بررسی تایید');
        expect(checkBtn, findsOneWidget);
      },
    );

    testWidgets(
      'when emailVerified == false, displays localized buttons in English',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(isVerified: false, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBadge, 'Unverified'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Verify Email'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'Check Status'), findsOneWidget);
      },
    );

    testWidgets(
      'when emailVerified == false, displays localized buttons in Arabic',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(isVerified: false, locale: const Locale('ar')),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBadge, 'غير مؤكد'), findsOneWidget);
        expect(find.widgetWithText(AppButton, 'تأكيد البريد'), findsOneWidget);
        expect(
          find.widgetWithText(AppButton, 'التحقق من الحالة'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when emailVerified == false, displays localized buttons in Turkish',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(isVerified: false, locale: const Locale('tr')),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBadge, 'Doğrulanmadı'), findsOneWidget);
        expect(
          find.widgetWithText(AppButton, 'E-postayı Doğrula'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(AppButton, 'Durumu Kontrol Et'),
          findsOneWidget,
        );
      },
    );
  });
}
