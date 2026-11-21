import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemorph/core/theme/app_colors.dart';
import 'package:stylemorph/core/theme/app_theme.dart';
import 'package:stylemorph/core/theme/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Default Theme Luxury Editorial + Light Mode Tests', () {
    test('ThemeNotifier defaults to Luxury Editorial and Light Mode', () {
      final notifier = ThemeNotifier();
      expect(notifier.state.palette, AppPalette.editorial);
      expect(notifier.state.mode, ThemeMode.light);
      expect(notifier.state.isDark, isFalse);
    });

    test('Resolved default AppColors matches Luxury Editorial Light', () {
      final notifier = ThemeNotifier();
      final colors = AppColors.resolve(
        notifier.state.palette,
        notifier.state.isDark,
      );

      // Verify Luxury Editorial light characteristics
      expect(colors.bg, const Color(0xFFFAF8F5));
      expect(colors.sf, const Color(0xFFFFFFFF));
      expect(colors.pr, const Color(0xFF8C6D46)); // Champagne Gold
      expect(colors.tx, const Color(0xFF1A1613));
    });

    test('AppTheme.buildTheme with default state creates correct theme', () {
      final notifier = ThemeNotifier();
      final themeData = AppTheme.buildTheme(
        palette: notifier.state.palette,
        isDark: notifier.state.isDark,
      );

      expect(themeData.brightness, Brightness.light);
      expect(themeData.scaffoldBackgroundColor, const Color(0xFFFAF8F5));
    });

    test(
      'ThemeNotifier persists and updates palette and mode changes',
      () async {
        final notifier = ThemeNotifier();
        notifier.setPalette(AppPalette.slate);
        notifier.setThemeMode(ThemeMode.dark);

        expect(notifier.state.palette, AppPalette.slate);
        expect(notifier.state.mode, ThemeMode.dark);
        expect(notifier.state.isDark, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(ThemeNotifier.keyThemePalette), 'slate');
        expect(prefs.getString(ThemeNotifier.keyThemeMode), 'dark');
      },
    );

    testWidgets(
      'Widget tree under themeProvider receives editorial colors by default',
      (WidgetTester tester) async {
        late AppColors capturedColors;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                final themeState = ref.watch(themeProvider);
                return MaterialApp(
                  theme: AppTheme.buildTheme(
                    palette: themeState.palette,
                    isDark: false,
                  ),
                  home: Builder(
                    builder: (ctx) {
                      capturedColors = ctx.colors;
                      return const Scaffold(body: Text('Editorial Test'));
                    },
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(capturedColors.bg, const Color(0xFFFAF8F5));
        expect(capturedColors.pr, const Color(0xFF8C6D46));
      },
    );
  });
}
