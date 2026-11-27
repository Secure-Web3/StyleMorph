import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stylemorph/core/config/app_build_info.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/about_sub_tab.dart';
import 'package:stylemorph/features/profile/presentation/widgets/unsaved_changes_dialog.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';

class _FixedLocaleNotifier extends LocaleNotifier {
  _FixedLocaleNotifier(AppLanguage lang) : super() {
    state = lang;
  }
}

ProviderContainer _createTestContainer({
  AppTab initialTab = AppTab.wardrobe,
  String languageCode = 'fa',
  bool hasUnsavedProfileChanges = false,
  String currentProfileTab = 'p-identity',
}) {
  final language = AppLanguage.fromCode(languageCode);
  return ProviderContainer(
    overrides: [
      localeProvider.overrideWith((ref) => _FixedLocaleNotifier(language)),
      appStateProvider.overrideWith(
        (ref) => AppStateNotifier()
          ..state = AppState(
            currentTab: initialTab,
            currentProfileTab: currentProfileTab,
            hasUnsavedProfileChanges: hasUnsavedProfileChanges,
            userName: 'Test User',
            userHandle: '@test_user',
            stylePoints: 250,
            coins: 120,
          ),
      ),
    ],
  );
}

Widget _wrapWithApp({
  required ProviderContainer container,
  required AppLanguage language,
  required Widget child,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: language.locale,
      supportedLocales: AppLanguage.supportedLanguages
          .map((l) => l.locale)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(extensions: const [AppColors.lightWhite]),
      builder: (context, innerChild) => ShadTheme(
        data: AppTheme.buildShadTheme(palette: AppPalette.white, isDark: false),
        child: Directionality(
          textDirection: language.textDirection,
          child: innerChild ?? const SizedBox.shrink(),
        ),
      ),
      home: child,
    ),
  );
}

void main() {
  group('AppBuildInfo Unit Tests', () {
    test(
      'compareSemVer compares MAJOR.MINOR.PATCH and prefixes accurately',
      () {
        expect(AppBuildInfo.compareSemVer('1.0.0', '1.0.0'), 0);
        expect(AppBuildInfo.compareSemVer('v1.0.0', '1.0.1'), lessThan(0));
        expect(AppBuildInfo.compareSemVer('1.2.0', '1.10.0'), lessThan(0));
        expect(AppBuildInfo.compareSemVer('2.0.0', '1.9.9'), greaterThan(0));
        expect(AppBuildInfo.compareSemVer('1.0.0+10', '1.0.0'), 0);
      },
    );

    test('isUpdateAvailable detects newer build or newer SemVer', () {
      expect(
        AppBuildInfo.isUpdateAvailable(
          remoteVersion: '1.0.0',
          remoteBuild: 100,
          currentVersion: '1.0.0',
          currentBuild: 100,
        ),
        isFalse,
      );
      expect(
        AppBuildInfo.isUpdateAvailable(
          remoteVersion: '1.0.0',
          remoteBuild: 105,
          currentVersion: '1.0.0',
          currentBuild: 100,
        ),
        isTrue,
      );
      expect(
        AppBuildInfo.isUpdateAvailable(
          remoteVersion: '1.1.0',
          remoteBuild: 100,
          currentVersion: '1.0.0',
          currentBuild: 100,
        ),
        isTrue,
      );
    });

    test('isForceUpdateRequired respects minRequiredBuild threshold', () {
      expect(
        AppBuildInfo.isForceUpdateRequired(
          minRequiredBuild: 0,
          currentBuild: 100,
        ),
        isFalse,
      );
      expect(
        AppBuildInfo.isForceUpdateRequired(
          minRequiredBuild: 100,
          currentBuild: 100,
        ),
        isFalse,
      );
      expect(
        AppBuildInfo.isForceUpdateRequired(
          minRequiredBuild: 120,
          currentBuild: 100,
        ),
        isTrue,
      );
    });
  });

  group('AboutSubTab Versioning Widget Tests', () {
    testWidgets('AboutSubTab renders AppBuildInfo version and build in en', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final language = AppLanguage.fromCode('en');
      final container = _createTestContainer(languageCode: 'en');
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container: container,
          language: language,
          child: const Scaffold(
            body: SingleChildScrollView(child: AboutSubTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('v${AppBuildInfo.appVersion}'), findsOneWidget);
      expect(find.text('Build ${AppBuildInfo.buildNumber}'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
    });
  });

  group('MainShellScreen RTL/LTR Swipe & Drawer Edge-Swipe Tests', () {
    testWidgets(
      'LTR (en): horizontal swipe switches module from Wardrobe to Wellness',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final language = AppLanguage.fromCode('en');
        final container = _createTestContainer(
          initialTab: AppTab.wardrobe,
          languageCode: 'en',
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(
            container: container,
            language: language,
            child: const MainShellScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).currentTab, AppTab.wardrobe);

        // In LTR, swiping right-to-left advances to the next module (Wellness)
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).currentTab, AppTab.wellness);
      },
    );

    testWidgets(
      'RTL (fa): horizontal swipe switches module from Wardrobe to Wellness',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final language = AppLanguage.fromCode('fa');
        final container = _createTestContainer(
          initialTab: AppTab.wardrobe,
          languageCode: 'fa',
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(
            container: container,
            language: language,
            child: const MainShellScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).currentTab, AppTab.wardrobe);

        // In RTL, swiping left-to-right advances to the next module (Wellness)
        await tester.drag(find.byType(PageView), const Offset(300, 0));
        await tester.pumpAndSettle();

        expect(container.read(appStateProvider).currentTab, AppTab.wellness);
      },
    );

    testWidgets('LTR (en): start-edge overscroll on Wardrobe opens AppDrawer', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final language = AppLanguage.fromCode('en');
      final container = _createTestContainer(
        initialTab: AppTab.wardrobe,
        languageCode: 'en',
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container: container,
          language: language,
          child: const MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsNothing);

      // In LTR, dragging left-to-right at index 0 overscrolls past start edge
      await tester.drag(find.byType(PageView), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsOneWidget);
    });

    testWidgets('RTL (fa): start-edge overscroll on Wardrobe opens AppDrawer', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final language = AppLanguage.fromCode('fa');
      final container = _createTestContainer(
        initialTab: AppTab.wardrobe,
        languageCode: 'fa',
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container: container,
          language: language,
          child: const MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsNothing);

      // In RTL, dragging right-to-left at index 0 overscrolls past start edge
      await tester.drag(find.byType(PageView), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsOneWidget);
    });

    testWidgets('LTR (en): start-to-end swipe on Profile opens AppDrawer', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final language = AppLanguage.fromCode('en');
      final container = _createTestContainer(
        initialTab: AppTab.profile,
        languageCode: 'en',
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container: container,
          language: language,
          child: const MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsNothing);

      // In LTR, start -> end is left -> right (+dx)
      await tester.drag(find.byType(ProfileTab), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsOneWidget);
      expect(container.read(appStateProvider).currentTab, AppTab.profile);
    });

    testWidgets('RTL (fa): start-to-end swipe on Profile opens AppDrawer', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final language = AppLanguage.fromCode('fa');
      final container = _createTestContainer(
        initialTab: AppTab.profile,
        languageCode: 'fa',
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container: container,
          language: language,
          child: const MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsNothing);

      // In RTL, start -> end is right -> left (-dx)
      await tester.drag(find.byType(ProfileTab), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsOneWidget);
      expect(container.read(appStateProvider).currentTab, AppTab.profile);
    });

    testWidgets('LTR (en): end-to-start swipe on Profile exits to Wardrobe', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final language = AppLanguage.fromCode('en');
      final container = _createTestContainer(
        initialTab: AppTab.profile,
        languageCode: 'en',
        currentProfileTab: 'p-settings',
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container: container,
          language: language,
          child: const MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // In LTR, end -> start is right -> left (-dx)
      await tester.drag(find.byType(ProfileTab), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(container.read(appStateProvider).currentTab, AppTab.wardrobe);
    });

    testWidgets('RTL (fa): end-to-start swipe on Profile exits to Wardrobe', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final language = AppLanguage.fromCode('fa');
      final container = _createTestContainer(
        initialTab: AppTab.profile,
        languageCode: 'fa',
        currentProfileTab: 'p-settings',
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _wrapWithApp(
          container: container,
          language: language,
          child: const MainShellScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // In RTL, end -> start is left -> right (+dx)
      await tester.drag(find.byType(ProfileTab), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(container.read(appStateProvider).currentTab, AppTab.wardrobe);
    });

    testWidgets(
      'Profile end-to-start swipe respects UnsavedChangesDialog when Identity is dirty',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final language = AppLanguage.fromCode('en');
        final container = _createTestContainer(
          initialTab: AppTab.profile,
          languageCode: 'en',
          currentProfileTab: 'p-identity',
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          _wrapWithApp(
            container: container,
            language: language,
            child: const MainShellScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Simulate user editing an Identity field after ProfileTab mounts
        container.read(appStateProvider.notifier).markDirty();
        await tester.pump();

        // Swipe end -> start in LTR (-dx)
        await tester.drag(find.byType(ProfileTab), const Offset(-200, 0));
        await tester.pumpAndSettle();

        // Guard dialog must appear and keep user on Profile until resolved
        expect(find.byType(UnsavedChangesDialog), findsOneWidget);
        expect(container.read(appStateProvider).currentTab, AppTab.profile);
      },
    );
  });
}
