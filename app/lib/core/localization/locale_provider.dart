import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_language.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLanguage> {
  static const String keyAppLanguage = 'app_language_code';

  LocaleNotifier() : super(_resolveInitialLanguage()) {
    _loadFromLocalPrefs();
  }

  Future<void> _loadFromLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(keyAppLanguage);
      if (code != null && code.isNotEmpty) {
        state = AppLanguage.fromCode(code);
      }
    } catch (_) {}
  }

  /// Detects the OS/browser locale on first launch.
  /// Falls back to English if the OS language is not supported.
  static AppLanguage _resolveInitialLanguage() {
    try {
      final platformLocale =
          WidgetsBinding.instance.platformDispatcher.locale;
      final languageCode = platformLocale.languageCode.toLowerCase();
      for (final lang in AppLanguage.supportedLanguages) {
        if (lang.code.toLowerCase() == languageCode) {
          return lang;
        }
      }
      return AppLanguage.fromCode('en');
    } catch (_) {
      return AppLanguage.fromCode('en');
    }
  }

  void setLanguage(String code) {
    state = AppLanguage.fromCode(code);
    try {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(keyAppLanguage, code);
      });
    } catch (_) {}
  }
}
