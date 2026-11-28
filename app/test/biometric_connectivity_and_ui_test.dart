import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/services/app_update_service.dart';
import 'package:stylemorph/core/services/biometric_service.dart';
import 'package:stylemorph/core/services/connection_health_service.dart';
import 'package:stylemorph/core/services/loyalty_service.dart';
import 'package:stylemorph/core/services/session_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/domain/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/about_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/loyalty_rank_modal.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';

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

class _FakeSessionService extends SessionService {
  _FakeSessionService();

  @override
  Future<void> upsertSession() async {}
}

class _FakeAppUpdateService extends AppUpdateService {
  @override
  Future<AppUpdateCheckResult> checkForUpdate({
    bool manual = false,
    String? currentVersion,
    int? currentBuild,
    String? uidOverride,
    RemoteVersionInfo? remoteOverride,
  }) async {
    return const AppUpdateCheckResult.none();
  }
}

Widget _wrapWithApp({
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = const Locale('en'),
}) {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith(
        (ref) => LocaleNotifier()..setLanguage(locale.languageCode),
      ),
      ...overrides,
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
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BiometricService.resetCacheForTest();
    SharedPreferences.setMockInitialValues({
      'user_theme_palette': 'editorial',
      'user_theme_mode': 'light',
      'app_language_code': 'en',
    });
  });

  group('Step 1 - Biometric Reinstall Reset vs Update Preservation', () {
    test(
      'reconcileSyncedBiometricLock resets to false on fresh reinstall when local binding is missing',
      () async {
        var localBindingPresent = false;
        final service = BiometricService(
          localBindingChecker: () async => localBindingPresent,
          localBindingWriter: (enabled) async {
            localBindingPresent = enabled;
          },
        );

        expect(await service.hasValidLocalBiometricBinding(), isFalse);
        final resolved = await service.reconcileSyncedBiometricLock(true);
        expect(resolved, isFalse);
        expect(await service.isBiometricLockEnabled(), isFalse);
        expect(BiometricService.cachedEnabled, isFalse);
      },
    );

    test(
      'reconcileSyncedBiometricLock preserves true on app update when local binding exists',
      () async {
        var localBindingPresent = true;
        final service = BiometricService(
          localBindingChecker: () async => localBindingPresent,
          localBindingWriter: (enabled) async {
            localBindingPresent = enabled;
          },
        );

        expect(await service.hasValidLocalBiometricBinding(), isTrue);
        final resolved = await service.reconcileSyncedBiometricLock(true);
        expect(resolved, isTrue);
        expect(await service.isBiometricLockEnabled(), isTrue);
        expect(BiometricService.cachedEnabled, isTrue);
      },
    );
  });

  group('Step 2 - ConnectionHealthService & UI Alerts', () {
    test(
      'ConnectionHealthNotifier exposes isServerUnreachable and supports dismiss + retry',
      () async {
        var reachable = false;
        final notifier = ConnectionHealthNotifier(
          probeFn: () async => reachable,
        );

        expect(notifier.state.shouldShowBanner, isFalse);

        final firstResult = await notifier.checkReachability();
        expect(firstResult, isFalse);
        expect(notifier.state.isServerUnreachable, isTrue);
        expect(notifier.state.shouldShowBanner, isTrue);

        notifier.dismissBanner();
        expect(notifier.state.shouldShowBanner, isFalse);

        reachable = true;
        final retryResult = await notifier.checkReachability(
          resetDismissed: true,
        );
        expect(retryResult, isTrue);
        expect(notifier.state.isServerUnreachable, isFalse);
        expect(notifier.state.shouldShowBanner, isFalse);
      },
    );

    testWidgets(
      'MainShellScreen displays dismissible server unreachable banner with Retry button',
      (tester) async {
        final healthNotifier = ConnectionHealthNotifier(
          probeFn: () async => false,
        );

        await tester.pumpWidget(
          _wrapWithApp(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(
                  AppState(
                    isProfileLoaded: true,
                    preferences: const UserPreferences(),
                  ),
                ),
              ),
              sessionServiceProvider.overrideWithValue(_FakeSessionService()),
              connectionHealthProvider.overrideWith((ref) => healthNotifier),
            ],
            child: const MainShellScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('server_unreachable_banner')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('server_unreachable_retry_btn')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('server_unreachable_dismiss_btn')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('server_unreachable_banner')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AboutSubTab displays unreachable notice when update check fails connectivity probe',
      (tester) async {
        final healthNotifier = ConnectionHealthNotifier(
          probeFn: () async => false,
        );

        await tester.pumpWidget(
          _wrapWithApp(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(
                  AppState(
                    isProfileLoaded: true,
                    preferences: const UserPreferences(),
                  ),
                ),
              ),
              appUpdateServiceProvider.overrideWithValue(
                _FakeAppUpdateService(),
              ),
              connectionHealthProvider.overrideWith((ref) => healthNotifier),
            ],
            child: const Scaffold(
              body: SingleChildScrollView(child: AboutSubTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Check for Updates'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('about_update_unreachable_notice')),
          findsOneWidget,
        );
      },
    );
  });

  group('Step 3 - Profile Sidebar & AppDrawer Vertical Layout', () {
    testWidgets(
      'ProfileTab renders all 8+ sidebar tabs without overflow on 375x667 viewport',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 667));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrapWithApp(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(
                  AppState(
                    isProfileLoaded: true,
                    preferences: const UserPreferences(appMode: 'advanced'),
                  ),
                ),
              ),
              sessionServiceProvider.overrideWithValue(_FakeSessionService()),
              allSessionsProvider.overrideWith((ref) => Stream.value(const [])),
            ],
            child: const Scaffold(body: ProfileTab()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('profile_nav_p-identity')), findsOneWidget);
        expect(find.byKey(const Key('profile_nav_p-sessions')), findsOneWidget);
        expect(find.byKey(const Key('profile_nav_p-settings')), findsOneWidget);
        expect(find.byKey(const Key('profile_nav_p-about')), findsOneWidget);

        final companionTop = tester
            .getTopLeft(find.byKey(const Key('profile_nav_p-companion')))
            .dy;
        final sessionsTop = tester
            .getTopLeft(find.byKey(const Key('profile_nav_p-sessions')))
            .dy;
        expect(sessionsTop, greaterThan(companionTop));
      },
    );

    testWidgets(
      'AppDrawer removes CustomScrollView and Spacer so Settings sits directly below Wallet & Plan',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 667));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrapWithApp(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(
                  AppState(
                    isProfileLoaded: true,
                    preferences: const UserPreferences(),
                  ),
                ),
              ),
            ],
            child: const Scaffold(body: AppDrawer()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.byType(CustomScrollView),
          ),
          findsNothing,
        );
        expect(find.text('Wallet & Plan'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      },
    );
  });

  group('Step 4 - Itemized Earned StylePoints Breakdown', () {
    test(
      'LoyaltyService.calculateBreakdown sums identically to calculateStylePoints',
      () {
        final breakdown = LoyaltyService.calculateBreakdown(
          profileProgress: 0.65,
          isEmailVerified: true,
          referralCount: 2,
          aiUsageCount: 5,
          coinActivity: 250,
        );
        final total = LoyaltyService.calculateStylePoints(
          profileProgress: 0.65,
          isEmailVerified: true,
          referralCount: 2,
          aiUsageCount: 5,
          coinActivity: 250,
        );

        expect(breakdown.profileCompletionPercent, equals(65));
        expect(breakdown.profilePoints, equals(195));
        expect(breakdown.emailPoints, equals(100));
        expect(breakdown.referralPoints, equals(300));
        expect(breakdown.aiPoints, equals(50));
        expect(breakdown.walletPoints, equals(25));
        expect(breakdown.totalPoints, equals(total));
        expect(total, equals(670));
      },
    );

    testWidgets(
      'LoyaltyModalSheet renders Your Earned Points breakdown card with category rows',
      (tester) async {
        final breakdown = LoyaltyService.calculateBreakdown(
          profileProgress: 0.5,
          isEmailVerified: true,
          referralCount: 1,
          aiUsageCount: 3,
          coinActivity: 120,
        );

        await tester.pumpWidget(
          _wrapWithApp(
            child: Scaffold(
              body: SingleChildScrollView(
                child: LoyaltyModalSheet(
                  points: breakdown.totalPoints,
                  rank: LoyaltyService.getRank(breakdown.totalPoints),
                  breakdown: breakdown,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('loyalty_earned_points_breakdown_card')),
          findsOneWidget,
        );
        expect(find.text('Your Earned Points'), findsOneWidget);
        expect(
          find.text('+150 pts'),
          findsNWidgets(2),
        ); // Profile 50% & 1 referral
        expect(find.text('+100 pts'), findsOneWidget); // Verified email
        expect(find.text('+30 pts'), findsOneWidget); // 3 AI sessions
        expect(find.text('+12 pts'), findsOneWidget); // 120 coins
      },
    );
  });
}
