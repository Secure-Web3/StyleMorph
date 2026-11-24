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
import 'package:stylemorph/features/profile/domain/user_preferences.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';

class _MockProfileAppStateNotifier extends AppStateNotifier {
  int loadCallCount = 0;

  _MockProfileAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {
    final currentUid = state.loadedUid;
    if (!force &&
        state.isProfileLoaded &&
        (currentUid == null || state.loadedUid == currentUid)) {
      return;
    }
    loadCallCount++;
    state = state.copyWith(
      isProfileLoaded: true,
      loadedUid: currentUid,
      preferences: const UserPreferences(
        fashionThemePalette: 'editorial',
        brightnessMode: 'light',
        appLanguage: 'fa',
        appMode: 'simple',
      ),
    );
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
      'app_language_code': 'fa',
      'user_app_mode': 'simple',
    });
  });

  group('Drawer Preferences Persistence Tests (Step 1 & Step 2)', () {
    testWidgets(
      'Changing AppMode (Simple -> Advanced) in AppDrawer persists immediately and keeps hasUnsavedChanges clean',
      (tester) async {
        final scaffoldKey = GlobalKey<ScaffoldState>();
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith((ref) => AppStateNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
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
              home: Scaffold(
                key: scaffoldKey,
                drawer: const AppDrawer(),
                body: const SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open drawer
        scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).isSimpleMode, true);
        expect(container.read(appStateProvider).hasUnsavedChanges, false);

        // Tap Advanced mode
        final advancedFinder = find.byIcon(Icons.tune_rounded);
        expect(advancedFinder, findsOneWidget);
        await tester.tap(advancedFinder);
        await tester.pumpAndSettle();

        // Verify live AppState & SharedPreferences updated immediately
        expect(container.read(appStateProvider).isAdvancedMode, true);
        expect(
          container.read(appStateProvider).preferences.appMode,
          'advanced',
        );
        expect(container.read(appStateProvider).hasUnsavedChanges, false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_app_mode'), 'advanced');
      },
    );

    testWidgets(
      'Changing Palette in AppDrawer updates themeProvider, AppState.preferences, and SharedPreferences without dirtying form',
      (tester) async {
        final scaffoldKey = GlobalKey<ScaffoldState>();
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith((ref) => AppStateNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
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
              home: Scaffold(
                key: scaffoldKey,
                drawer: const AppDrawer(),
                body: const SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();

        // Initial palette is editorial
        expect(
          container.read(appStateProvider).preferences.fashionThemePalette,
          'editorial',
        );

        // Find beige dot (Color(0xFFD9C3A5))
        final beigeFinder = find.byWidgetPredicate((widget) {
          if (widget is AnimatedContainer &&
              widget.decoration is BoxDecoration) {
            final box = widget.decoration as BoxDecoration;
            return box.color == const Color(0xFFD9C3A5);
          }
          return false;
        });
        expect(beigeFinder, findsOneWidget);

        await tester.tap(beigeFinder);
        await tester.pumpAndSettle();

        // Verify optimistic update on themeProvider & appState.preferences
        expect(container.read(themeProvider).palette, AppPalette.beige);
        expect(
          container.read(appStateProvider).preferences.fashionThemePalette,
          'beige',
        );
        expect(container.read(appStateProvider).hasUnsavedChanges, false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(ThemeNotifier.keyThemePalette), 'beige');
      },
    );

    testWidgets(
      'Tapping Brightness Toggle in AppDrawer cycles mode and persists immediately without dirtying form',
      (tester) async {
        final scaffoldKey = GlobalKey<ScaffoldState>();
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith((ref) => AppStateNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
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
              home: Scaffold(
                key: scaffoldKey,
                drawer: const AppDrawer(),
                body: const SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();

        expect(container.read(themeProvider).mode, ThemeMode.light);
        expect(
          container.read(appStateProvider).preferences.brightnessMode,
          'light',
        );

        // Tap brightness toggle icon (Icons.light_mode_rounded -> dark)
        final brightnessFinder = find.byIcon(Icons.light_mode_rounded);
        expect(brightnessFinder, findsOneWidget);

        await tester.tap(brightnessFinder);
        await tester.pumpAndSettle();

        expect(container.read(themeProvider).mode, ThemeMode.dark);
        expect(
          container.read(appStateProvider).preferences.brightnessMode,
          'dark',
        );
        expect(container.read(appStateProvider).hasUnsavedChanges, false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(ThemeNotifier.keyThemeMode), 'dark');
      },
    );

    testWidgets(
      'Changing Language in AppDrawer updates localeProvider and AppState.preferences without dirtying form',
      (tester) async {
        final scaffoldKey = GlobalKey<ScaffoldState>();
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith((ref) => AppStateNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
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
              home: Scaffold(
                key: scaffoldKey,
                drawer: const AppDrawer(),
                body: const SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();

        // Dropdown selection for English ('English')
        final dropdownFinder = find.byType(DropdownButton<String>);
        expect(dropdownFinder, findsOneWidget);

        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        final englishItem = find.text('English').last;
        await tester.tap(englishItem);
        await tester.pumpAndSettle();

        expect(container.read(localeProvider).code, 'en');
        expect(container.read(appStateProvider).preferences.appLanguage, 'en');
        expect(container.read(appStateProvider).hasUnsavedChanges, false);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(LocaleNotifier.keyAppLanguage), 'en');
      },
    );

    testWidgets(
      'Navigating to ProfileTab when isProfileLoaded == true for same uid does NOT reload stale preferences',
      (tester) async {
        final testNotifier = _MockProfileAppStateNotifier(
          const AppState(
            isProfileLoaded: true,
            loadedUid: 'test_uid_123',
            preferences: UserPreferences(
              fashionThemePalette: 'beige',
              brightnessMode: 'dark',
              appLanguage: 'tr',
              appMode: 'advanced',
            ),
          ),
        );
        testNotifier.loadCallCount = 0; // reset after initial constructor call

        final container = ProviderContainer(
          overrides: [appStateProvider.overrideWith((ref) => testNotifier)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
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
              home: const Scaffold(body: ProfileTab()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify that loadProfileFromFirestore was NOT triggered because profile is already loaded for same uid
        expect(testNotifier.loadCallCount, 0);

        // Verify newly chosen preferences remain intact and were not overwritten
        final currentPrefs = container.read(appStateProvider).preferences;
        expect(currentPrefs.fashionThemePalette, 'beige');
        expect(currentPrefs.brightnessMode, 'dark');
        expect(currentPrefs.appLanguage, 'tr');
        expect(currentPrefs.appMode, 'advanced');
      },
    );

    test(
      'loadProfileFromFirestore({bool force = false}) returns immediately when already loaded for current uid',
      () async {
        final notifier = AppStateNotifier();
        notifier.state = notifier.state.copyWith(
          isProfileLoaded: true,
          loadedUid: 'user_xyz',
          preferences: const UserPreferences(
            fashionThemePalette: 'slate',
            brightnessMode: 'dark',
            appLanguage: 'ar',
            appMode: 'advanced',
          ),
        );

        // Without force: should return immediately and not alter state
        await notifier.loadProfileFromFirestore(force: false);
        expect(notifier.state.preferences.fashionThemePalette, 'slate');
        expect(notifier.state.preferences.brightnessMode, 'dark');
        expect(notifier.state.preferences.appLanguage, 'ar');
        expect(notifier.state.preferences.appMode, 'advanced');
        expect(notifier.state.hasUnsavedChanges, false);
      },
    );
  });
}
