import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_language.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.supportedLanguages.first);

  void setLanguage(String code) {
    state = AppLanguage.fromCode(code);
  }
}
