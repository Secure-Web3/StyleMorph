import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Unified luxury dark editorial splash screen with animated SM monogram logo.
///
/// Features smooth scale & gold shimmer entrance animations, custom vector SM monogram
/// fallback matching the champagne star emblem, and dark editorial (#12100E) styling.
class UnifiedSplashScreen extends StatefulWidget {
  final bool animate;

  const UnifiedSplashScreen({super.key, this.animate = true});

  @override
  State<UnifiedSplashScreen> createState() => _UnifiedSplashScreenState();
}

class _UnifiedSplashScreenState extends State<UnifiedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF12100E);
    const goldLight = Color(0xFFF5E6BE);
    const goldPrimary = Color(0xFFD4AF37);
    const goldDeep = Color(0xFFA67C1E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 1.2,
            colors: [
              Color(0xFF221C16),
              Color(0xFF161310),
              Color(0xFF12100E),
              Color(0xFF0C0A09),
            ],
            stops: [0.0, 0.45, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = _scaleAnimation.value;
              final opacity = _fadeAnimation.value.clamp(0.0, 1.0);
              final pulse = _pulseAnimation.value;

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SM Monogram Star Emblem
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: goldPrimary.withValues(
                                alpha: 0.20 * pulse,
                              ),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _SmMonogramPainter(
                            primaryColor: goldPrimary,
                            lightColor: goldLight,
                            deepColor: goldDeep,
                            pulse: pulse,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Brand Wordmark
                      Text(
                        'STYLEMORPH',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.5,
                          color: goldLight,
                          shadows: [
                            Shadow(
                              color: goldPrimary.withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Refined Subtitle
                      Text(
                        'HAUTE COUTURE & AI STYLING',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.5,
                          color: goldPrimary.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Subtle Luxury Loading Indicator
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goldPrimary.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom vector painter for the luxury interconnected SM monogram and 4-point star emblem.
class _SmMonogramPainter extends CustomPainter {
  final Color primaryColor;
  final Color lightColor;
  final Color deepColor;
  final double pulse;

  _SmMonogramPainter({
    required this.primaryColor,
    required this.lightColor,
    required this.deepColor,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Outer Golden Ring
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: [deepColor, primaryColor, lightColor, primaryColor, deepColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, (w / 2) - 4, ringPaint);

    // 2. Center 4-Point Luxury Diamond Star
    final starPaint = Paint()
      ..shader = RadialGradient(
        colors: [lightColor, primaryColor],
      ).createShader(Rect.fromCircle(center: center, radius: 24))
      ..style = PaintingStyle.fill;

    final starPath = Path();
    const starRadius = 14.0;
    const innerRadius = 3.5;
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90.0) * (math.pi / 180.0);
      final nextAngle = ((i * 90.0) + 45.0) * (math.pi / 180.0);
      if (i == 0) {
        starPath.moveTo(
          center.dx + starRadius * math.cos(angle),
          center.dy + starRadius * math.sin(angle),
        );
      } else {
        starPath.lineTo(
          center.dx + starRadius * math.cos(angle),
          center.dy + starRadius * math.sin(angle),
        );
      }
      starPath.lineTo(
        center.dx + innerRadius * math.cos(nextAngle),
        center.dy + innerRadius * math.sin(nextAngle),
      );
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);

    // 3. S & M Interlocking Monogram Curves
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [lightColor, primaryColor, deepColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stylized "S" curve on the left
    final sPath = Path();
    sPath.moveTo(w * 0.35, h * 0.33);
    sPath.cubicTo(w * 0.28, h * 0.33, w * 0.26, h * 0.42, w * 0.34, h * 0.49);
    sPath.cubicTo(w * 0.42, h * 0.56, w * 0.40, h * 0.67, w * 0.32, h * 0.67);
    canvas.drawPath(sPath, strokePaint);

    // Stylized "M" curves on the right
    final mPath = Path();
    mPath.moveTo(w * 0.50, h * 0.67);
    mPath.lineTo(w * 0.50, h * 0.33);
    mPath.lineTo(w * 0.62, h * 0.52);
    mPath.lineTo(w * 0.74, h * 0.33);
    mPath.lineTo(w * 0.74, h * 0.67);
    canvas.drawPath(mPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SmMonogramPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}
