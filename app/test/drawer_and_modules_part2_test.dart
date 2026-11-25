import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/app_logo.dart';
import 'package:stylemorph/core/widgets/brand_wordmark.dart';
import 'package:stylemorph/core/widgets/gender_3d_avatar.dart';
import 'package:stylemorph/features/atelier/presentation/atelier_tab.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';
import 'package:stylemorph/features/shop/presentation/shop_tab.dart';
import 'package:stylemorph/features/stylist/presentation/stylist_tab.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_tab.dart';
import 'package:stylemorph/features/wellness/presentation/wellness_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {}
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
      'app_language_code': 'fa',
    });
  });

  ProviderContainer createContainer({
    String languageCode = 'fa',
    AppTab initialTab = AppTab.wardrobe,
  }) {
    final container = ProviderContainer(
      overrides: [
        appStateProvider.overrideWith(
          (ref) => _TestAppStateNotifier(
            AppState(
              isLoggedIn: true,
              currentTab: initialTab,
              userName: 'Sara Ahmadi',
              loyaltyRank: 'Silver',
              stylePoints: 624,
              profileProgress: 0.84,
              preferences: UserPreferences(
                fashionThemePalette: 'editorial',
                brightnessMode: 'light',
                appLanguage: languageCode,
                appMode: 'simple',
              ),
            ),
          ),
        ),
      ],
    );
    container.read(localeProvider.notifier).setLanguage(languageCode);
    return container;
  }

  group('Part 2: AppDrawer Refactor & Bottom Nav Unlock', () {
    for (final localeCode in ['fa', 'en']) {
      testWidgets(
        'AppDrawer renders 3-zone luxury layout without redundant Referral/Companion items or overflow ($localeCode)',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 667));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final strings = AppStrings(localeCode);
          final container = createContainer(languageCode: localeCode);
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: testTheme,
                locale: Locale(localeCode),
                supportedLocales: AppLanguage.supportedLanguages
                    .map((l) => l.locale)
                    .toList(),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: const Scaffold(body: AppDrawer()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Zone 1: AppLogo, BrandWordmark, Interactive Profile Card
          expect(find.byType(AppLogo), findsOneWidget);
          expect(find.byType(BrandWordmark), findsOneWidget);
          expect(find.text('Sara Ahmadi'), findsOneWidget);
          expect(
            find.textContaining(strings.formatNumber(624)),
            findsOneWidget,
          );
          expect(find.text(strings.formatPercent(84)), findsOneWidget);

          // Zone 2: Compact Wallet & Plan + Activity + App & Support
          expect(find.text(strings.tWal), findsOneWidget);
          expect(find.text(strings.drawerSectionActivity), findsOneWidget);
          expect(find.text(strings.drawerSectionAppSupport), findsOneWidget);
          expect(find.text(strings.tSet), findsOneWidget);
          expect(find.text(strings.mSupport), findsOneWidget);
          expect(find.text(strings.tAbout), findsOneWidget);

          // No redundant Referral or Companion items
          expect(find.text(strings.tRef), findsNothing);
          expect(find.text(strings.tComp), findsNothing);

          // Zone 3: Quick Control Dock
          expect(find.text(strings.appModeSimple), findsOneWidget);
          expect(find.text(strings.appModeAdvanced), findsOneWidget);
          expect(find.text(strings.mOut), findsOneWidget);

          expect(tester.takeException(), isNull);

          // Tapping Profile Identity Card navigates to Profile
          await tester.tap(find.text('Sara Ahmadi'));
          await tester.pumpAndSettle();
          expect(container.read(appStateProvider).currentTab, AppTab.profile);
          expect(
            container.read(appStateProvider).currentProfileTab,
            'p-identity',
          );
        },
      );
    }

    testWidgets(
      'All 5 bottom navigation tabs (Wardrobe, Wellness, Stylist, Atelier, Shop) are enabled and switch cleanly',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final strings = AppStrings('en');
        final container = createContainer(languageCode: 'en');
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('en'),
              supportedLocales: AppLanguage.supportedLanguages
                  .map((l) => l.locale)
                  .toList(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const MainShellScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(AppBottomNav.disabledTabs, isEmpty);
        expect(AppBottomNav.disabledTabIndices, isEmpty);
        expect(find.byType(WardrobeTab), findsOneWidget);

        final nav = find.byType(AppBottomNav);

        final tabTargets = <(String, AppTab, Type)>[
          (strings.nWell, AppTab.wellness, WellnessTab),
          (strings.nSty, AppTab.stylist, StylistTab),
          (strings.nAtel, AppTab.atelier, AtelierTab),
          (strings.nShop, AppTab.shop, ShopTab),
          (strings.nWard, AppTab.wardrobe, WardrobeTab),
        ];

        for (final (label, expectedTab, expectedWidget) in tabTargets) {
          await tester.tap(
            find.descendant(of: nav, matching: find.text(label)),
          );
          await tester.pumpAndSettle();

          expect(container.read(appStateProvider).currentTab, expectedTab);
          expect(find.byType(expectedWidget), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'AppDrawer renders enlarged 56px avatar and Latin digits (75%) in English locale without Persian numerals',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 667));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(
              (ref) => _TestAppStateNotifier(
                const AppState(
                  isLoggedIn: true,
                  currentTab: AppTab.wardrobe,
                  userName: 'Sara Ahmadi',
                  loyaltyRank: 'Silver',
                  stylePoints: 624,
                  profileProgress: 0.75,
                  preferences: UserPreferences(
                    fashionThemePalette: 'editorial',
                    brightnessMode: 'light',
                    appLanguage: 'en',
                    appMode: 'simple',
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(localeProvider.notifier).setLanguage('en');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('en'),
              supportedLocales: AppLanguage.supportedLanguages
                  .map((l) => l.locale)
                  .toList(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const Scaffold(body: AppDrawer()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify enlarged 56x56 avatar container
        final avatarFinder = find.ancestor(
          of: find.byType(Gender3dAvatar),
          matching: find.byType(Container),
        );
        expect(avatarFinder, findsWidgets);
        final avatarSize = tester.getSize(avatarFinder.first);
        expect(avatarSize.width, equals(56.0));
        expect(avatarSize.height, equals(56.0));

        // Verify Latin digits (75% and 624) and zero Persian numerals (۰-۹)
        expect(find.text('75%'), findsOneWidget);
        expect(find.textContaining('624'), findsOneWidget);
        expect(find.textContaining(RegExp(r'[۰-۹]')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
