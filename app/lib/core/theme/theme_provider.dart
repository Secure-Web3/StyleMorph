import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';

class ThemeState {
  final AppPalette palette;
  final ThemeMode mode;
  final bool isDark;

  const ThemeState({
    required this.palette,
    required this.mode,
    required this.isDark,
  });

  /// Resolves the effective brightness taking [ThemeMode.system] into account.
  bool resolveIsDark(BuildContext context) {
    if (mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  ThemeState copyWith({
    AppPalette? palette,
    ThemeMode? mode,
    bool? isDark,
  }) {
    return ThemeState(
      palette: palette ?? this.palette,
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(
          const ThemeState(
            palette: AppPalette.white,
            mode: ThemeMode.light,
            isDark: false,
          ),
        );

  static bool _resolveDarkFlag(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  void setPalette(AppPalette palette) {
    state = state.copyWith(palette: palette);
  }

  void cyclePalette() {
    const values = AppPalette.values;
    final nextIndex = (values.indexOf(state.palette) + 1) % values.length;
    state = state.copyWith(palette: values[nextIndex]);
  }

  /// Cycles through Light -> Dark -> System Auto -> Light.
  void cycleThemeMode() {
    const order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final nextIndex = (order.indexOf(state.mode) + 1) % order.length;
    final nextMode = order[nextIndex];
    state = state.copyWith(
      mode: nextMode,
      isDark: _resolveDarkFlag(nextMode),
    );
  }

  void toggleDark() {
    if (state.isDark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(
      mode: mode,
      isDark: _resolveDarkFlag(mode),
    );
  }
}
