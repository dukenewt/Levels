import 'package:flutter/material.dart';
import 'dart:math' as math;

class SkillProgressWheel extends StatelessWidget {
  final double progress;
  final Color color;

  const SkillProgressWheel({
    Key? key,
    required this.progress,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: SkillProgressWheelPainter(
          progress: progress,
          color: color,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ),
    );
  }
}

class SkillProgressWheelPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  SkillProgressWheelPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const ringWidth = 12.0;

    // Background ring
    _drawBackgroundRing(canvas, center, radius, ringWidth);

    // Progress ring
    _drawProgressRing(canvas, center, radius, ringWidth, progress, color);
  }

  void _drawBackgroundRing(
      Canvas canvas, Offset center, double radius, double strokeWidth) {
    final paint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawProgressRing(Canvas canvas, Offset center, double radius,
      double strokeWidth, double progress, Color color) {
    if (progress <= 0) return;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withOpacity(0.3),
        color,
        color.withOpacity(0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SkillProgressWheelPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
