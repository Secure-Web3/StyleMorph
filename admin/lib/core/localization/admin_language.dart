import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AdminLanguage {
  fa(code: 'fa', label: 'فارسی', isRtl: true),
  en(code: 'en', label: 'English', isRtl: false),
  ar(code: 'ar', label: 'العربية', isRtl: true);

  final String code;
  final String label;
  final bool isRtl;

  const AdminLanguage({
    required this.code,
    required this.label,
    required this.isRtl,
  });

  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;
  Locale get locale => Locale(code);
}

final adminLanguageProvider =
    StateNotifierProvider<AdminLanguageNotifier, AdminLanguage>((ref) {
  return AdminLanguageNotifier();
});

class AdminLanguageNotifier extends StateNotifier<AdminLanguage> {
  AdminLanguageNotifier() : super(AdminLanguage.fa);

  void setLanguage(AdminLanguage lang) {
    state = lang;
  }

  void cycleLanguage() {
    const list = AdminLanguage.values;
    final next = (list.indexOf(state) + 1) % list.length;
    state = list[next];
  }
}
