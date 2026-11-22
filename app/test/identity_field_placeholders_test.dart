import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
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

  group('Identity Sub-Tab Field Placeholders & Hint Examples Tests', () {
    testWidgets(
      'renders localized placeholders for all empty input fields in Persian',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // First Name & Last Name
        expect(find.text('مثال: علی'), findsOneWidget);
        expect(find.text('مثال: رضایی'), findsOneWidget);

        // Handle & National ID
        expect(find.text('@ali_style'), findsOneWidget);
        expect(find.text('کد ملی ۱۰ رقمی'), findsOneWidget);

        // Date of Birth
        expect(find.text('انتخاب تاریخ تولد'), findsOneWidget);

        // Mobile
        expect(find.text('+98 912 345 6789'), findsOneWidget);

        // Country, Province, City
        expect(find.text('مثال: ایران'), findsOneWidget);
        expect(find.text('مثال: تهران'), findsNWidgets(2)); // Province & City

        // Address & Postal Code
        expect(find.text('خیابان، کوچه، پلاک، واحد'), findsOneWidget);
        expect(find.text('کد پستی / زیپ‌کد'), findsOneWidget);
      },
    );

    testWidgets(
      'renders localized placeholders for all empty input fields in English',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        // First Name & Last Name
        expect(find.text('e.g. Ali'), findsOneWidget);
        expect(find.text('e.g. Rezaei'), findsOneWidget);

        // Handle & National ID
        expect(find.text('@ali_style'), findsOneWidget);
        expect(find.text('National ID number'), findsOneWidget);

        // Date of Birth
        expect(find.text('Select date of birth'), findsOneWidget);

        // Mobile
        expect(find.text('+1 234 567 8900'), findsOneWidget);

        // Country, Province, City
        expect(find.text('e.g. United States, Canada'), findsOneWidget);
        expect(find.text('e.g. California, Ontario'), findsOneWidget);
        expect(find.text('e.g. New York, Toronto'), findsOneWidget);

        // Address & Postal Code
        expect(
          find.text('Street name, building number, suite'),
          findsOneWidget,
        );
        expect(find.text('Postal / ZIP Code'), findsWidgets);
      },
    );

    test(
      'AppStrings contains non-empty placeholders across all 4 languages',
      () {
        for (final lang in ['fa', 'en', 'ar', 'tr']) {
          final strings = AppStrings(lang);
          expect(strings.idFirstNamePlaceholder.isNotEmpty, isTrue);
          expect(strings.idLastNamePlaceholder.isNotEmpty, isTrue);
          expect(strings.idNickPlaceholder.isNotEmpty, isTrue);
          expect(strings.idNationalIdPlaceholder.isNotEmpty, isTrue);
          expect(strings.idDobPlaceholder.isNotEmpty, isTrue);
          expect(strings.idMobilePlaceholder.isNotEmpty, isTrue);
          expect(strings.idEmailPlaceholder.isNotEmpty, isTrue);
          expect(strings.idCountryPlaceholder.isNotEmpty, isTrue);
          expect(strings.idProvincePlaceholder.isNotEmpty, isTrue);
          expect(strings.idCityPlaceholder.isNotEmpty, isTrue);
          expect(strings.idAddressPlaceholder.isNotEmpty, isTrue);
          expect(strings.idZipPlaceholder.isNotEmpty, isTrue);
        }
      },
    );
  });
}
