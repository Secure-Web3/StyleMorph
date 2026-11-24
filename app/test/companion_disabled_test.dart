import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore({bool force = false}) async {
    // Keep initialState intact for deterministic tests
  }
}

void main() {
  final testTheme = AppTheme.buildTheme(
    palette: AppPalette.editorial,
    isDark: false,
  );

  Widget buildTestableWidget({
    required Widget child,
    Locale locale = const Locale('fa'),
    AppState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          appStateProvider.overrideWith(
            (ref) => _TestAppStateNotifier(initialState),
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
        home: Scaffold(body: child),
      ),
    );
  }

  group('Temporarily Disable AI Companion Sub-Tab Tests (Task 22)', () {
    testWidgets(
      'Profile sidebar displays Companion tab with Coming Soon badge and disabled state in Persian',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = const AppState(
          currentTab: AppTab.profile,
          currentProfileTab: 'p-identity',
        );

        await tester.pumpWidget(
          buildTestableWidget(initialState: state, child: const ProfileTab()),
        );
        await tester.pumpAndSettle();

        // Find the Companion tab text in Persian ('شخصیت همراه')
        final companionTextFinder = find.text('شخصیت همراه');
        expect(companionTextFinder, findsOneWidget);

        final companionTabFinder = find.ancestor(
          of: companionTextFinder,
          matching: find.byType(InkWell),
        );
        expect(companionTabFinder, findsOneWidget);

        // Verify "به زودی" badge is rendered inside this companion tab button
        final badgeFinder = find.descendant(
          of: companionTabFinder,
          matching: find.text('به زودی'),
        );
        expect(badgeFinder, findsOneWidget);

        // Verify the tab is wrapped with reduced opacity (muted disabled appearance)
        final opacityFinder = find.ancestor(
          of: companionTextFinder,
          matching: find.byType(Opacity),
        );
        expect(opacityFinder, findsWidgets);
        final opacityWidget = tester.widget<Opacity>(opacityFinder.first);
        expect(opacityWidget.opacity, lessThan(1.0));

        // Attempt to tap the Companion tab
        await tester.tap(companionTabFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Ensure that tapping does NOT switch the active profile tab to 'p-companion'
        final element = tester.element(find.byType(ProfileTab));
        final container = ProviderScope.containerOf(element);
        expect(
          container.read(appStateProvider).currentProfileTab,
          'p-identity',
        );
      },
    );

    testWidgets(
      'Profile sidebar displays Companion tab with Coming Soon badge in English',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = const AppState(
          currentTab: AppTab.profile,
          currentProfileTab: 'p-identity',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            locale: const Locale('en'),
            initialState: state,
            child: const ProfileTab(),
          ),
        );
        await tester.pumpAndSettle();

        // In English, text is 'Companion'
        final companionTextFinder = find.text('Companion');
        expect(companionTextFinder, findsOneWidget);

        final companionTabFinder = find.ancestor(
          of: companionTextFinder,
          matching: find.byType(InkWell),
        );
        expect(companionTabFinder, findsOneWidget);

        // Badge inside companion tab is 'Coming Soon'
        final badgeFinder = find.descendant(
          of: companionTabFinder,
          matching: find.text('Coming Soon'),
        );
        expect(badgeFinder, findsOneWidget);

        // Tap attempt does not navigate
        await tester.tap(companionTabFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(ProfileTab));
        final container = ProviderScope.containerOf(element);
        expect(
          container.read(appStateProvider).currentProfileTab,
          'p-identity',
        );
      },
    );

    testWidgets(
      'AppDrawer displays Companion item with Coming Soon badge and disabled state',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = const AppState(
          currentTab: AppTab.profile,
          currentProfileTab: 'p-identity',
        );
        final scaffoldKey = GlobalKey<ScaffoldState>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appStateProvider.overrideWith(
                (ref) => _TestAppStateNotifier(state),
              ),
            ],
            child: MaterialApp(
              theme: testTheme,
              locale: const Locale('fa'),
              supportedLocales: const [Locale('fa'), Locale('en')],
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

        // Open the drawer
        scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();

        // Verify Companion item title and "به زودی" badge are visible in Drawer
        final companionTextFinder = find.text('شخصیت همراه');
        expect(companionTextFinder, findsOneWidget);

        final comingSoonFinder = find.text('به زودی');
        expect(comingSoonFinder, findsWidgets);

        // Tap on Companion drawer item
        await tester.tap(companionTextFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify state has not changed to 'p-companion'
        final element = tester.element(find.byType(AppDrawer));
        final container = ProviderScope.containerOf(element);
        expect(
          container.read(appStateProvider).currentProfileTab,
          'p-identity',
        );
      },
    );
  });
}
