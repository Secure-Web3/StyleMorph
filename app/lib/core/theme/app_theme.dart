import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme({
    required AppPalette palette,
    required bool isDark,
    String? localeCode,
  }) {
    final colors = AppColors.resolve(palette, isDark);
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final targetFont = AppTypography.fontFamilyFor(localeCode);
    final fontFallback = AppTypography.fontFamilyFallbackFor(localeCode);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: targetFont,
      fontFamilyFallback: fontFallback,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.sf,
      cardColor: colors.sf,
      dividerColor: colors.bd,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.pr,
        onPrimary: colors.prt,
        secondary: colors.pr,
        onSecondary: colors.prt,
        error: colors.orColor,
        onError: colors.prt,
        surface: colors.sf,
        onSurface: colors.tx,
      ),
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.sf,
        foregroundColor: colors.tx,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: targetFont,
          fontFamilyFallback: fontFallback,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colors.tx,
        ),
      ),
    );
  }

  static ShadThemeData buildShadTheme({
    required AppPalette palette,
    required bool isDark,
  }) {
    final colors = AppColors.resolve(palette, isDark);
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return ShadThemeData(
      brightness: brightness,
      radius: AppRadius.rXl,
      colorScheme: ShadColorScheme(
        background: colors.bg,
        foreground: colors.tx,
        card: colors.sf,
        cardForeground: colors.tx,
        popover: colors.sf,
        popoverForeground: colors.tx,
        primary: colors.pr,
        primaryForeground: colors.prt,
        secondary: colors.bg,
        secondaryForeground: colors.tx,
        muted: colors.bg,
        mutedForeground: colors.mu,
        accent: colors.bg,
        accentForeground: colors.tx,
        destructive: colors.orColor,
        destructiveForeground: colors.prt,
        border: colors.bd,
        input: colors.bd,
        ring: colors.pr,
        selection: colors.pr.withValues(alpha: 0.2),
      ),
    );
  }
}
