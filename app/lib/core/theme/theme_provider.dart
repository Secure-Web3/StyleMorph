import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  ThemeState copyWith({AppPalette? palette, ThemeMode? mode, bool? isDark}) {
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
  static const String keyThemePalette = 'user_theme_palette';
  static const String keyThemeMode = 'user_theme_mode';
  StreamSubscription<User?>? _authSubscription;

  ThemeNotifier()
    : super(
        const ThemeState(
          palette: AppPalette.editorial, // Luxury Editorial Default
          mode: ThemeMode.light, // Light Mode Default
          isDark: false,
        ),
      ) {
    _loadFromLocalPrefs();
    _initAuthListener();
  }

  static bool _resolveDarkFlag(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  Future<void> _loadFromLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPaletteName = prefs.getString(keyThemePalette);
      final savedModeName = prefs.getString(keyThemeMode);

      AppPalette? palette;
      if (savedPaletteName != null) {
        for (final p in AppPalette.values) {
          if (p.name == savedPaletteName) {
            palette = p;
            break;
          }
        }
      }

      ThemeMode? mode;
      if (savedModeName != null) {
        for (final m in ThemeMode.values) {
          if (m.name == savedModeName) {
            mode = m;
            break;
          }
        }
      }

      if (palette != null || mode != null) {
        final newPalette = palette ?? state.palette;
        final newMode = mode ?? state.mode;
        state = state.copyWith(
          palette: newPalette,
          mode: newMode,
          isDark: _resolveDarkFlag(newMode),
        );
      }
    } catch (e) {
      debugPrint('[ThemeNotifier] _loadFromLocalPrefs notice: $e');
    }
  }

  void _initAuthListener() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
          user,
        ) {
          if (user != null) {
            _loadUserThemeFromFirestore(user.uid);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserThemeFromFirestore(String uid) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        Map<String, dynamic>? themeMap;
        if (data['preferences'] is Map) {
          final prefMap = Map<String, dynamic>.from(data['preferences'] as Map);
          themeMap = {
            'palette': prefMap['fashionThemePalette'] ?? prefMap['palette'],
            'mode': prefMap['brightnessMode'] ?? prefMap['mode'],
          };
        } else if (data['theme'] is Map) {
          themeMap = Map<String, dynamic>.from(data['theme'] as Map);
        }
        if (themeMap != null) {
          final paletteStr = themeMap['palette']?.toString();
          final modeStr = themeMap['mode']?.toString();

          AppPalette? palette;
          if (paletteStr != null) {
            for (final p in AppPalette.values) {
              if (p.name == paletteStr) {
                palette = p;
                break;
              }
            }
          }

          ThemeMode? mode;
          if (modeStr != null) {
            for (final m in ThemeMode.values) {
              if (m.name == modeStr) {
                mode = m;
                break;
              }
            }
          }

          if (palette != null || mode != null) {
            final newPalette = palette ?? state.palette;
            final newMode = mode ?? state.mode;
            state = state.copyWith(
              palette: newPalette,
              mode: newMode,
              isDark: _resolveDarkFlag(newMode),
            );
            _saveToLocalPrefs();
          }
        }
      }
    } catch (e) {
      debugPrint('[ThemeNotifier] _loadUserThemeFromFirestore error: $e');
    }
  }

  Future<void> _saveToLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyThemePalette, state.palette.name);
      await prefs.setString(keyThemeMode, state.mode.name);
    } catch (e) {
      debugPrint('[ThemeNotifier] _saveToLocalPrefs error: $e');
    }
  }

  Future<void> _saveUserThemeToFirestore() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'theme': {'palette': state.palette.name, 'mode': state.mode.name},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ThemeNotifier] _saveUserThemeToFirestore error: $e');
    }
  }

  void setPalette(AppPalette palette) {
    state = state.copyWith(palette: palette);
    _saveToLocalPrefs();
    _saveUserThemeToFirestore();
  }

  void cyclePalette() {
    const values = AppPalette.values;
    final nextIndex = (values.indexOf(state.palette) + 1) % values.length;
    setPalette(values[nextIndex]);
  }

  /// Cycles through Light -> Dark -> System Auto -> Light.
  void cycleThemeMode() {
    const order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final nextIndex = (order.indexOf(state.mode) + 1) % order.length;
    setThemeMode(order[nextIndex]);
  }

  void toggleDark() {
    if (state.isDark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(mode: mode, isDark: _resolveDarkFlag(mode));
    _saveToLocalPrefs();
    _saveUserThemeToFirestore();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
