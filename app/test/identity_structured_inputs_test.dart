import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_text_field.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_provider.dart';
import 'package:stylemorph/features/auth/presentation/email_verification_screen.dart';
import 'package:stylemorph/features/profile/data/identity_validator.dart';
import 'package:stylemorph/features/profile/data/iso_location_data.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  Widget buildTestableWidget({
    Locale locale = const Locale('fa'),
    AppState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          appStateProvider.overrideWith(
            (ref) => _TestAppStateNotifier(initialState),
          ),
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
          body: SingleChildScrollView(child: IdentitySubTab()),
        ),
      ),
    );
  }

  group('Iranian National ID Modulo-11 Validation Tests', () {
    test('validates correct Iranian national IDs', () {
      // Valid National IDs with correct modulo-11 check digit
      expect(IdentityValidator.isValidIranianNationalId('0010350810'), true);
      expect(IdentityValidator.isValidIranianNationalId('0499370899'), true);
      expect(IdentityValidator.isValidIranianNationalId('7731689956'), true);
      expect(IdentityValidator.isValidIranianNationalId('0084545933'), true);
    });

    test('rejects fake repeated digits (e.g. 1111111111, 0000000000)', () {
      expect(IdentityValidator.isValidIranianNationalId('0000000000'), false);
      expect(IdentityValidator.isValidIranianNationalId('1111111111'), false);
      expect(IdentityValidator.isValidIranianNationalId('2222222222'), false);
      expect(IdentityValidator.isValidIranianNationalId('9999999999'), false);
    });

    test('rejects incorrect length or non-digit characters', () {
      expect(IdentityValidator.isValidIranianNationalId('12345'), false);
      expect(IdentityValidator.isValidIranianNationalId('00103508110'), false);
      expect(IdentityValidator.isValidIranianNationalId('001035081A'), false);
      expect(IdentityValidator.isValidIranianNationalId(''), false);
      expect(IdentityValidator.isValidIranianNationalId(null), false);
    });

    test('rejects invalid check-digit', () {
      // 0010350811 is valid; changing last digit makes it invalid
      expect(IdentityValidator.isValidIranianNationalId('0010350812'), false);
      expect(IdentityValidator.isValidIranianNationalId('0010350819'), false);
    });
  });

  group('Turkish Kimlik (T.C. Kimlik No) Validation Tests', () {
    test('validates correct 11-digit Turkish Kimlik numbers', () {
      // 10000000146 is a standard valid test T.C. Kimlik
      expect(IdentityValidator.isValidTurkishKimlik('10000000146'), true);
    });

    test('rejects Kimlik starting with 0 or non-11 digits', () {
      expect(IdentityValidator.isValidTurkishKimlik('01234567890'), false);
      expect(IdentityValidator.isValidTurkishKimlik('1234567890'), false);
      expect(IdentityValidator.isValidTurkishKimlik('123456789012'), false);
      expect(IdentityValidator.isValidTurkishKimlik('1000000014A'), false);
      expect(IdentityValidator.isValidTurkishKimlik(''), false);
      expect(IdentityValidator.isValidTurkishKimlik(null), false);
    });

    test('rejects invalid 10th or 11th check digits', () {
      // 10000000146 is valid; changing 10th or 11th digit fails
      expect(IdentityValidator.isValidTurkishKimlik('10000000156'), false);
      expect(IdentityValidator.isValidTurkishKimlik('10000000147'), false);
    });
  });

  group('Country-Aware Postal / ZIP Code Validation Tests', () {
    test('validates Iranian 10-digit postal codes', () {
      expect(IdentityValidator.isValidIranianPostalCode('1939546789'), true);
      expect(IdentityValidator.isValidIranianPostalCode('3153512345'), true);

      // Cannot start with 0 or 2
      expect(IdentityValidator.isValidIranianPostalCode('0123456789'), false);
      expect(IdentityValidator.isValidIranianPostalCode('2123456789'), false);
      // Rejects non-10 digits or repeated digits
      expect(IdentityValidator.isValidIranianPostalCode('1111111111'), false);
      expect(IdentityValidator.isValidIranianPostalCode('12345'), false);
    });

    test('validates Turkish 5-digit postal codes', () {
      expect(IdentityValidator.isValidTurkishPostalCode('34000'), true);
      expect(IdentityValidator.isValidTurkishPostalCode('06100'), true);
      expect(IdentityValidator.isValidTurkishPostalCode('3400'), false);
      expect(IdentityValidator.isValidTurkishPostalCode('340000'), false);
      expect(IdentityValidator.isValidTurkishPostalCode('34ABC'), false);
    });

    test('validates International alphanumeric postal codes', () {
      expect(
        IdentityValidator.isValidInternationalPostalCode('SW1A 1AA'),
        true,
      );
      expect(IdentityValidator.isValidInternationalPostalCode('90210'), true);
      expect(IdentityValidator.isValidInternationalPostalCode('K1A-0B1'), true);
      expect(IdentityValidator.isValidInternationalPostalCode('12'), false);
    });
  });

  group('E.164 Structured Mobile Validation & Formatting Tests', () {
    final iran = IsoLocationData.findByCode('IR')!;
    final turkey = IsoLocationData.findByCode('TR')!;
    final usa = IsoLocationData.findByCode('US')!;

    test('validates subscriber length and prefixes per country', () {
      // Iran: 10 digits starting with 9
      expect(IdentityValidator.isValidSubscriber('9123456789', iran), true);
      expect(
        IdentityValidator.isValidSubscriber('09123456789', iran),
        true,
      ); // normalized
      expect(
        IdentityValidator.isValidSubscriber('8123456789', iran),
        false,
      ); // not starting with 9
      expect(
        IdentityValidator.isValidSubscriber('912345678', iran),
        false,
      ); // only 9 digits

      // Turkey: 10 digits starting with 5
      expect(IdentityValidator.isValidSubscriber('5321234567', turkey), true);
      expect(IdentityValidator.isValidSubscriber('05321234567', turkey), true);
      expect(IdentityValidator.isValidSubscriber('4321234567', turkey), false);

      // USA: 10 digits
      expect(IdentityValidator.isValidSubscriber('2025550123', usa), true);
    });

    test('formats canonical +E164 string correctly', () {
      expect(
        IdentityValidator.formatE164(dialCode: '+98', subscriber: '9123456789'),
        '+989123456789',
      );
      expect(
        IdentityValidator.formatE164(dialCode: '98', subscriber: '09123456789'),
        '+989123456789',
      );
      expect(
        IdentityValidator.formatE164(
          dialCode: '+90',
          subscriber: '05321234567',
        ),
        '+905321234567',
      );
    });

    test(
      'parses existing canonical +E164 string back into country and subscriber',
      () {
        final parsedIran = IdentityValidator.parseE164('+989123456789');
        expect(parsedIran.country.code, 'IR');
        expect(parsedIran.subscriber, '9123456789');

        final parsedTurkey = IdentityValidator.parseE164('+905321234567');
        expect(parsedTurkey.country.code, 'TR');
        expect(parsedTurkey.subscriber, '5321234567');

        final parsedUsa = IdentityValidator.parseE164('+12025550123');
        expect(parsedUsa.country.dialCode, '+1');
        expect(parsedUsa.subscriber, '2025550123');
      },
    );
  });

  group('Identity Sub-Tab Structured Widget Tests', () {
    testWidgets(
      'unrestricted First Name, Last Name, and Nickname fields accept Unicode',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Find First Name, Last Name, Nickname
        final firstFinder = find.widgetWithText(AppTextField, 'نام');
        final lastFinder = find.widgetWithText(AppTextField, 'نام خانوادگی');
        final nickFinder = find.widgetWithText(AppTextField, 'نام مستعار');

        expect(firstFinder, findsOneWidget);
        expect(lastFinder, findsOneWidget);
        expect(nickFinder, findsOneWidget);

        // Enter Persian characters
        await tester.enterText(firstFinder, 'علیرضا');
        await tester.enterText(lastFinder, 'رضایی');
        await tester.enterText(nickFinder, 'سردار_استایل');
        await tester.pumpAndSettle();

        expect(find.text('علیرضا'), findsOneWidget);
        expect(find.text('رضایی'), findsOneWidget);
        expect(find.text('سردار_استایل'), findsOneWidget);

        // Enter Turkish / Arabic / English characters
        await tester.enterText(firstFinder, 'Ahmet Özgür');
        await tester.enterText(lastFinder, 'Yılmaz');
        await tester.enterText(nickFinder, '@ahmet_tr');
        await tester.pumpAndSettle();

        expect(find.text('Ahmet Özgür'), findsOneWidget);
        expect(find.text('Yılmaz'), findsOneWidget);
        expect(find.text('@ahmet_tr'), findsOneWidget);
      },
    );

    testWidgets(
      'renders cascading Country, Province, and City selectors with flags',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Country selector exists with Iran flag and label
        expect(find.text('🇮🇷'), findsWidgets);
        expect(find.text('کشور'), findsOneWidget);
        expect(find.text('استان'), findsOneWidget);
        expect(find.text('شهر'), findsOneWidget);
      },
    );

    testWidgets(
      'renders structured E.164 mobile dial code picker button and subscriber input',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Dial code button shows "+98" and flag
        expect(find.text('+98'), findsOneWidget);
        expect(find.text('به زودی'), findsOneWidget);
        expect(find.text('شماره موبایل'), findsOneWidget);

        // Entering invalid Iranian mobile shows error
        final mobileSubscriberFinder = find.byWidgetPredicate(
          (w) => w is AppTextField && w.keyboardType == TextInputType.phone,
        );
        expect(mobileSubscriberFinder, findsOneWidget);

        await tester.enterText(mobileSubscriberFinder, '1234');
        await tester.pumpAndSettle();

        expect(
          find.text('شماره موبایل وارد شده برای این کشور نامعتبر است'),
          findsOneWidget,
        );

        // Entering valid Iranian mobile clears error
        await tester.enterText(mobileSubscriberFinder, '9123456789');
        await tester.pumpAndSettle();

        expect(
          find.text('شماره موبایل وارد شده برای این کشور نامعتبر است'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'validates Iranian National ID using modulo-11 and shows error on invalid input',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        final nidFinder = find.widgetWithText(AppTextField, 'کد ملی');
        expect(nidFinder, findsOneWidget);

        // Enter repeated digits (invalid)
        await tester.enterText(nidFinder, '1111111111');
        await tester.pumpAndSettle();

        expect(find.text('کد ملی ۱۰ رقمی نامعتبر است'), findsOneWidget);

        // Enter valid Iranian national ID (e.g. 0010350810)
        await tester.enterText(nidFinder, '0010350810');
        await tester.pumpAndSettle();

        expect(find.text('کد ملی ۱۰ رقمی نامعتبر است'), findsNothing);
      },
    );

    testWidgets(
      'validates Iranian Postal Code and shows error on invalid input',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestableWidget(locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        final zipFinder = find.widgetWithText(AppTextField, 'کد پستی');
        expect(zipFinder, findsOneWidget);

        // Enter invalid postal code starting with 0
        await tester.enterText(zipFinder, '0123456789');
        await tester.pumpAndSettle();

        expect(
          find.text('کد پستی باید ۱۰ رقم عددی معتبر باشد'),
          findsOneWidget,
        );

        // Enter valid 10-digit postal code
        await tester.enterText(zipFinder, '1939546789');
        await tester.pumpAndSettle();

        expect(find.text('کد پستی باید ۱۰ رقم عددی معتبر باشد'), findsNothing);
      },
    );
  });
}

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initialState) : super() {
    state = initialState;
  }

  @override
  Future<void> loadProfileFromFirestore() async {
    // No-op in test
  }
}
