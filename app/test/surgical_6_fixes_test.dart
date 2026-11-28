import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/referral_service.dart';
import 'package:stylemorph/core/services/two_factor_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/profile/domain/legal_document_v2.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/referral_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/two_factor_setup_dialog.dart';

class _FakeReferralService extends ReferralService {
  @override
  Future<String> ensureUserReferralCode(
    String uid, {
    String? existingCode,
  }) async => 'SM88TEST';

  @override
  Future<List<ReferralEntry>> getReferrals(String uid) async => const [];

  @override
  Stream<List<ReferralEntry>> referralsStream(String uid) =>
      Stream.value(const []);

  @override
  Future<ReferrerLookupResult> lookupReferrerByInput({
    required String rawInput,
    required String currentUid,
  }) async {
    final code = ReferralService.extractReferralCode(rawInput);
    if (code == null) {
      return const ReferrerLookupResult(
        status: ReferrerLookupStatus.invalidFormat,
      );
    }
    if (code == 'MYSELF1') {
      return const ReferrerLookupResult(
        status: ReferrerLookupStatus.selfReferral,
      );
    }
    return ReferrerLookupResult(
      status: ReferrerLookupStatus.found,
      referrer: UplineReferrerInfo(
        uid: 'inviter-1',
        code: code,
        displayName: 'Sara Moradi',
      ),
    );
  }

  @override
  Future<bool> bindUplineReferrer({
    required String currentUid,
    required String currentEmail,
    String? currentDisplayName,
    required String referralCode,
  }) async => true;
}

Widget _wrapApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.buildTheme(palette: AppPalette.editorial, isDark: false),
      locale: const Locale('en'),
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Fix 1: Google Play Authenticator Link in 2FA Setup', () {
    testWidgets(
      'Get on Google Play button launches Google Authenticator Play Store URI',
      (tester) async {
        Uri? launchedUri;
        await tester.pumpWidget(
          _wrapApp(
            SingleChildScrollView(
              child: TwoFactorSetupDialog(
                currentConfig: const TwoFactorConfig(
                  enabled: false,
                  method: TwoFactorMethod.totp,
                ),
                initialTotpSecret: 'JBSWY3DPEHPK3PXP',
                uidOverride: 'uid-1',
                onLaunchStoreUrl: (uri) async {
                  launchedUri = uri;
                  return true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final playBtn = find.byKey(const Key('two_fa_google_play_btn'));
        expect(playBtn, findsOneWidget);
        await tester.ensureVisible(playBtn);
        await tester.tap(playBtn);
        await tester.pumpAndSettle();

        expect(
          launchedUri.toString(),
          'https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2',
        );
      },
    );
  });

  group('Fix 2: Align Minimum Age to 13+ in Legal Agreement', () {
    test('all locales and legal clauses use 13+ instead of 18+', () {
      for (final lang in ['en', 'fa', 'ar', 'tr']) {
        final strings = AppStrings(lang);
        expect(strings.aboutAgreementCheckbox, isNot(contains('18')));
        expect(strings.aboutAgreementCheckbox, isNot(contains('۱۸')));
        expect(strings.aboutAgreementCheckbox, isNot(contains('١٨')));

        final keyPoints = LegalDocumentV2.getKeyPoints(lang);
        expect(keyPoints.first.headline, isNot(contains('18')));
        expect(keyPoints.first.headline, isNot(contains('۱۸')));
        expect(keyPoints.first.headline, isNot(contains('١٨')));

        final termsFirst = LegalDocumentV2.getTermsClauses(lang).first;
        expect(termsFirst.title, isNot(contains('18')));
        expect(termsFirst.title, isNot(contains('۱۸')));
        expect(termsFirst.title, isNot(contains('١٨')));
      }
    });
  });

  group('Fix 3: 3-Column Wheel Date Picker in IdentitySubTab', () {
    testWidgets(
      'tapping DOB opens 3-column CupertinoPicker wheel sheet and confirms date',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrapApp(const SingleChildScrollView(child: IdentitySubTab())),
        );
        await tester.pumpAndSettle();

        final calendarIcon = find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.calendar.codePoint,
        );
        await tester.ensureVisible(calendarIcon);
        await tester.tap(calendarIcon);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wheel_dob_picker_sheet')), findsOneWidget);
        expect(find.byType(CupertinoPicker), findsNWidgets(3));

        await tester.tap(find.byKey(const Key('wheel_dob_confirm_btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wheel_dob_picker_sheet')), findsNothing);
        expect(find.textContaining('yrs'), findsOneWidget);
      },
    );
  });

  group('Fix 4: AuthScreen Stable Scrollable Layout (No Keyboard Jump)', () {
    testWidgets(
      'AuthScreen renders cleanly with zero overflow when keyboard viewInsets open',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              viewInsets: EdgeInsets.only(bottom: 320),
            ),
            child: _wrapApp(const AuthScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: find.byType(AuthScreen),
            matching: find.byType(SingleChildScrollView),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Fix 5 & 6: Upline Referral + Smart Popup + Native Share Sheet', () {
    test('extractReferralCode parses invite URLs and raw codes cleanly', () {
      expect(
        ReferralService.extractReferralCode(
          'https://stylemorph.app/invite?ref=sm-9x2k',
        ),
        'SM-9X2K',
      );
      expect(
        ReferralService.extractReferralCode(
          'https://stylemorph-preview.web.app/?code=ab12cd34',
        ),
        'AB12CD34',
      );
      expect(
        ReferralService.extractReferralCode('https://stylemorph.app/r/xy99zw'),
        'XY99ZW',
      );
      expect(ReferralService.extractReferralCode(' sm77k9 '), 'SM77K9');
      expect(ReferralService.extractReferralCode(''), isNull);
    });

    testWidgets(
      'ReferralSubTab renders locked read-only upline card when upline is set',
      (tester) async {
        await tester.pumpWidget(
          _wrapApp(
            const SizedBox(
              height: 700,
              child: ReferralSubTab(uidOverride: 'user-1'),
            ),
            overrides: [
              referralServiceProvider.overrideWithValue(_FakeReferralService()),
              uplineReferrerProvider('user-1').overrideWith(
                (ref) async => const UplineReferrerInfo(
                  uid: 'inviter-1',
                  code: 'SM88SARA',
                  displayName: 'Sara Moradi',
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ref_upline_locked_card')), findsOneWidget);
        expect(find.text('Sara Moradi (SM88SARA)'), findsOneWidget);
        expect(find.byKey(const Key('ref_enter_code_btn')), findsNothing);
      },
    );

    testWidgets(
      'ReferralSubTab opens smart popup, confirms referrer, and triggers native share on Invite Link tap',
      (tester) async {
        String? sharedLink;
        await tester.pumpWidget(
          _wrapApp(
            SizedBox(
              height: 700,
              child: ReferralSubTab(
                uidOverride: 'user-1',
                onShareLinkOverride: (link, title) async {
                  sharedLink = link;
                  return true;
                },
              ),
            ),
            overrides: [
              referralServiceProvider.overrideWithValue(_FakeReferralService()),
              uplineReferrerProvider(
                'user-1',
              ).overrideWith((ref) async => null),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Tap Invite Link -> triggers native share sheet callback
        await tester.tap(find.byKey(const Key('ref_invite_link_tile')));
        await tester.pumpAndSettle();
        expect(sharedLink, contains('?ref='));

        // Tap Enter Referral Code -> smart popup -> paste URL -> confirmation dialog
        await tester.tap(find.byKey(const Key('ref_enter_code_btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('ref_upline_input_dialog')),
          findsOneWidget,
        );

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('ref_upline_input_field')),
            matching: find.byType(TextField),
          ),
          'https://stylemorph.app/invite?ref=SM9X2K',
        );
        await tester.tap(find.byKey(const Key('ref_upline_lookup_btn')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('ref_upline_confirm_dialog')),
          findsOneWidget,
        );
        expect(find.textContaining('Sara Moradi (SM9X2K)'), findsOneWidget);

        await tester.tap(find.byKey(const Key('ref_upline_confirm_btn')));
        await tester.pumpAndSettle();
      },
    );
  });
}
