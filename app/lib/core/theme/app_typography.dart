import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Vazirmatn';

  static TextStyle displayLarge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.25,
    color: color,
  );

  static TextStyle headlineMedium({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: color,
  );

  static TextStyle titleMedium({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: color,
  );

  static TextStyle moduleTitle({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: color,
  );

  static TextStyle sectionTitle({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: color,
  );

  static TextStyle cardTitle({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: color,
  );

  static TextStyle inputLabel({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: color,
  );

  static TextStyle buttonLabel({Color? color, double fontSize = 13}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color,
      );

  static TextStyle chipLabel({Color? color, bool isSelected = false}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        height: 1.25,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  static TextStyle bodySmall({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  static TextStyle caption({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: color,
  );

  static TextStyle badge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  /// Resolves the primary font family for the target locale.
  /// For LTR languages (`en`, `tr`), returns null to use platform-native Latin typography,
  /// preventing fonts with Arabic glyph mappings from altering ASCII Latin digits.
  static String? fontFamilyFor(String? localeCode) {
    if (localeCode == null) return fontFamily;
    final lang = localeCode.toLowerCase().split(RegExp(r'[-_]')).first;
    if (lang == 'en' || lang == 'tr') {
      return null;
    }
    return fontFamily;
  }

  /// Fallback font list per locale.
  static List<String> fontFamilyFallbackFor(String? localeCode) {
    final lang = localeCode?.toLowerCase().split(RegExp(r'[-_]')).first;
    if (lang == 'en' || lang == 'tr') {
      return const ['Roboto', 'Arial', 'sans-serif', 'Vazirmatn'];
    }
    return const ['Vazirmatn', 'Roboto', 'Arial', 'sans-serif'];
  }
}
