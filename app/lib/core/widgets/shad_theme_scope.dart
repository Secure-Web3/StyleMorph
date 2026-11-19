import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Wraps [child] in a fallback [ShadTheme] only when no [ShadTheme] ancestor
/// exists in the widget tree (e.g., isolated widget tests).
Widget ensureShadTheme(BuildContext context, Widget child) {
  if (ShadTheme.maybeOf(context) != null) {
    return child;
  }
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return ShadTheme(
    data: AppTheme.buildShadTheme(
      palette: AppPalette.editorial,
      isDark: isDark,
    ),
    child: child,
  );
}
