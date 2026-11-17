import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_language.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(_resolveInitialLanguage());

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
  }
}
