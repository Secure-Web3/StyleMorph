import 'package:flutter/material.dart';

/// Official matte obsidian background color sampled from `sm_logo.png`.
const Color kSplashObsidianBackground = Color(0xFF0D0D0F);

/// Unified luxury dark obsidian splash screen featuring the transparent
/// `sm_logo_transparent.png` centered at 168×168 on `#0D0D0F` with a clipped
/// diagonal metallic gold sheen sweep.
class UnifiedSplashScreen extends StatefulWidget {
  final bool animate;

  const UnifiedSplashScreen({super.key, this.animate = true});

  @override
  State<UnifiedSplashScreen> createState() => _UnifiedSplashScreenState();
}

class _UnifiedSplashScreenState extends State<UnifiedSplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _logoAsset =
      'assets/images/brand/sm_logo_transparent.png';
  static const double _logoSize = 168.0;

  late final AnimationController _controller;
  late final Animation<double> _sheenProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Sweep from 0.0..0.72 with luxury easing, leaving a brief calm pause (0.72..1.0).
    _sheenProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeInOutCubic),
      ),
    );

    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(covariant UnifiedSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSplashObsidianBackground,
      body: Center(
        child: SizedBox(
          width: _logoSize,
          height: _logoSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ultra-soft radial champagne ambient glow seamlessly fading into #0D0D0F.
              Container(
                width: _logoSize,
                height: _logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFD4AF37).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),

              // Base layer: true transparent RGBA SM monogram & star.
              Opacity(
                opacity: 0.92,
                child: Image.asset(
                  _logoAsset,
                  width: _logoSize,
                  height: _logoSize,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),

              // Sheen overlay: clipped strictly to non-transparent logo pixels via
              // BlendMode.srcIn so the #0D0D0F background is never touched.
              AnimatedBuilder(
                animation: _sheenProgress,
                builder: (context, child) {
                  final t = _sheenProgress.value;
                  final shift = -1.6 + (3.2 * t);
                  return ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment(shift - 0.65, shift - 0.65),
                        end: Alignment(shift + 0.65, shift + 0.65),
                        colors: const [
                          Colors.transparent,
                          Color(0x66D4AF37),
                          Color(0xF5FFF6D1),
                          Color(0x66D4AF37),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: Image.asset(
                  _logoAsset,
                  width: _logoSize,
                  height: _logoSize,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
