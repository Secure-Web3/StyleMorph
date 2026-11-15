import 'package:flutter/material.dart';

class AppLanguage {
  final String code;
  final String nativeName;
  final Locale locale;
  final TextDirection textDirection;

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.locale,
    required this.textDirection,
  });

  static const supportedLanguages = [
    AppLanguage(
      code: 'fa',
      nativeName: 'فارسی',
      locale: Locale('fa'),
      textDirection: TextDirection.rtl,
    ),
    AppLanguage(
      code: 'en',
      nativeName: 'English',
      locale: Locale('en'),
      textDirection: TextDirection.ltr,
    ),
    AppLanguage(
      code: 'ar',
      nativeName: 'العربية',
      locale: Locale('ar'),
      textDirection: TextDirection.rtl,
    ),
    AppLanguage(
      code: 'tr',
      nativeName: 'Türkçe',
      locale: Locale('tr'),
      textDirection: TextDirection.ltr,
    ),
  ];

  static AppLanguage fromCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages.first,
    );
  }
}
