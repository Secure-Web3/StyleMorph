import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
          body: SingleChildScrollView(
            child: IdentitySubTab(),
          ),
        ),
      ),
    );
  }

  group('International Postal / ZIP Code Field Tests', () {
    testWidgets('renders international "کد پستی" label in Persian without 10-digit restriction text',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('fa')));
      await tester.pumpAndSettle();

      // Ensure the old 10-digit label does NOT exist
      expect(find.text('کد پستی ۱۰ رقمی'), findsNothing);

      // Ensure new international label exists
      expect(find.text('کد پستی'), findsOneWidget);
    });

    testWidgets('renders "Postal / ZIP Code" label in English without 10-digit restriction text',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Ensure the old 10-digit label does NOT exist
      expect(find.text('10-Digit Postal Code'), findsNothing);

      // Ensure new international label exists
      expect(find.text('Postal / ZIP Code'), findsWidgets);
    });

    testWidgets('renders "الرمز البريدي" in Arabic and "Posta Kodu" in Turkish',
        (WidgetTester tester) async {
      // Arabic
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(find.text('الرمز البريدي (١٠ أرقام)'), findsNothing);
      expect(find.text('الرمز البريدي'), findsWidgets);

      // Turkish
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('tr')));
      await tester.pumpAndSettle();
      expect(find.text('10 Haneli Posta Kodu'), findsNothing);
      expect(find.text('Posta Kodu'), findsWidgets);
    });

    testWidgets('supports international alphanumeric formats up to 12 characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final zipFieldFinder = find.byWidgetPredicate(
        (w) => w is AppTextField && w.label == 'Postal / ZIP Code',
      );
      expect(zipFieldFinder, findsOneWidget);

      final appTextField = tester.widget<AppTextField>(zipFieldFinder);
      expect(appTextField.maxLength, 12);
      expect(appTextField.keyboardType, TextInputType.text);

      // Test entering a UK postal code with letters and numbers: "SW1A 1AA"
      await tester.enterText(zipFieldFinder, 'SW1A 1AA');
      await tester.pumpAndSettle();
      expect(find.text('SW1A 1AA'), findsOneWidget);

      // Test entering a US 9-digit ZIP+4: "90210-1234"
      await tester.enterText(zipFieldFinder, '90210-1234');
      await tester.pumpAndSettle();
      expect(find.text('90210-1234'), findsOneWidget);
    });

    test('AppState updates and retains international zip codes cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appStateProvider.notifier);

      // UK format
      notifier.updateIdentityField('zip', 'EC1A 1BB');
      expect(container.read(appStateProvider).identityValues['zip'], 'EC1A 1BB');
      expect(container.read(appStateProvider).hasUnsavedProfileChanges, isTrue);

      // Canada format
      notifier.updateIdentityField('zip', 'K1A 0B1');
      expect(container.read(appStateProvider).identityValues['zip'], 'K1A 0B1');

      // US ZIP+4 format
      notifier.updateIdentityField('zip', '10001-0001');
      expect(container.read(appStateProvider).identityValues['zip'], '10001-0001');
    });
  });
}
