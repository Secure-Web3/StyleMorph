import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemorph/core/localization/app_language.dart';
import 'package:stylemorph/core/localization/locale_provider.dart';
import 'package:stylemorph/core/state/app_state.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/widgets/unified_splash_screen.dart';
import 'package:stylemorph/features/shell/presentation/main_shell_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnifiedSplashScreen zero-halo rendering', () {
    testWidgets(
      'renders sm_logo_transparent.png with BlendMode.srcATop and no tinted box decoration',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: UnifiedSplashScreen(animate: false)),
        );
        await tester.pump();

        expect(find.byType(UnifiedSplashScreen), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(2));

        final shaderMask = tester.widget<ShaderMask>(find.byType(ShaderMask));
        expect(shaderMask.blendMode, BlendMode.srcATop);

        // Ensure no radial/box Container decoration wraps the logo
        expect(
          find.descendant(
            of: find.byType(UnifiedSplashScreen),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration != null,
            ),
          ),
          findsNothing,
        );
      },
    );
  });

  group('MainShellScreen single-page swipe smoothness', () {
    for (final lang in [
      AppLanguage.fromCode('en'),
      AppLanguage.fromCode('fa'),
    ]) {
      testWidgets(
        'uses standard PageScrollPhysics and advances exactly 1 tab per swipe in ${lang.code}',
        (tester) async {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          container.read(localeProvider.notifier).setLanguage(lang.code);
          container.read(appStateProvider.notifier).switchTab(AppTab.wardrobe);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: lang.locale,
                supportedLocales: const [Locale('en'), Locale('fa')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: AppTheme.buildTheme(
                  palette: AppPalette.editorial,
                  isDark: false,
                ),
                home: const MainShellScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final pageView = tester.widget<PageView>(find.byType(PageView));
          expect(pageView.physics, const PageScrollPhysics());

          // Swipe left in LTR (or right in RTL) to advance from Wardrobe -> Wellness (1 tab)
          final dx = lang.textDirection == TextDirection.rtl ? 300.0 : -300.0;
          await tester.fling(find.byType(PageView), Offset(dx, 0), 1200);
          await tester.pumpAndSettle();

          expect(container.read(appStateProvider).currentTab, AppTab.wellness);
        },
      );
    }
  });
}
