import 'package:flutter/material.dart';

/// Visual contrast mode for [AppLogo].
enum AppLogoVariant {
  /// Automatically adapts to the active light or dark theme.
  auto,

  /// Translucent obsidian glass treatment for dark photo/hero overlays.
  overlay,
}

/// Official StyleMorph `SM` monogram emblem with theme-aware contrast framing.
class AppLogo extends StatelessWidget {
  static const String assetPath = 'assets/images/brand/sm_logo_transparent.png';
  static const Color _champagneGold = Color(0xFFD4AF37);

  final double size;
  final AppLogoVariant variant;

  const AppLogo({
    super.key,
    this.size = 56,
    this.variant = AppLogoVariant.auto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(size * 0.25);
    final innerPadding = EdgeInsets.all(size * 0.14);

    final BoxDecoration decoration;
    switch (variant) {
      case AppLogoVariant.overlay:
        decoration = BoxDecoration(
          color: const Color(0xFF141416).withValues(alpha: 0.72),
          borderRadius: borderRadius,
          border: Border.all(
            color: _champagneGold.withValues(alpha: 0.45),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case AppLogoVariant.auto:
        if (isDark) {
          decoration = BoxDecoration(
            color: const Color(0xFF1A1A1E),
            borderRadius: borderRadius,
            border: Border.all(
              color: _champagneGold.withValues(alpha: 0.32),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          );
        } else {
          decoration = BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF141416), Color(0xFF202024)],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: _champagneGold.withValues(alpha: 0.55),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          );
        }
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      child: Padding(
        padding: innerPadding,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
