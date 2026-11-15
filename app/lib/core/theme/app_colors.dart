import 'package:flutter/material.dart';

enum AppPalette {
  white,
  beige,
  slate,
  obsidian,
  editorial,
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color sf;
  final Color bd;
  final Color tx;
  final Color mu;
  final Color pr;
  final Color prt;
  final Color ok;
  final Color okb;
  final Color wn;
  final Color wnb;
  final Color inColor;
  final Color inb;
  final Color orColor;
  final Color orb;

  const AppColors({
    required this.bg,
    required this.sf,
    required this.bd,
    required this.tx,
    required this.mu,
    required this.pr,
    required this.prt,
    required this.ok,
    required this.okb,
    required this.wn,
    required this.wnb,
    required this.inColor,
    required this.inb,
    required this.orColor,
    required this.orb,
  });

  // 1. Minimal Light (White)
  static const lightWhite = AppColors(
    bg: Color(0xFFFFFFFF),
    sf: Color(0xFFFFFFFF),
    bd: Color(0xFFE5E5E5),
    tx: Color(0xFF171717),
    mu: Color(0xFF737373),
    pr: Color(0xFF171717),
    prt: Color(0xFFFFFFFF),
    ok: Color(0xFF2E6B47),
    okb: Color(0xFFE6F3EA),
    wn: Color(0xFF8A6A12),
    wnb: Color(0xFFFBF3DC),
    inColor: Color(0xFF2F5D9B),
    inb: Color(0xFFE8F0FA),
    orColor: Color(0xFF9A5418),
    orb: Color(0xFFFBEBDD),
  );

  static const darkWhite = AppColors(
    bg: Color(0xFF111111),
    sf: Color(0xFF1A1A1A),
    bd: Color(0xFF2C2C2C),
    tx: Color(0xFFF2F2F2),
    mu: Color(0xFF9A9A9A),
    pr: Color(0xFFF2F2F2),
    prt: Color(0xFF111111),
    ok: Color(0xFF4ADE80),
    okb: Color(0xFF143521),
    wn: Color(0xFFFBBF24),
    wnb: Color(0xFF392C08),
    inColor: Color(0xFF60A5FA),
    inb: Color(0xFF172B4D),
    orColor: Color(0xFFF87171),
    orb: Color(0xFF3C1A14),
  );

  // 2. Luxury Warm Beige
  static const lightBeige = AppColors(
    bg: Color(0xFFFAF7F2),
    sf: Color(0xFFFFFDF9),
    bd: Color(0xFFE7DFD3),
    tx: Color(0xFF2B2118),
    mu: Color(0xFF8A7B6B),
    pr: Color(0xFF5C4033),
    prt: Color(0xFFFFFDF9),
    ok: Color(0xFF2E6B47),
    okb: Color(0xFFE6F3EA),
    wn: Color(0xFF8A6A12),
    wnb: Color(0xFFFBF3DC),
    inColor: Color(0xFF2F5D9B),
    inb: Color(0xFFE8F0FA),
    orColor: Color(0xFF9A5418),
    orb: Color(0xFFFBEBDD),
  );

  static const darkBeige = AppColors(
    bg: Color(0xFF1C1713),
    sf: Color(0xFF251F19),
    bd: Color(0xFF3A3128),
    tx: Color(0xFFF3EBE0),
    mu: Color(0xFFA8998A),
    pr: Color(0xFFD9B99B),
    prt: Color(0xFF1C1713),
    ok: Color(0xFF4ADE80),
    okb: Color(0xFF143521),
    wn: Color(0xFFFBBF24),
    wnb: Color(0xFF392C08),
    inColor: Color(0xFF60A5FA),
    inb: Color(0xFF172B4D),
    orColor: Color(0xFFF87171),
    orb: Color(0xFF3C1A14),
  );

  // 3. Modern Slate
  static const lightSlate = AppColors(
    bg: Color(0xFFF4F5F6),
    sf: Color(0xFFFFFFFF),
    bd: Color(0xFFDDE0E3),
    tx: Color(0xFF26292D),
    mu: Color(0xFF6B7178),
    pr: Color(0xFF2F3438),
    prt: Color(0xFFFFFFFF),
    ok: Color(0xFF2E6B47),
    okb: Color(0xFFE6F3EA),
    wn: Color(0xFF8A6A12),
    wnb: Color(0xFFFBF3DC),
    inColor: Color(0xFF2F5D9B),
    inb: Color(0xFFE8F0FA),
    orColor: Color(0xFF9A5418),
    orb: Color(0xFFFBEBDD),
  );

  static const darkSlate = AppColors(
    bg: Color(0xFF17191B),
    sf: Color(0xFF202325),
    bd: Color(0xFF33373B),
    tx: Color(0xFFE8EAEC),
    mu: Color(0xFF9AA0A6),
    pr: Color(0xFFC9CED3),
    prt: Color(0xFF17191B),
    ok: Color(0xFF4ADE80),
    okb: Color(0xFF143521),
    wn: Color(0xFFFBBF24),
    wnb: Color(0xFF392C08),
    inColor: Color(0xFF60A5FA),
    inb: Color(0xFF172B4D),
    orColor: Color(0xFFF87171),
    orb: Color(0xFF3C1A14),
  );

  // 4. Obsidian Dark (Ultra Luxury Deep Dark)
  static const lightObsidian = AppColors(
    bg: Color(0xFFF7F7F8),
    sf: Color(0xFFFFFFFF),
    bd: Color(0xFFE2E4E8),
    tx: Color(0xFF0D0E11),
    mu: Color(0xFF656972),
    pr: Color(0xFF0D0E11),
    prt: Color(0xFFFFFFFF),
    ok: Color(0xFF2E6B47),
    okb: Color(0xFFE6F3EA),
    wn: Color(0xFF8A6A12),
    wnb: Color(0xFFFBF3DC),
    inColor: Color(0xFF2F5D9B),
    inb: Color(0xFFE8F0FA),
    orColor: Color(0xFF9A5418),
    orb: Color(0xFFFBEBDD),
  );

  static const darkObsidian = AppColors(
    bg: Color(0xFF090A0C),
    sf: Color(0xFF131418),
    bd: Color(0xFF22252B),
    tx: Color(0xFFF5F6F8),
    mu: Color(0xFF888E99),
    pr: Color(0xFFE5E7EB),
    prt: Color(0xFF090A0C),
    ok: Color(0xFF4ADE80),
    okb: Color(0xFF143521),
    wn: Color(0xFFFBBF24),
    wnb: Color(0xFF392C08),
    inColor: Color(0xFF60A5FA),
    inb: Color(0xFF172B4D),
    orColor: Color(0xFFF87171),
    orb: Color(0xFF3C1A14),
  );

  // 5. Luxury Editorial (High-Fashion Champagne Gold & Ivory)
  static const lightEditorial = AppColors(
    bg: Color(0xFFFAF8F5),
    sf: Color(0xFFFFFFFF),
    bd: Color(0xFFE8E2D8),
    tx: Color(0xFF1A1613),
    mu: Color(0xFF7D756D),
    pr: Color(0xFF8C6D46),
    prt: Color(0xFFFFFFFF),
    ok: Color(0xFF2E6B47),
    okb: Color(0xFFE6F3EA),
    wn: Color(0xFF8A6A12),
    wnb: Color(0xFFFBF3DC),
    inColor: Color(0xFF2F5D9B),
    inb: Color(0xFFE8F0FA),
    orColor: Color(0xFF9A5418),
    orb: Color(0xFFFBEBDD),
  );

  static const darkEditorial = AppColors(
    bg: Color(0xFF141210),
    sf: Color(0xFF1E1B18),
    bd: Color(0xFF332E29),
    tx: Color(0xFFF5F0EA),
    mu: Color(0xFF9E958C),
    pr: Color(0xFFD4AF37),
    prt: Color(0xFF141210),
    ok: Color(0xFF4ADE80),
    okb: Color(0xFF143521),
    wn: Color(0xFFFBBF24),
    wnb: Color(0xFF392C08),
    inColor: Color(0xFF60A5FA),
    inb: Color(0xFF172B4D),
    orColor: Color(0xFFF87171),
    orb: Color(0xFF3C1A14),
  );

  static AppColors resolve(AppPalette palette, bool isDark) {
    switch (palette) {
      case AppPalette.white:
        return isDark ? darkWhite : lightWhite;
      case AppPalette.beige:
        return isDark ? darkBeige : lightBeige;
      case AppPalette.slate:
        return isDark ? darkSlate : lightSlate;
      case AppPalette.obsidian:
        return isDark ? darkObsidian : lightObsidian;
      case AppPalette.editorial:
        return isDark ? darkEditorial : lightEditorial;
    }
  }

  @override
  AppColors copyWith({
    Color? bg,
    Color? sf,
    Color? bd,
    Color? tx,
    Color? mu,
    Color? pr,
    Color? prt,
    Color? ok,
    Color? okb,
    Color? wn,
    Color? wnb,
    Color? inColor,
    Color? inb,
    Color? orColor,
    Color? orb,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      sf: sf ?? this.sf,
      bd: bd ?? this.bd,
      tx: tx ?? this.tx,
      mu: mu ?? this.mu,
      pr: pr ?? this.pr,
      prt: prt ?? this.prt,
      ok: ok ?? this.ok,
      okb: okb ?? this.okb,
      wn: wn ?? this.wn,
      wnb: wnb ?? this.wnb,
      inColor: inColor ?? this.inColor,
      inb: inb ?? this.inb,
      orColor: orColor ?? this.orColor,
      orb: orb ?? this.orb,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      sf: Color.lerp(sf, other.sf, t) ?? sf,
      bd: Color.lerp(bd, other.bd, t) ?? bd,
      tx: Color.lerp(tx, other.tx, t) ?? tx,
      mu: Color.lerp(mu, other.mu, t) ?? mu,
      pr: Color.lerp(pr, other.pr, t) ?? pr,
      prt: Color.lerp(prt, other.prt, t) ?? prt,
      ok: Color.lerp(ok, other.ok, t) ?? ok,
      okb: Color.lerp(okb, other.okb, t) ?? okb,
      wn: Color.lerp(wn, other.wn, t) ?? wn,
      wnb: Color.lerp(wnb, other.wnb, t) ?? wnb,
      inColor: Color.lerp(inColor, other.inColor, t) ?? inColor,
      inb: Color.lerp(inb, other.inb, t) ?? inb,
      orColor: Color.lerp(orColor, other.orColor, t) ?? orColor,
      orb: Color.lerp(orb, other.orb, t) ?? orb,
    );
  }
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.lightWhite;
}
