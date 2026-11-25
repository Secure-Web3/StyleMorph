import 'package:flutter/material.dart';

/// Official matte obsidian background color sampled from `sm_logo.png`.
const Color kSplashObsidianBackground = Color(0xFF0D0D0F);

/// Unified luxury dark obsidian splash screen featuring the official `sm_logo.png`
/// centered on `#0D0D0F` with a continuous diagonal metallic gold sheen sweep.
class UnifiedSplashScreen extends StatefulWidget {
  final bool animate;

  const UnifiedSplashScreen({super.key, this.animate = true});

  @override
  State<UnifiedSplashScreen> createState() => _UnifiedSplashScreenState();
}

class _UnifiedSplashScreenState extends State<UnifiedSplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _logoAsset = 'assets/images/brand/sm_logo.png';
  static const double _logoSize = 180.0;

  late final AnimationController _controller;
  late final Animation<double> _sheenProgress;

  /// Isolates only the gold monogram/star strokes by mapping dark obsidian
  /// background pixels (`R,G,B <= 42`) to full transparency (`alpha = 0`),
  /// preventing any square box flash during the diagonal sheen sweep.
  static const ColorFilter _goldStrokeIsolator = ColorFilter.matrix(<double>[
    1.35,
    0.0,
    0.0,
    0.0,
    -45.0,
    0.0,
    1.35,
    0.0,
    0.0,
    -45.0,
    0.0,
    0.0,
    1.35,
    0.0,
    -45.0,
    0.9,
    0.9,
    0.0,
    0.0,
    -80.0,
  ]);

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
              // Base layer: official sm_logo.png with soft outer edge feathering
              // so its dark corners blend seamlessly into #0D0D0F.
              ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (Rect bounds) {
                  return const RadialGradient(
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.68, 0.98],
                  ).createShader(bounds);
                },
                child: Image.asset(
                  _logoAsset,
                  width: _logoSize,
                  height: _logoSize,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),

              // Overlay layer: diagonal metallic champagne-gold sheen sweeping
              // exclusively across the illuminated gold strokes.
              AnimatedBuilder(
                animation: _sheenProgress,
                builder: (context, child) {
                  final t = _sheenProgress.value;
                  // Sweep diagonally from top-left (-1.8) to bottom-right (+1.8).
                  final centerShift = -1.8 + (3.6 * t);
                  return ShaderMask(
                    blendMode: BlendMode.modulate,
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment(
                          centerShift - 0.65,
                          centerShift - 0.65,
                        ),
                        end: Alignment(centerShift + 0.65, centerShift + 0.65),
                        colors: const [
                          Colors.transparent,
                          Color(0x66B8860B),
                          Color(0xDDFFD97D),
                          Color(0xFFFFF6D6),
                          Color(0xDDFFD97D),
                          Color(0x66B8860B),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.22, 0.40, 0.50, 0.60, 0.78, 1.0],
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: ColorFiltered(
                  colorFilter: _goldStrokeIsolator,
                  child: Image.asset(
                    _logoAsset,
                    width: _logoSize,
                    height: _logoSize,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
