import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_button.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/about_sub_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore() async {}

  @override
  Future<bool> saveProfileToFirestore() async {
    return true;
  }

  @override
  Future<void> acceptTerms({String version = '1.0'}) async {
    state = state.copyWith(
      termsAcceptedAt: DateTime(2026, 11, 22),
      termsVersion: version,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  setUpAll(() {
    LicenseRegistry.addLicense(
      () => Stream<LicenseEntry>.fromIterable([
        const LicenseEntryWithLineBreaks([
          'stylemorph_core',
        ], 'StyleMorph Core License Apache 2.0'),
        const LicenseEntryWithLineBreaks([
          'sample_package',
        ], 'Sample Package MIT License'),
      ]),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_theme_palette': 'editorial',
      'user_theme_mode': 'light',
      'app_language_code': 'en',
    });
  });

  Widget createTestWidget({
    AppState? initialState,
    Locale locale = const Locale('en'),
    Widget? child,
  }) {
    final notifier = _TestAppStateNotifier(
      initialState ??
          const AppState(
            isLoggedIn: true,
            currentTab: AppTab.profile,
            currentProfileTab: 'p-about',
            termsAcceptedAt: null,
          ),
    );

    return ProviderScope(
      overrides: [appStateProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        theme: testTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('fa')],
        locale: locale,
        home: Scaffold(body: child ?? const ProfileTab()),
      ),
    );
  }

  group('Profile Sidebar "About" Tab Integration & Red Alert Badge', () {
    testWidgets('renders About tab below Settings with info icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: const AppState(
            isLoggedIn: true,
            currentProfileTab: 'p-settings',
            termsAcceptedAt: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Settings and About tabs in sidebar
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets(
      'shows red alert badge on About tab when termsAcceptedAt is null',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const AppState(
              isLoggedIn: true,
              currentProfileTab: 'p-settings',
              termsAcceptedAt: null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Red alert badge should be present on sidebar
        expect(
          find.byKey(const Key('sidebar_about_alert_badge')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides red alert badge on About tab when termsAcceptedAt is signed',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: AppState(
              isLoggedIn: true,
              currentProfileTab: 'p-settings',
              termsAcceptedAt: DateTime(2026, 11, 20),
              termsVersion: '1.0',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Red alert badge should NOT be present
        expect(
          find.byKey(const Key('sidebar_about_alert_badge')),
          findsNothing,
        );
      },
    );

    testWidgets('tapping About tab switches active tab to p-about', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: const AppState(
            isLoggedIn: true,
            currentProfileTab: 'p-identity',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final aboutTabFinder = find.text('About');
      expect(aboutTabFinder, findsOneWidget);

      await tester.tap(aboutTabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AboutSubTab), findsOneWidget);
    });

    testWidgets(
      'renders localized About tab label in Persian ("درباره برنامه")',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            locale: const Locale('fa'),
            initialState: const AppState(
              isLoggedIn: true,
              currentProfileTab: 'p-about',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('درباره برنامه'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsWidgets);
        expect(find.byType(AboutSubTab), findsOneWidget);
      },
    );
  });

  group('AboutSubTab Luxury Editorial Aesthetic & Sections', () {
    testWidgets('renders Brand Hero Card with logo, name, and mission', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const SingleChildScrollView(child: AboutSubTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('StyleMorph'), findsOneWidget);
      expect(
        find.text('Personal AI Stylist & Virtual Try-On Studio'),
        findsOneWidget,
      );
      expect(
        find.textContaining('StyleMorph is a cutting-edge platform'),
        findsOneWidget,
      );
    });

    testWidgets('renders Version & Build Status Specs Card', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const SingleChildScrollView(child: AboutSubTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('Build'), findsOneWidget);
      expect(find.text('Build 100'), findsOneWidget);
      expect(find.text('Release Date'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Stable (Production)'), findsOneWidget);
    });

    testWidgets('renders Manual "Check for Updates" Button & triggers check', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const SingleChildScrollView(child: AboutSubTab()),
        ),
      );
      await tester.pumpAndSettle();

      final checkBtn = find.text('Check for Updates');
      expect(checkBtn, findsOneWidget);

      await tester.tap(checkBtn);
      await tester.pump(); // Enter checking state

      // Wait for async completion
      await tester.pumpAndSettle();

      // In test/mock environment, it gracefully completes to upToDate
      expect(
        find.text('You are running the latest version of StyleMorph.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'STEP 1: verifies What\'s New changelog card has been completely removed',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const SingleChildScrollView(child: AboutSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        // Changelog must NOT be present
        expect(find.text('What\'s New in Version 1.0'), findsNothing);
        expect(find.text('What\'s New'), findsNothing);
        expect(find.text('تازه‌ها و تغییرات نسخه ۱.۰'), findsNothing);
      },
    );

    testWidgets(
      'STEP 4: renders User Agreement card when unsigned, allows signing and updates state',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const AppState(
              isLoggedIn: true,
              currentTab: AppTab.profile,
              currentProfileTab: 'p-about',
              termsAcceptedAt: null,
            ),
            child: const SingleChildScrollView(child: AboutSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        // Card should be rendered in unsigned state
        expect(find.byKey(const Key('agreement_card')), findsOneWidget);
        expect(find.text('User Agreement & Consent'), findsOneWidget);

        final triggerBtn = find.byKey(const Key('agreement_open_modal_button'));
        expect(triggerBtn, findsOneWidget);

        // Tap trigger button to open Full Contract modal
        await tester.scrollUntilVisible(triggerBtn, 100);
        await tester.tap(triggerBtn);
        await tester.pumpAndSettle();

        expect(find.byType(FullContractModalSheet), findsOneWidget);
        expect(
          find.text(
            'I have read and agree to the StyleMorph Terms of Service and Privacy Policy.',
          ),
          findsOneWidget,
        );

        final signBtn = find.byKey(const Key('agreement_sign_button'));
        expect(signBtn, findsOneWidget);

        // Sign button should be disabled when checkbox is unchecked
        final btnWidgetBefore = tester.widget<AppButton>(signBtn);
        expect(btnWidgetBefore.onPressed, isNull);

        // Tap checkbox
        final checkbox = find.byKey(const Key('agreement_checkbox'));
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // Sign button should now be enabled
        final btnWidgetAfter = tester.widget<AppButton>(signBtn);
        expect(btnWidgetAfter.onPressed, isNotNull);

        // Tap sign button
        await tester.tap(signBtn);
        await tester.pumpAndSettle();

        // Modal closes and verified green badge is shown
        expect(find.byType(FullContractModalSheet), findsNothing);
        expect(find.byKey(const Key('agreement_signed_badge')), findsOneWidget);
        expect(find.text('Electronically Signed & Accepted'), findsOneWidget);
        expect(find.textContaining('(v1.0)'), findsOneWidget);
      },
    );

    testWidgets(
      'FullContractModalSheet can be dismissed without signing via Close button',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            initialState: const AppState(
              isLoggedIn: true,
              currentTab: AppTab.profile,
              currentProfileTab: 'p-about',
              termsAcceptedAt: null,
            ),
            child: const SingleChildScrollView(child: AboutSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        final triggerBtn = find.byKey(const Key('agreement_open_modal_button'));
        await tester.scrollUntilVisible(triggerBtn, 100);
        await tester.tap(triggerBtn);
        await tester.pumpAndSettle();

        expect(find.byType(FullContractModalSheet), findsOneWidget);

        final cancelBtn = find.byKey(const Key('agreement_cancel_button'));
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        expect(find.byType(FullContractModalSheet), findsNothing);
        // Remains unsigned
        expect(
          find.byKey(const Key('agreement_open_modal_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('agreement_signed_badge')), findsNothing);
      },
    );

    testWidgets('STEP 4: renders verified green badge when already signed', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: AppState(
            isLoggedIn: true,
            currentTab: AppTab.profile,
            currentProfileTab: 'p-about',
            termsAcceptedAt: DateTime(2026, 11, 20),
            termsVersion: '1.0',
          ),
          child: const SingleChildScrollView(child: AboutSubTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('agreement_card')), findsOneWidget);
      expect(find.byKey(const Key('agreement_signed_badge')), findsOneWidget);
      expect(find.text('Electronically Signed & Accepted'), findsOneWidget);
      expect(
        find.textContaining('Signed on: 2026/11/20 (v1.0)'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('agreement_sign_button')), findsNothing);
    });

    testWidgets(
      'STEP 3: renders Legal & Compliance Links and opens Terms modal sheet with multi-line header & store-compliant sections',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const SingleChildScrollView(child: AboutSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Legal & Compliance'), findsOneWidget);
        final termsTile = find.text('Terms of Service');
        expect(termsTile, findsOneWidget);
        expect(
          find.text('Privacy Policy & AI Image Data Protection'),
          findsOneWidget,
        );
        expect(find.text('Open Source Licenses'), findsOneWidget);

        await tester.scrollUntilVisible(termsTile, 100);
        await tester.tap(termsTile);
        await tester.pumpAndSettle();

        // Bottom sheet should be visible with store-compliant Terms content
        expect(find.byType(LegalDocModalSheet), findsOneWidget);
        expect(
          find.textContaining('By accessing or using StyleMorph'),
          findsOneWidget,
        );
        expect(find.textContaining('13 years old'), findsOneWidget);
        // Scroll terms list to reveal Anti-Deepfake policy section
        final antiDeepfakeFinder = find.textContaining('Anti-Deepfake');
        await tester.scrollUntilVisible(
          antiDeepfakeFinder,
          100,
          scrollable: find.byType(Scrollable).last,
        );
        expect(antiDeepfakeFinder, findsOneWidget);

        // Close modal
        final closeBtn = find.text('Close');
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();
        expect(find.byType(LegalDocModalSheet), findsNothing);

        // Now test Privacy Policy modal
        final privacyTile = find.text(
          'Privacy Policy & AI Image Data Protection',
        );
        await tester.scrollUntilVisible(privacyTile, 100);
        await tester.tap(privacyTile);
        await tester.pumpAndSettle();

        expect(find.byType(LegalDocModalSheet), findsOneWidget);
        expect(
          find.textContaining(
            'Google Cloud Platform and Firebase infrastructure in Frankfurt',
          ),
          findsOneWidget,
        );

        await tester.drag(find.byType(ListView).last, const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(find.textContaining('Zero-Sale Guarantee'), findsOneWidget);

        // Close privacy modal
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(LegalDocModalSheet), findsNothing);
      },
    );

    testWidgets(
      'STEP 2: renders Official Contact & Socials and opens SocialLinksModal with high-contrast tokens',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const SingleChildScrollView(child: AboutSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Official Contact & Socials'), findsOneWidget);
        expect(find.text('Official Website'), findsOneWidget);
        expect(find.text('https://stylemorph.app'), findsOneWidget);
        expect(find.text('Support Email'), findsOneWidget);
        expect(find.text('support@stylemorph.app'), findsOneWidget);
        expect(find.text('Social Media'), findsOneWidget);
        expect(find.text('13 official channels & communities'), findsOneWidget);
        expect(
          find.text('© 2026 StyleMorph. All rights reserved.'),
          findsOneWidget,
        );

        final socialTile = find.text('Social Media');
        await tester.scrollUntilVisible(socialTile, 100);
        await tester.tap(socialTile);
        await tester.pumpAndSettle();

        // SocialLinksModal bottom sheet should be visible
        expect(find.byType(SocialLinksModal), findsOneWidget);
        expect(find.text('Instagram'), findsOneWidget);
        expect(find.text('TikTok'), findsOneWidget);
        expect(find.text('Telegram (Official)'), findsOneWidget);
        expect(find.text('Telegram (Main)'), findsOneWidget);
        expect(find.text('Telegram (Community)'), findsOneWidget);
        expect(find.text('@stylemorph.official'), findsWidgets);
        expect(find.text('@StyleMorph_official'), findsOneWidget);

        // Scroll list to reveal subsequent channels
        await tester.drag(find.byType(ListView).last, const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Telegram (Bot)'), findsOneWidget);
        expect(find.text('X (Twitter)'), findsOneWidget);
        expect(find.text('Threads'), findsOneWidget);
        expect(find.text('Pinterest'), findsOneWidget);
        expect(find.text('@stylemorph_bot'), findsOneWidget);
        expect(find.text('@StyleMorph_studio'), findsOneWidget);

        await tester.drag(find.byType(ListView).last, const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Snapchat'), findsOneWidget);
        expect(find.text('Facebook'), findsOneWidget);
        expect(find.text('Reddit'), findsOneWidget);
        expect(find.text('Bluesky'), findsOneWidget);
        expect(find.text('@stylemorph'), findsOneWidget);
        expect(find.text('u/StyleMorph_official'), findsOneWidget);
        expect(find.text('@stylemorph.bsky.social'), findsOneWidget);

        // Close modal
        final closeBtn = find.text('Close');
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();
        expect(find.byType(SocialLinksModal), findsNothing);
      },
    );

    testWidgets(
      'STEP 5: verifies global "StyleMorph" trademark brand unification (no Persian/Arabic transliterations)',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            locale: const Locale('fa'),
            child: const SingleChildScrollView(child: AboutSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        // Brand name should be Latin StyleMorph
        expect(find.text('StyleMorph'), findsWidgets);

        // No Persian transliteration should be visible in about tab
        expect(find.textContaining('استایل‌مورف'), findsNothing);
        expect(find.textContaining('استایل مورف'), findsNothing);
        expect(find.textContaining('ستايل مورف'), findsNothing);
      },
    );

    testWidgets(
      'tapping Open Source Licenses opens OpenSourceLicensesSheet with search and details',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            child: const SingleChildScrollView(child: AboutSubTab()),
          ),
        );
        await tester.pumpAndSettle();

        final licensesTile = find.text('Open Source Licenses');
        expect(licensesTile, findsOneWidget);

        await tester.scrollUntilVisible(licensesTile, 100);
        await tester.tap(licensesTile);
        await tester.pumpAndSettle();

        // OpenSourceLicensesSheet should be open
        expect(find.byType(OpenSourceLicensesSheet), findsOneWidget);
        expect(find.text('Search packages or libraries...'), findsOneWidget);

        // The registered test packages should be rendered
        expect(find.text('stylemorph_core'), findsOneWidget);
        expect(find.text('sample_package'), findsOneWidget);

        // Tap a package to view its full license details
        await tester.tap(find.text('stylemorph_core'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('StyleMorph Core License Apache 2.0'),
          findsOneWidget,
        );

        // Close the detail dialog
        final dialogClose = find.text('Close');
        await tester.tap(dialogClose.last);
        await tester.pumpAndSettle();

        // Test filtering by typing in search
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'sample');
        await tester.pumpAndSettle();

        expect(find.text('sample_package'), findsOneWidget);
        expect(find.text('stylemorph_core'), findsNothing);

        // Clear search
        await tester.enterText(searchField, 'nonexistent_pkg_123');
        await tester.pumpAndSettle();
        expect(find.text('No packages match your search'), findsOneWidget);
      },
    );
  });
}
