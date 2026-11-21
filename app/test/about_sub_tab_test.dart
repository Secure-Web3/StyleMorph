import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/about_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/legal_doc_modal_sheet.dart';

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

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

  group('Profile Sidebar "About" Tab Integration (Task 27)', () {
    testWidgets('renders About tab below Settings with info icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          initialState: const AppState(
            isLoggedIn: true,
            currentProfileTab: 'p-settings',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Settings and About tabs in sidebar
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

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

    testWidgets('renders What\'s New changelog card with 5 highlights', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const SingleChildScrollView(child: AboutSubTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('What\'s New in Version 1.0'), findsOneWidget);
      expect(find.text('Virtual Try-On & Atelier Studio'), findsOneWidget);
      expect(find.text('Smart Wardrobe & Auto-Tagging'), findsOneWidget);
      expect(find.text('High-Resilience AI Gateway'), findsOneWidget);
      expect(find.text('Referral Rewards & Loyalty Tiers'), findsOneWidget);
      expect(find.text('Data Privacy & Dual Persona Avatar'), findsOneWidget);
    });

    testWidgets(
      'renders Legal & Compliance Links and opens Terms modal sheet',
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

        // Bottom sheet should be visible with Terms of Service content
        expect(find.byType(LegalDocModalSheet), findsOneWidget);
        expect(
          find.textContaining('By accessing or using StyleMorph'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders Official Contact & Socials with interactive links', (
      tester,
    ) async {
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
      expect(find.text('@stylemorph.app'), findsOneWidget);
      expect(find.text('@stylemorph'), findsOneWidget);
      expect(
        find.text('© 2026 StyleMorph. All rights reserved.'),
        findsOneWidget,
      );
    });
  });
}
