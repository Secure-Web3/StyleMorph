import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/brand_wordmark.dart';
import 'package:stylemorph/features/auth/presentation/auth_screen.dart';
import 'package:stylemorph/features/profile/presentation/profile_tab.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';
import 'package:stylemorph/features/shell/presentation/widgets/app_drawer.dart';

void main() {
  Widget wrapWithApp({
    required Widget child,
    AppLanguage? language,
    List<Override> overrides = const [],
  }) {
    final resolvedLang = language ?? AppLanguage.fromCode('en');
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.buildTheme(
          palette: AppPalette.white,
          isDark: false,
          localeCode: resolvedLang.code,
        ),
        locale: resolvedLang.locale,
        builder: (context, inner) => ShadTheme(
          data: AppTheme.buildShadTheme(
            palette: AppPalette.white,
            isDark: false,
          ),
          child: Directionality(
            textDirection: resolvedLang.textDirection,
            child: inner ?? const SizedBox.shrink(),
          ),
        ),
        home: child,
      ),
    );
  }

  group(
    'Batch 2 — AuthScreen Zero-Scroll, Profile Drawer Swipe & Sub-Tab Scroll',
    () {
      testWidgets(
        'AuthScreen Sign In renders completely with zero scroll and zero overflow on 375x667 and 390x844',
        (tester) async {
          for (final size in const [Size(375, 667), Size(390, 844)]) {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(wrapWithApp(child: const AuthScreen()));
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            expect(find.byType(BrandWordmark), findsOneWidget);
            expect(find.byType(SingleChildScrollView), findsNothing);
            expect(find.text('Google'), findsOneWidget);
            expect(find.text('Apple'), findsOneWidget);
          }
        },
      );

      testWidgets(
        'Horizontal swipe in Profile opens AppDrawer in both LTR (en) and RTL (fa) without changing active tab',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          // 1. LTR (English): swipe left-to-right opens drawer
          final containerLtr = ProviderContainer();
          addTearDown(containerLtr.dispose);
          containerLtr.read(localeProvider.notifier).setLanguage('en');
          containerLtr
              .read(appStateProvider.notifier)
              .switchTab(AppTab.profile);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: containerLtr,
              child: MaterialApp(
                theme: AppTheme.buildTheme(
                  palette: AppPalette.white,
                  isDark: false,
                  localeCode: 'en',
                ),
                builder: (context, inner) => ShadTheme(
                  data: AppTheme.buildShadTheme(
                    palette: AppPalette.white,
                    isDark: false,
                  ),
                  child: inner ?? const SizedBox.shrink(),
                ),
                home: const MainShellScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.dragFrom(const Offset(240, 400), const Offset(120, 0));
          await tester.pumpAndSettle();

          expect(find.byType(AppDrawer), findsOneWidget);
          expect(
            containerLtr.read(appStateProvider).currentTab,
            AppTab.profile,
          );

          // 2. RTL (Persian): swipe right-to-left opens drawer
          final containerRtl = ProviderContainer();
          addTearDown(containerRtl.dispose);
          containerRtl.read(localeProvider.notifier).setLanguage('fa');
          containerRtl
              .read(appStateProvider.notifier)
              .switchTab(AppTab.profile);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: containerRtl,
              child: MaterialApp(
                theme: AppTheme.buildTheme(
                  palette: AppPalette.white,
                  isDark: false,
                  localeCode: 'fa',
                ),
                builder: (context, inner) => ShadTheme(
                  data: AppTheme.buildShadTheme(
                    palette: AppPalette.white,
                    isDark: false,
                  ),
                  child: inner ?? const SizedBox.shrink(),
                ),
                home: const MainShellScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.dragFrom(const Offset(150, 400), const Offset(-120, 0));
          await tester.pumpAndSettle();

          expect(find.byType(AppDrawer), findsOneWidget);
          expect(
            containerRtl.read(appStateProvider).currentTab,
            AppTab.profile,
          );
        },
      );

      testWidgets(
        'Scrolling inside Identity sub-tab does not affect scroll offset of Media or AI Anatomy sub-tabs',
        (tester) async {
          tester.view.physicalSize = const Size(480, 520);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final container = ProviderContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.buildTheme(
                  palette: AppPalette.white,
                  isDark: false,
                  localeCode: 'en',
                ),
                builder: (context, inner) => ShadTheme(
                  data: AppTheme.buildShadTheme(
                    palette: AppPalette.white,
                    isDark: false,
                  ),
                  child: const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Scaffold(body: ProfileTab()),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Scroll down inside Identity sub-tab
          final identityScrollFinder = find.byKey(
            const ValueKey('profile_scroll_p-identity'),
          );
          expect(identityScrollFinder, findsOneWidget);

          final identityScrollView = tester.widget<SingleChildScrollView>(
            identityScrollFinder,
          );
          expect(
            identityScrollView.controller!.position.maxScrollExtent,
            greaterThan(0.0),
          );
          identityScrollView.controller!.jumpTo(120.0);
          await tester.pumpAndSettle();
          expect(identityScrollView.controller!.offset, equals(120.0));

          // Switch to Settings sub-tab
          await tester.tap(find.byKey(const Key('profile_nav_p-settings')));
          await tester.pumpAndSettle();

          final settingsScrollFinder = find.byKey(
            const ValueKey('profile_scroll_p-settings'),
          );
          expect(settingsScrollFinder, findsOneWidget);
          final settingsScrollView = tester.widget<SingleChildScrollView>(
            settingsScrollFinder,
          );
          expect(settingsScrollView.controller!.offset, equals(0.0));

          // Switch to About sub-tab
          await tester.tap(find.byKey(const Key('profile_nav_p-about')));
          await tester.pumpAndSettle();

          final aboutScrollFinder = find.byKey(
            const ValueKey('profile_scroll_p-about'),
          );
          expect(aboutScrollFinder, findsOneWidget);
          final aboutScrollView = tester.widget<SingleChildScrollView>(
            aboutScrollFinder,
          );
          expect(aboutScrollView.controller!.offset, equals(0.0));
        },
      );
    },
  );
}
