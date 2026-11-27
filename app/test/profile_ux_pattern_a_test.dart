import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/services/biometric_service.dart';
import 'package:stylemorph/core/services/two_factor_service.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/theme_provider.dart';
import 'package:stylemorph/core/widgets/app_switch.dart';
import 'package:stylemorph/core/widgets/brand_wordmark.dart';
import 'package:stylemorph/features/auth/presentation/biometric_lock_screen.dart';
import 'package:stylemorph/features/auth/presentation/widgets/two_factor_verify_screen.dart';
import 'package:stylemorph/features/profile/domain/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/settings_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/unsaved_changes_dialog.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier([AppState? initial]) : super() {
    if (initial != null) {
      state = initial;
    }
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {}

  @override
  Future<bool> saveProfileToFirestore() async {
    state = state.copyWith(hasUnsavedProfileChanges: false);
    return true;
  }
}

class _FakeBiometricService extends BiometricService {
  final bool supported;
  final bool enabled;

  _FakeBiometricService({this.supported = true, this.enabled = true});

  @override
  Future<bool> isBiometricAvailable() async => supported;

  @override
  Future<bool> isBiometricLockEnabled() async => enabled;

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}

Widget _wrapWithApp({
  required Widget child,
  _TestAppStateNotifier? notifier,
  List<Override> extraOverrides = const [],
  bool isDark = false,
}) {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: isDark,
  );
  return ProviderScope(
    overrides: [
      if (notifier != null) appStateProvider.overrideWith((ref) => notifier),
      themeProvider.overrideWith((ref) => ThemeNotifier()),
      localeProvider.overrideWith((ref) => LocaleNotifier()),
      ...extraOverrides,
    ],
    child: MaterialApp(
      theme: testTheme,
      locale: const Locale('fa'),
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
    BiometricService.resetCacheForTest();
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 1: BiometricService synchronous cache prevents toggle jump', () {
    test('BiometricService.cachedEnabled updates on read and write', () async {
      SharedPreferences.setMockInitialValues({'biometric_lock_enabled': true});
      final service = BiometricService();

      expect(BiometricService.cachedEnabled, isNull);
      final enabled = await service.isBiometricLockEnabled();
      expect(enabled, isTrue);
      expect(BiometricService.cachedEnabled, isTrue);

      await service.setBiometricLockEnabled(false);
      expect(BiometricService.cachedEnabled, isFalse);
    });

    testWidgets(
      'SettingsSubTab initializes biometric switch to true on first frame when cachedEnabled is true',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        SharedPreferences.setMockInitialValues({
          'biometric_lock_enabled': true,
        });
        final realService = BiometricService();
        await realService.isBiometricLockEnabled();
        expect(BiometricService.cachedEnabled, isTrue);

        final fakeService = _FakeBiometricService(
          supported: true,
          enabled: true,
        );

        await tester.pumpWidget(
          _wrapWithApp(
            notifier: _TestAppStateNotifier(const AppState()),
            extraOverrides: [
              biometricServiceProvider.overrideWithValue(fakeService),
            ],
            child: const SingleChildScrollView(child: SettingsSubTab()),
          ),
        );

        // First frame (before pumpAndSettle): biometric switch must already be true.
        final biometricTile = find.ancestor(
          of: find.text('قفل بیومتریک (اثر انگشت / Face ID)'),
          matching: find.byType(AppSwitchTile),
        );
        expect(biometricTile, findsOneWidget);
        final switchWidget = tester.widget<AppSwitchTile>(biometricTile);
        expect(switchWidget.value, isTrue);

        await tester.pumpAndSettle();
        final settledWidget = tester.widget<AppSwitchTile>(biometricTile);
        expect(settledWidget.value, isTrue);
      },
    );
  });

  group('Step 2: Profile sidebar sub-tab ordering', () {
    testWidgets(
      'Profile sidebar renders Identity -> AI Anatomy -> Media in exact order',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final notifier = _TestAppStateNotifier(const AppState());
        await tester.pumpWidget(
          _wrapWithApp(notifier: notifier, child: const ProfileTab()),
        );
        await tester.pumpAndSettle();

        final identityY = tester
            .getTopLeft(find.byKey(const Key('profile_nav_p-identity')))
            .dy;
        final anatomyY = tester
            .getTopLeft(find.byKey(const Key('profile_nav_p-ai')))
            .dy;
        final mediaY = tester
            .getTopLeft(find.byKey(const Key('profile_nav_p-gallery')))
            .dy;

        expect(identityY, lessThan(anatomyY));
        expect(anatomyY, lessThan(mediaY));
      },
    );
  });

  group('Step 3: Pattern-A Save Behavior in Profile', () {
    testWidgets(
      'Sticky Save Bar is shown on Identity & AI Anatomy and hidden on Settings',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final notifier = _TestAppStateNotifier(
          const AppState(currentProfileTab: 'p-identity'),
        );
        await tester.pumpWidget(
          _wrapWithApp(notifier: notifier, child: const ProfileTab()),
        );
        await tester.pumpAndSettle();

        // Identity has Sticky Save Bar
        expect(find.text('تغییراتی ثبت نشده'), findsOneWidget);

        // Switch to AI Anatomy -> Sticky Save Bar still present
        await tester.tap(find.byKey(const Key('profile_nav_p-ai')));
        await tester.pumpAndSettle();
        expect(find.text('تغییراتی ثبت نشده'), findsOneWidget);

        // Switch to Settings -> Sticky Save Bar is hidden
        await tester.tap(find.byKey(const Key('profile_nav_p-settings')));
        await tester.pumpAndSettle();
        expect(find.text('تغییراتی ثبت نشده'), findsNothing);
        expect(find.text('ذخیره تغییرات'), findsNothing);
      },
    );

    testWidgets(
      'Toggling settings auto-saves without dirtying profile or triggering exit dialog',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final notifier = _TestAppStateNotifier(
          const AppState(
            currentProfileTab: 'p-settings',
            preferences: UserPreferences(showFloatingSupport: true),
          ),
        );
        await tester.pumpWidget(
          _wrapWithApp(notifier: notifier, child: const ProfileTab()),
        );
        await tester.pumpAndSettle();

        final advancedModeBtn = find.text('پیشرفته (حرفه‌ای)');
        expect(advancedModeBtn, findsOneWidget);
        await tester.tap(advancedModeBtn);
        await tester.pumpAndSettle();

        expect(notifier.state.isAdvancedMode, isTrue);
        expect(notifier.state.hasUnsavedProfileChanges, isFalse);
        expect(find.text('ذخیره تغییرات'), findsNothing);

        // Verify remaining auto-save preference methods keep hasUnsavedProfileChanges clean
        await notifier.toggleFloatingSupport(false, persistImmediately: true);
        await notifier.toggleHeaderCoins(false, persistImmediately: true);
        await notifier.toggleShowEmailInHeader(true, persistImmediately: true);
        await notifier.setAutoDataBackup('monthly', persistImmediately: true);
        await tester.pumpAndSettle();

        expect(notifier.state.showFloatingSupport, isFalse);
        expect(notifier.state.showHeaderCoins, isFalse);
        expect(notifier.state.preferences.showEmailInHeader, isTrue);
        expect(notifier.state.preferences.autoDataBackup, 'monthly');
        expect(notifier.state.hasUnsavedProfileChanges, isFalse);

        // Switching away from Settings never triggers UnsavedChangesDialog
        await tester.tap(find.byKey(const Key('profile_nav_p-identity')));
        await tester.pumpAndSettle();
        expect(find.byType(UnsavedChangesDialog), findsNothing);
        expect(notifier.state.currentProfileTab, 'p-identity');
      },
    );
  });

  group('Step 4: BrandWordmark in 2FA & Biometric Lock UI', () {
    testWidgets(
      'TwoFactorVerifyScreen renders BrandWordmark in Light and Dark themes',
      (tester) async {
        for (final isDark in [false, true]) {
          await tester.pumpWidget(
            _wrapWithApp(
              isDark: isDark,
              child: const TwoFactorVerifyScreen(
                uid: 'u1',
                email: 'mina@stylemorph.style',
                config: TwoFactorConfig(
                  enabled: true,
                  method: TwoFactorMethod.totp,
                  totpSecret: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(BrandWordmark), findsOneWidget);
          expect(find.text(BrandWordmark.brandText), findsOneWidget);
        }
      },
    );

    testWidgets('BiometricLockScreen renders BrandWordmark', (tester) async {
      await tester.pumpWidget(
        _wrapWithApp(
          extraOverrides: [
            biometricServiceProvider.overrideWithValue(
              _FakeBiometricService(supported: true, enabled: true),
            ),
          ],
          child: const BiometricLockScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrandWordmark), findsOneWidget);
      expect(find.text(BrandWordmark.brandText), findsOneWidget);
    });
  });
}
