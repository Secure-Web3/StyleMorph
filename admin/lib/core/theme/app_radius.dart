import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 10.0;
  static const double xl = 12.0;
  static const double card = 14.0;
  static const double xxl = 16.0;
  static const double sheet = 20.0;
  static const double full = 999.0;

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius rXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius rSheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
  static const BorderRadius rFull = BorderRadius.all(Radius.circular(full));
}
