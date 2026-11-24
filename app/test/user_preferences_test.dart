import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/theme_provider.dart';
import 'package:stylemorph/features/profile/data/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/widgets/settings_sub_tab.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  bool saveCalled = false;

  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {
    // Keep test state deterministic
  }

  @override
  Future<bool> saveProfileToFirestore() async {
    saveCalled = true;
    state = state.copyWith(hasUnsavedProfileChanges: false);
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

  group('UserPreferences Model Unit Tests (Task 23)', () {
    test('UserPreferences has exact initial defaults as required', () {
      const prefs = UserPreferences();

      // Fashion Theme Palette: Luxury Editorial
      expect(prefs.fashionThemePalette, 'editorial');
      // Brightness Mode: Light Mode
      expect(prefs.brightnessMode, 'light');
      // App Language: English (EN)
      expect(prefs.appLanguage, 'en');
      // Show Floating Support Widget: OFF (false)
      expect(prefs.showFloatingSupport, false);
      // Show Coin Balance in Header: OFF (false)
      expect(prefs.showHeaderCoins, false);
      // Biometric Lock: OFF (false)
      expect(prefs.biometricLock, false);
      // Auto Data Backup: Weekly (Recommended)
      expect(prefs.autoDataBackup, 'weekly');
      // App Mode: Simple (Default)
      expect(prefs.appMode, 'simple');
      expect(prefs.isSimpleMode, true);
      expect(prefs.isAdvancedMode, false);
    });

    test('UserPreferences serialization toMap and fromMap roundtrip', () {
      const original = UserPreferences(
        fashionThemePalette: 'beige',
        brightnessMode: 'dark',
        appLanguage: 'fa',
        showFloatingSupport: true,
        showHeaderCoins: true,
        biometricLock: true,
        autoDataBackup: 'monthly',
        appMode: 'advanced',
      );

      final map = original.toMap();
      final restored = UserPreferences.fromMap(map);

      expect(restored.fashionThemePalette, 'beige');
      expect(restored.brightnessMode, 'dark');
      expect(restored.appLanguage, 'fa');
      expect(restored.showFloatingSupport, true);
      expect(restored.showHeaderCoins, true);
      expect(restored.biometricLock, true);
      expect(restored.autoDataBackup, 'monthly');
      expect(restored.appMode, 'advanced');
      expect(restored.isAdvancedMode, true);
      expect(restored, original);
    });

    test('AppState initial state enforces default preferences', () {
      const appState = AppState();

      expect(appState.showFloatingSupport, false);
      expect(appState.showHeaderCoins, false);
      expect(appState.preferences.fashionThemePalette, 'editorial');
      expect(appState.preferences.brightnessMode, 'light');
      expect(appState.preferences.appLanguage, 'en');
      expect(appState.preferences.showFloatingSupport, false);
      expect(appState.preferences.showHeaderCoins, false);
      expect(appState.preferences.biometricLock, false);
      expect(appState.preferences.autoDataBackup, 'weekly');
      expect(appState.preferences.appMode, 'simple');
      expect(appState.isSimpleMode, true);
    });
  });

  group('SettingsSubTab UI & Save Changes Widget Tests (Task 23)', () {
    Widget buildTestWidget({
      required _TestAppStateNotifier notifier,
      Locale locale = const Locale('fa'),
    }) {
      return ProviderScope(
        overrides: [
          appStateProvider.overrideWith((ref) => notifier),
          themeProvider.overrideWith((ref) => ThemeNotifier()),
          localeProvider.overrideWith((ref) => LocaleNotifier()),
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
            body: SingleChildScrollView(child: SettingsSubTab()),
          ),
        ),
      );
    }

    testWidgets(
      'Renders all setting controls and Save Changes button in Persian',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final testNotifier = _TestAppStateNotifier(const AppState());

        await tester.pumpWidget(
          buildTestWidget(notifier: testNotifier, locale: const Locale('fa')),
        );
        await tester.pumpAndSettle();

        // Verify sections rendered in Persian
        expect(find.text('تنظیمات و سفارشی‌سازی'), findsOneWidget);
        expect(
          find.text('قالب و پالت رنگی مد (Theme Palette)'),
          findsOneWidget,
        );
        expect(
          find.text('حالت روشنایی (Light / Dark / System)'),
          findsOneWidget,
        );
        expect(find.text('زبان برنامه (Language)'), findsOneWidget);
        expect(find.text('نمایش ویجت شناور پشتیبانی'), findsOneWidget);
        expect(find.text('نمایش موجودی سکه در هدر'), findsOneWidget);
        expect(find.text('پشتیبان‌گیری خودکار داده‌ها'), findsOneWidget);

        // Verify inline duplicate Save Changes button is removed and Logout button is visible
        expect(find.text('ذخیره تغییرات'), findsNothing);
        final logoutBtnFinder = find.text('خروج از حساب کاربری');
        expect(logoutBtnFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Renders all setting controls and Save Changes button in English',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final testNotifier = _TestAppStateNotifier(const AppState());

        await tester.pumpWidget(
          buildTestWidget(notifier: testNotifier, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        // Verify sections rendered in English
        expect(find.text('Settings & Customization'), findsOneWidget);
        expect(find.text('Fashion Theme Palette'), findsOneWidget);
        expect(
          find.text('Brightness Mode (Light / Dark / System)'),
          findsOneWidget,
        );
        expect(find.text('App Language'), findsOneWidget);
        expect(find.text('Show Floating Support Widget'), findsOneWidget);
        expect(find.text('Show Coin Balance in Header'), findsOneWidget);
        expect(find.text('Auto Data Backup'), findsOneWidget);

        // Verify inline duplicate Save Changes button is removed and Logout button is visible
        expect(find.text('Save Changes'), findsNothing);
        final logoutBtnFinder = find.text('Sign Out of Account');
        expect(logoutBtnFinder, findsOneWidget);
      },
    );
  });
}
