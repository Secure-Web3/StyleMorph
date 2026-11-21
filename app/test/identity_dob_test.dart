import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_text_field.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
  );

  Widget buildTestableWidget({
    Locale locale = const Locale('fa'),
    List<dynamic> overrides = const [],
  }) {
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

  group('Date of Birth & Legal Age Validation Tests', () {
    testWidgets(
      'renders Date of Birth field with localized label and age requirement note in Persian',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        expect(find.text('تاریخ تولد'), findsOneWidget);
        expect(find.text('انتخاب تاریخ تولد'), findsOneWidget);
        expect(find.text('حداقل سن قانونی ۱۳ سال است'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is FaIcon &&
                w.icon?.codePoint == FontAwesomeIcons.calendar.codePoint,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders Date of Birth field with localized label in English', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Select date of birth'), findsOneWidget);
      expect(find.text('Minimum legal age is 13 years'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.calendar.codePoint,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'AppTextField supports controlled manual typing and calendar icon opens date picker',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        // Find the DOB AppTextField
        final dobFieldFinder = find.widgetWithText(
          AppTextField,
          'Date of Birth',
        );
        expect(dobFieldFinder, findsOneWidget);

        final appTextField = tester.widget<AppTextField>(dobFieldFinder);
        expect(appTextField.readOnly, isFalse);

        // Tap calendar icon button
        final calendarIconFinder = find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.calendar.codePoint,
        );
        expect(calendarIconFinder, findsOneWidget);
        await tester.tap(calendarIconFinder);
        await tester.pumpAndSettle();

        // The Flutter DatePicker dialog should now be open
        expect(find.byType(DatePickerDialog), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsNothing);

        // Test manual typing digits with auto-hyphen and Live Age pill
        await tester.enterText(dobFieldFinder, '19900520');
        await tester.pumpAndSettle();

        // Formatted to YYYY-MM-DD
        expect(find.text('1990-05-20'), findsOneWidget);

        // Live Age Pill calculates age in years
        expect(find.textContaining('yrs'), findsOneWidget);
      },
    );

    test('calculateProfileProgress includes dob in completion score', () {
      final withoutDob = AppStateNotifier.calculateProfileProgress(
        identity: {'email': 'test@example.com', 'firstName': 'Ali'},
        aiDna: {},
      );

      final withDob = AppStateNotifier.calculateProfileProgress(
        identity: {
          'email': 'test@example.com',
          'firstName': 'Ali',
          'dob': '2000-01-15',
        },
        aiDna: {},
      );

      expect(withDob, greaterThan(withoutDob));
      expect(withDob - withoutDob, closeTo(0.25 / 9, 0.001));
    });

    test('updateIdentityField preserves ISO-8601 dob format in state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);
      notifier.updateIdentityField('dob', '1995-06-20');

      final state = container.read(appStateProvider);
      expect(state.identityValues['dob'], '1995-06-20');
      expect(state.hasUnsavedProfileChanges, isTrue);
    });
  });
}
