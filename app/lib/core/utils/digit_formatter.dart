/// Centralized locale-aware digit formatting utility.
/// Enforces Latin digits (0-9) for LTR locales (`en`, `tr`),
/// Persian digits (۰-۹) for `fa`, and Eastern Arabic digits (٠-٩) for `ar`.
class DigitFormatter {
  DigitFormatter._();

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static const _arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Normalizes a language code (e.g. 'en-US' -> 'en').
  static String normalizeLang(String localeCode) =>
      localeCode.toLowerCase().split(RegExp(r'[-_]')).first;

  /// Centralized locale-aware digit formatter.
  /// For LTR locales (`en`, `tr`): strictly converts any Persian or Arabic digits to Latin (0-9).
  /// For `fa`: converts Latin digits to Persian digits (۰-۹).
  /// For `ar`: converts Latin digits to Eastern Arabic digits (٠-٩).
  static String localizeDigits(Object? input, String languageCode) {
    if (input == null) return '';
    final raw = input.toString();
    final ascii = toLatinDigits(raw);
    final lang = normalizeLang(languageCode);

    if (lang == 'fa') {
      return replaceWithDigits(ascii, _faDigits).replaceAll('%', '٪');
    }
    if (lang == 'ar') {
      return replaceWithDigits(ascii, _arDigits).replaceAll('%', '٪');
    }

    // For en, tr, and all other LTR locales:
    return ascii
        .replaceAll('٪', '%')
        .replaceAll('٬', ',')
        .replaceAll('،', ',')
        .replaceAll('٫', '.');
  }

  /// Strictly converts any Persian (۰-۹) or Arabic-Indic (٠-٩) digits to ASCII Latin (0-9).
  static String toLatinDigits(String s) {
    final buf = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final faIdx = _faDigits.indexOf(ch);
      if (faIdx != -1) {
        buf.write(faIdx);
        continue;
      }
      final arIdx = _arDigits.indexOf(ch);
      if (arIdx != -1) {
        buf.write(arIdx);
        continue;
      }
      buf.write(ch);
    }
    return buf.toString();
  }

  /// Replaces Latin 0-9 digits with target locale digit glyphs.
  static String replaceWithDigits(String ascii, List<String> targets) {
    final buf = StringBuffer();
    for (final rune in ascii.runes) {
      final code = rune - 48;
      if (code >= 0 && code <= 9) {
        buf.write(targets[code]);
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }
}
