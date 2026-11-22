import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_badge.dart';
import 'package:stylemorph/core/widgets/app_button.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }
}

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  Widget buildTestableWidget({Locale locale = const Locale('fa')}) {
    return ProviderScope(
      overrides: [
        appStateProvider.overrideWith(
          (ref) => _TestAppStateNotifier(
            const AppState(preferences: UserPreferences(appMode: 'advanced')),
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

  group('Mobile Verification Section & Coming Soon Badge Tests', () {
    testWidgets(
      'renders clean mobile row with Coming Soon badge and no cramped inline verify button in Persian',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Mobile label should exist
        expect(find.text('شماره موبایل'), findsOneWidget);

        // Ensure "Coming Soon" (به زودی) badge exists in the label row
        final comingSoonBadge = find.widgetWithText(AppBadge, 'به زودی');
        expect(comingSoonBadge, findsOneWidget);

        // Ensure the old cramped inline verify button has been removed from input row
        expect(find.widgetWithText(AppButton, 'تایید'), findsNothing);

        // Dial code picker button is present
        expect(find.text('+98'), findsOneWidget);

        // Verify there is NO fake verified badge on mobile
        expect(find.widgetWithText(AppBadge, 'تایید شده'), findsNothing);
      },
    );

    testWidgets('renders clean mobile row with Coming Soon badge in English', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Number'), findsOneWidget);

      // "Coming Soon" badge
      final comingSoonBadge = find.widgetWithText(AppBadge, 'Coming Soon');
      expect(comingSoonBadge, findsOneWidget);

      // No cramped inline verify button
      expect(find.widgetWithText(AppButton, 'Verify'), findsNothing);
    });

    testWidgets('renders clean mobile row with Coming Soon badge in Arabic', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('رقم الجوال'), findsOneWidget);

      final comingSoonBadge = find.widgetWithText(AppBadge, 'قريباً');
      expect(comingSoonBadge, findsOneWidget);

      expect(find.widgetWithText(AppButton, 'تأكيد'), findsNothing);
    });

    testWidgets('renders clean mobile row with Coming Soon badge in Turkish', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('tr')));
      await tester.pumpAndSettle();

      expect(find.text('Cep Telefonu'), findsOneWidget);

      final comingSoonBadge = find.widgetWithText(AppBadge, 'Yakında');
      expect(comingSoonBadge, findsOneWidget);

      expect(find.widgetWithText(AppButton, 'Doğrula'), findsNothing);
    });

    testWidgets('dial code selector button is interactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('fa')));
      await tester.pumpAndSettle();

      final dialPickerFinder = find.text('+98');
      expect(dialPickerFinder, findsOneWidget);
      await tester.tap(dialPickerFinder);
      await tester.pumpAndSettle();

      // State remains healthy and bottom sheet opened or handled cleanly
      expect(find.widgetWithText(AppBadge, 'به زودی'), findsOneWidget);
    });
  });
}
