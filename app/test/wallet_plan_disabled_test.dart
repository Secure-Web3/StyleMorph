import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/shell/presentation/widgets/main_header.dart';

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(AppState initial) : super() {
    state = initial;
  }

  @override
  Future<void> loadProfileFromFirestore() async {
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
          appStateProvider
              .overrideWith((ref) => _TestAppStateNotifier(initialState)),
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
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Temporarily Disable Wallet & Plan Sub-Tab Tests (Task 20)', () {
    testWidgets('Profile sidebar displays Wallet & Plan tab with Coming Soon badge and disabled state in Persian',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        currentTab: AppTab.profile,
        currentProfileTab: 'p-identity',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const ProfileTab(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Wallet & Plan tab text in Persian ('مالی & پلن')
      final walletTextFinder = find.text('مالی & پلن');
      expect(walletTextFinder, findsOneWidget);

      final walletTabFinder = find.ancestor(
        of: walletTextFinder,
        matching: find.byType(InkWell),
      );
      expect(walletTabFinder, findsOneWidget);

      // Verify "به زودی" badge is rendered inside this wallet tab button
      final badgeFinder = find.descendant(
        of: walletTabFinder,
        matching: find.text('به زودی'),
      );
      expect(badgeFinder, findsOneWidget);

      // Verify the tab is wrapped with reduced opacity (muted disabled appearance)
      final opacityFinder = find.ancestor(
        of: walletTextFinder,
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsWidgets);
      final opacityWidget = tester.widget<Opacity>(opacityFinder.first);
      expect(opacityWidget.opacity, lessThan(1.0));

      // Attempt to tap the Wallet & Plan tab
      await tester.tap(walletTabFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Ensure that tapping does NOT switch the active profile tab to 'p-wallet'
      final element = tester.element(find.byType(ProfileTab));
      final container = ProviderScope.containerOf(element);
      expect(container.read(appStateProvider).currentProfileTab, 'p-identity');
    });

    testWidgets('Profile sidebar displays Wallet & Plan tab with Coming Soon badge in English',
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

      // In English, text is 'Wallet & Plan'
      final walletTextFinder = find.text('Wallet & Plan');
      expect(walletTextFinder, findsOneWidget);

      final walletTabFinder = find.ancestor(
        of: walletTextFinder,
        matching: find.byType(InkWell),
      );
      expect(walletTabFinder, findsOneWidget);

      // Badge inside wallet tab is 'Coming Soon'
      final badgeFinder = find.descendant(
        of: walletTabFinder,
        matching: find.text('Coming Soon'),
      );
      expect(badgeFinder, findsOneWidget);

      // Tap attempt does not navigate
      await tester.tap(walletTabFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(ProfileTab));
      final container = ProviderScope.containerOf(element);
      expect(container.read(appStateProvider).currentProfileTab, 'p-identity');
    });

    testWidgets('Header Coins badge has tap navigation disabled and does not open Wallet tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const AppState(
        currentTab: AppTab.profile,
        currentProfileTab: 'p-identity',
        showHeaderCoins: true,
        coins: 450,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: state,
          child: const Scaffold(
            appBar: MainHeader(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Coins chip should be visible in MainHeader with Persian coins label 'سکه' and amount '۴۵۰'
      final coinLabelFinder = find.text('سکه');
      expect(coinLabelFinder, findsOneWidget);

      final coinAmountFinder = find.text('۴۵۰');
      expect(coinAmountFinder, findsOneWidget);

      final coinsChipFinder = find.ancestor(
        of: coinLabelFinder,
        matching: find.byType(InkWell),
      );
      expect(coinsChipFinder, findsOneWidget);

      // Tap on the coins chip
      await tester.tap(coinsChipFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Ensure that tapping header coins chip does NOT switch profile tab to 'p-wallet'
      final element = tester.element(find.byType(MainHeader));
      final container = ProviderScope.containerOf(element);
      expect(container.read(appStateProvider).currentProfileTab, 'p-identity');
    });
  });
}
