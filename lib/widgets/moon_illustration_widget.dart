import 'dart:math' as math;
import 'package:flutter/material.dart';

class MoonIllustrationWidget extends StatelessWidget {
  final double size;

  const MoonIllustrationWidget({
    super.key,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoonPainter(),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.58, size.height * 0.48);
    final radius = size.width * 0.38;

    // Draw background 4-pointed stars/sparkles
    _drawSparkle(canvas, Offset(size.width * 0.12, size.height * 0.22), 12, 0.45);
    _drawSparkle(canvas, Offset(size.width * 0.05, size.height * 0.65), 7, 0.35);
    _drawSparkle(canvas, Offset(size.width * 0.28, size.height * 0.82), 9, 0.40);
    _drawSparkle(canvas, Offset(size.width * 0.95, size.height * 0.18), 10, 0.40);
    _drawSparkle(canvas, Offset(size.width * 0.98, size.height * 0.70), 11, 0.45);
    _drawSparkle(canvas, Offset(size.width * 0.78, size.height * 0.08), 8, 0.35);

    // Main Moon Base Circle (Gradient)
    final moonPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFE4F1F0),
          Color(0xFFC7DCDB),
          Color(0xFFB0C9C7),
        ],
        center: Alignment(-0.3, -0.3),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Moon Shadow / 3D Edge Shader
    canvas.drawCircle(center, radius, moonPaint);

    // Craters on Moon Surface
    final craterPaint = Paint()
      ..color = const Color(0xFF9EBBB9).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy + radius * 0.25), radius * 0.18, craterPaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.25, center.dy + radius * 0.1), radius * 0.15, craterPaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.05, center.dy + radius * 0.45), radius * 0.12, craterPaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.35, center.dy - radius * 0.2), radius * 0.14, craterPaint);
    canvas.drawCircle(Offset(center.dx - radius * 0.2, center.dy - radius * 0.35), radius * 0.10, craterPaint);

    // Subtle crescent inner shadow for 3D depth
    final shadowPaint = Paint()
      ..color = const Color(0xFF1B3B39).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(center.dx - radius * 0.25, center.dy - radius * 0.25), radius: radius * 1.05));
    
    final shadowPath = Path.combine(PathOperation.difference, path, clipPath);
    canvas.drawPath(shadowPath, shadowPaint);
  }

  void _drawSparkle(Canvas canvas, Offset position, double armLength, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    final innerRadius = armLength * 0.25;

    for (int i = 0; i < 8; i++) {
      final r = (i % 2 == 0) ? armLength : innerRadius;
      final angle = i * math.pi / 4;
      final x = position.dx + r * math.cos(angle);
      final y = position.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
