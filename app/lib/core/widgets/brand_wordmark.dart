import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Luxury editorial brand wordmark rendering the exact mixed-case `"StyleMorph"`
/// string using the bundled `Brygada 1918` serif typeface.
class BrandWordmark extends StatelessWidget {
  static const String brandText = 'StyleMorph';

  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Color? color;
  final List<Shadow>? shadows;
  final int? maxLines;
  final TextOverflow? overflow;

  const BrandWordmark({
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing = 0.6,
    this.color,
    this.shadows,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.colors.tx;

    return Text(
      brandText,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: AppTypography.brandFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: resolvedColor,
        shadows: shadows,
        height: 1.15,
      ),
    );
  }
}
