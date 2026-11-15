import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.pr,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: CustomPaint(
        painter: _LogoPainter(color: colors.prt),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    final strokeWidth = 2.6 * scale;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hanger hook
    final hookPath = Path();
    hookPath.moveTo(24 * scale, 15.5 * scale);
    hookPath.lineTo(24 * scale, 14 * scale);
    hookPath.arcToPoint(
      Offset(27.2 * scale, 17.2 * scale),
      radius: Radius.circular(3.2 * scale),
      clockwise: false,
    );
    canvas.drawPath(hookPath, paint);

    // Hanger triangle
    final trianglePath = Path();
    trianglePath.moveTo(24 * scale, 17.5 * scale);
    trianglePath.lineTo(10.5 * scale, 28.5 * scale);
    trianglePath.lineTo(37.5 * scale, 28.5 * scale);
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);

    // Bottom wave/clothes line
    final wavePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final wavePath = Path();
    wavePath.moveTo(15 * scale, 37 * scale);
    wavePath.cubicTo(
      18 * scale, 34.6 * scale,
      20.4 * scale, 39.4 * scale,
      24 * scale, 37 * scale,
    );
    wavePath.cubicTo(
      27.6 * scale, 34.6 * scale,
      30 * scale, 39.4 * scale,
      33 * scale, 37 * scale,
    );
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.color != color;
}
