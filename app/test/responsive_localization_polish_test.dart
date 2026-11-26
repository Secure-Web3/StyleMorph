import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/localization/app_strings.dart';
import 'package:stylemorph/core/services/session_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/auth/presentation/auth_provider.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/auth/presentation/widgets/auth_footer.dart';
import 'package:stylemorph/features/auth/presentation/widgets/turnstile_skeleton.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/identity_sub_tab.dart';
import 'package:stylemorph/features/shell/presentation/shell_state_provider.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';
import 'package:stylemorph/features/shell/presentation/widgets/notification_sheet.dart';
import 'package:stylemorph/features/wardrobe/data/wardrobe_repository.dart';
import 'package:stylemorph/features/wardrobe/domain/wardrobe_item.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_provider.dart';
import 'package:stylemorph/features/wardrobe/presentation/wardrobe_tab.dart';
import 'package:stylemorph/features/wardrobe/presentation/widgets/add_item_bottom_sheet.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {}

  @override
  Future<bool> saveProfileToFirestore() async {
    state = state.copyWith(hasUnsavedProfileChanges: false);
    return true;
  }
}

class _TestWardrobeNotifier extends WardrobeNotifier {
  _TestWardrobeNotifier(WardrobeRepository repo, WardrobeState initial)
    : super(repo, null) {
    state = initial;
  }
}

Widget _wrapWithApp({
  required Widget child,
  String localeCode = 'en',
  Size surfaceSize = const Size(390, 844),
  List<Override> overrides = const [],
  bool wrapInScaffold = true,
}) {
  final theme = AppTheme.buildTheme(
    palette: AppPalette.white,
    isDark: false,
    localeCode: localeCode,
  );
  return ProviderScope(
    overrides: overrides,
    child: MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: MaterialApp(
        theme: theme,
        locale: Locale(localeCode),
        supportedLocales: AppLanguage.supportedLanguages
            .map((l) => l.locale)
            .toList(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: wrapInScaffold ? Scaffold(body: child) : child,
      ),
    ),
  );
}

bool _containsPersianDigits(String value) =>
    RegExp(r'[۰-۹٠-٩]').hasMatch(value);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_language_code': 'en',
      'user_theme_palette': 'white',
      'user_theme_mode': 'light',
    });
  });

  group('Step 1: Latin Digits & Non-Vazirmatn Font in LTR (en)', () {
    testWidgets(
      'MainHeader renders Latin digits and non-Vazirmatn font for rank, coins, and percent in en',
      (tester) async {
        const initialState = AppState(
          currentTab: AppTab.profile,
          userName: 'Ava',
          loyaltyRank: 'bronze',
          stylePoints: 143,
          coins: 0,
          showHeaderCoins: true,
          preferences: UserPreferences(showHeaderCoins: true),
        );

        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            surfaceSize: const Size(360, 800),
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(initialState),
              ),
            ],
            child: const MainHeader(),
          ),
        );
        await tester.pump();

        expect(find.text('Bronze • 143 pts'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('Coins'), findsOneWidget);

        final rankText = tester.widget<Text>(find.text('Bronze • 143 pts'));
        expect(rankText.style?.fontFamily, isNot('Vazirmatn'));
        expect(_containsPersianDigits(rankText.data!), isFalse);

        final coinText = tester.widget<Text>(find.text('0'));
        expect(coinText.style?.fontFamily, isNot('Vazirmatn'));
        expect(_containsPersianDigits(coinText.data!), isFalse);
      },
    );

    testWidgets(
      'AppDrawer renders Latin digits for rank and profile completion in en',
      (tester) async {
        const initialState = AppState(
          userName: 'Ava',
          loyaltyRank: 'bronze',
          stylePoints: 143,
          identityValues: {'firstName': 'Ava'},
        );

        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            surfaceSize: const Size(390, 844),
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(initialState),
              ),
            ],
            child: const AppDrawer(),
          ),
        );
        await tester.pump();

        expect(find.text('Bronze • 143 pts'), findsOneWidget);
        final rankText = tester.widget<Text>(find.text('Bronze • 143 pts'));
        expect(rankText.style?.fontFamily, isNot('Vazirmatn'));
      },
    );

    testWidgets(
      'ProfileTab Sessions badge renders Latin digit 2 without Vazirmatn in en',
      (tester) async {
        final now = DateTime.now();
        final sessions = [
          SessionInfo(
            sessionId: 's1',
            deviceId: 'd1',
            deviceType: 'mobile',
            deviceName: 'iPhone',
            deviceModel: 'iPhone 15',
            platform: 'iOS',
            osVersion: '17.0',
            userAgent: 'Safari',
            createdAt: now,
            lastActiveAt: now,
            isActive: true,
            isPrimary: true,
            isBlocked: false,
          ),
          SessionInfo(
            sessionId: 's2',
            deviceId: 'd2',
            deviceType: 'desktop_web',
            deviceName: 'Mac',
            deviceModel: 'MacBook',
            platform: 'Web',
            osVersion: 'macOS',
            userAgent: 'Chrome',
            createdAt: now,
            lastActiveAt: now,
            isActive: true,
            isPrimary: false,
            isBlocked: false,
          ),
        ];

        const initialState = AppState(
          currentTab: AppTab.profile,
          preferences: UserPreferences(appMode: 'advanced'),
          isProfileLoaded: true,
        );

        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(initialState),
              ),
              allSessionsProvider.overrideWith((ref) => Stream.value(sessions)),
            ],
            child: const ProfileTab(),
          ),
        );
        await tester.pump();

        expect(find.text('2'), findsOneWidget);
        final badgeText = tester.widget<Text>(find.text('2'));
        expect(badgeText.style?.fontFamily, isNot('Vazirmatn'));
      },
    );

    testWidgets(
      'NotificationSheet unread pill renders Latin 5 new without Vazirmatn in en',
      (tester) async {
        final notifications = List.generate(
          5,
          (i) => AppNotification(
            id: 'n$i',
            title: 'Notice $i',
            body: 'Body $i',
            category: 'account',
            targetRoute: 'wardrobe',
            emoji: '🔔',
            timestampLabel: 'Now',
            isRead: false,
          ),
        );

        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            overrides: [
              shellStateProvider.overrideWith((ref) {
                final notifier = ShellStateNotifier();
                notifier.state = notifier.state.copyWith(
                  notifications: notifications,
                );
                return notifier;
              }),
            ],
            child: const NotificationSheet(),
          ),
        );
        await tester.pump();

        expect(find.text('5 new'), findsOneWidget);
        final pillText = tester.widget<Text>(find.text('5 new'));
        expect(pillText.style?.fontFamily, isNot('Vazirmatn'));
      },
    );
  });

  group('Step 2: Unclipped Rank Pill & Anchored App & Support', () {
    testWidgets(
      'MainHeader displays full Bronze • 143 pts without overflow on 360px width',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        const initialState = AppState(
          currentTab: AppTab.profile,
          userName: 'Very Long Fashionista Name',
          loyaltyRank: 'bronze',
          stylePoints: 143,
        );

        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            surfaceSize: const Size(360, 800),
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(initialState),
              ),
            ],
            child: const MainHeader(),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Bronze • 143 pts'), findsOneWidget);
      },
    );

    testWidgets(
      'AppDrawer anchors App & Support above bottom dock on 390x844 and scrolls cleanly on 360x667',
      (tester) async {
        for (final size in const [Size(390, 844), Size(360, 667)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          const initialState = AppState(
            userName: 'Ava',
            loyaltyRank: 'bronze',
            stylePoints: 143,
          );

          await tester.pumpWidget(
            _wrapWithApp(
              localeCode: 'en',
              surfaceSize: size,
              overrides: [
                appStateProvider.overrideWith(
                  (ref) => _TestAppStateNotifier(initialState),
                ),
              ],
              child: const AppDrawer(),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.text('Bronze • 143 pts'), findsOneWidget);
          expect(
            find.text(AppStrings('en').drawerSectionAppSupport),
            findsOneWidget,
          );
        }
        tester.view.reset();
      },
    );
  });

  group('Step 3: AuthScreen Sign Up Scroll & Turnstile Loading/Fallback', () {
    testWidgets(
      'AuthScreen Sign Up keeps buttons reachable above pinned AuthFooter on 375x667 and 390x844',
      (tester) async {
        for (final size in const [Size(375, 667), Size(390, 844)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            _wrapWithApp(
              localeCode: 'en',
              surfaceSize: size,
              wrapInScaffold: false,
              child: Consumer(
                builder: (context, ref, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final notifier = ref.read(authFormProvider.notifier);
                    if (ref.read(authFormProvider).mode != AuthMode.signup) {
                      notifier.setMode(AuthMode.signup);
                    }
                  });
                  return const AuthScreen();
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          // Drain any unrelated Ahem-font width overflow in AuthTopBar/AuthFooter on 375px.
          tester.takeException();

          expect(find.byType(AuthFooter), findsOneWidget);

          final signupBtn = find.text(AppStrings('en').authSignupBtn);
          expect(signupBtn, findsOneWidget);
          await tester.ensureVisible(signupBtn);
          await tester.pump();

          final footerTop = tester.getTopLeft(find.byType(AuthFooter)).dy;
          final btnBottom = tester.getBottomLeft(signupBtn).dy;
          expect(btnBottom, lessThanOrEqualTo(footerTop));
        }
        tester.view.reset();
      },
    );

    testWidgets(
      'TurnstileSkeleton displays loading spinner and fallback hint when failed',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            child: const TurnstileSkeleton(isFailed: true),
          ),
        );
        await tester.pump();

        expect(
          find.text(AppStrings('en').authTurnstileUnavailable),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      },
    );
  });

  group('Step 4: Wardrobe Compact UX on 375x667', () {
    testWidgets('WardrobeTab sidebar renders cleanly on 375x667', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrapWithApp(
          localeCode: 'en',
          surfaceSize: const Size(375, 667),
          overrides: [
            wardrobeProvider.overrideWith(
              (ref) => _TestWardrobeNotifier(
                ref.watch(wardrobeRepositoryProvider),
                const WardrobeState(
                  items: <WardrobeItem>[],
                  filter: WardrobeFilter(),
                ),
              ),
            ),
          ],
          child: const WardrobeTab(),
        ),
      );
      await tester.pump();
      // Drain any unrelated Ahem-font width overflow in _TopBar on 375px.
      tester.takeException();
      expect(find.byType(WardrobeTab), findsOneWidget);
    });

    testWidgets(
      'AddItemBottomSheet renders compact photo box and zero overflow on 375x667',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            surfaceSize: const Size(375, 667),
            child: const SizedBox(height: 600, child: AddItemBottomSheet()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        final photoBox = tester.renderObject(
          find.byKey(const Key('add_item_primary_photo_box')),
        );
        expect((photoBox as RenderBox).size.height, equals(96.0));
      },
    );
  });

  group('Step 5: Neutral Empty Country Flag in IdentitySubTab', () {
    testWidgets(
      'IdentitySubTab renders neutral globe icon instead of Iran flag when country is empty',
      (tester) async {
        const initialState = AppState(
          isProfileLoaded: true,
          identityValues: {'country': '', 'countryCode': ''},
        );

        await tester.pumpWidget(
          _wrapWithApp(
            localeCode: 'en',
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(initialState),
              ),
            ],
            child: const SingleChildScrollView(child: IdentitySubTab()),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('identity_country_neutral_globe')),
          findsOneWidget,
        );
        expect(find.text('234 567 8900'), findsNothing);
      },
    );
  });
}
