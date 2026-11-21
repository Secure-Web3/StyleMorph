import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_badge.dart';
import 'package:stylemorph/core/widgets/app_button.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  Widget buildTestableWidget({Locale locale = const Locale('fa')}) {
    return ProviderScope(
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

  group('Mobile Verification Button & Coming Soon Badge Tests', () {
    testWidgets(
      'removes fake verified badge and renders disabled button with Coming Soon badge in Persian',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Mobile label should exist
        expect(find.text('شماره موبایل'), findsOneWidget);

        // Verify the mobile verification button exists
        final buttonFinder = find.widgetWithText(AppButton, 'تایید');
        expect(buttonFinder, findsOneWidget);

        // Ensure button is strictly disabled (onPressed == null)
        final appButton = tester.widget<AppButton>(buttonFinder);
        expect(appButton.onPressed, isNull);

        // Ensure "Coming Soon" (به زودی) badge exists
        final comingSoonBadge = find.widgetWithText(AppBadge, 'به زودی');
        expect(comingSoonBadge, findsOneWidget);

        // Verify there is NO fake verified badge on mobile
        // (The only "تایید شده" should be on email only if email is verified, but default is unverified "تأیید نشده")
        expect(find.widgetWithText(AppBadge, 'تایید شده'), findsNothing);
      },
    );

    testWidgets(
      'renders disabled mobile button and Coming Soon badge in English',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mobile Number'), findsOneWidget);

        // "Verify" button disabled
        final buttonFinder = find.widgetWithText(AppButton, 'Verify');
        expect(buttonFinder, findsOneWidget);
        final appButton = tester.widget<AppButton>(buttonFinder);
        expect(appButton.onPressed, isNull);

        // "Coming Soon" badge
        final comingSoonBadge = find.widgetWithText(AppBadge, 'Coming Soon');
        expect(comingSoonBadge, findsOneWidget);
      },
    );

    testWidgets(
      'renders disabled mobile button and Coming Soon badge in Arabic',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('ar')),
        );
        await tester.pumpAndSettle();

        expect(find.text('رقم الجوال'), findsOneWidget);

        final buttonFinder = find.widgetWithText(AppButton, 'تأكيد');
        expect(buttonFinder, findsOneWidget);
        final appButton = tester.widget<AppButton>(buttonFinder);
        expect(appButton.onPressed, isNull);

        final comingSoonBadge = find.widgetWithText(AppBadge, 'قريباً');
        expect(comingSoonBadge, findsOneWidget);
      },
    );

    testWidgets(
      'renders disabled mobile button and Coming Soon badge in Turkish',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('tr')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cep Telefonu'), findsOneWidget);

        final buttonFinder = find.widgetWithText(AppButton, 'Doğrula');
        expect(buttonFinder, findsOneWidget);
        final appButton = tester.widget<AppButton>(buttonFinder);
        expect(appButton.onPressed, isNull);

        final comingSoonBadge = find.widgetWithText(AppBadge, 'Yakında');
        expect(comingSoonBadge, findsOneWidget);
      },
    );

    testWidgets('tapping disabled mobile button does nothing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('fa')));
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(AppButton, 'تایید');
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // State remains unchanged and no exceptions thrown
      expect(find.widgetWithText(AppBadge, 'به زودی'), findsOneWidget);
    });
  });
}
