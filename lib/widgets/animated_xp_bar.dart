import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedXPBar extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  final bool shimmer;
  final Duration duration;
  final Duration shimmerDuration;

  const AnimatedXPBar({
    Key? key,
    required this.progress,
    required this.color,
    this.height = 8.0,
    this.shimmer = false,
    this.duration = const Duration(milliseconds: 1000),
    this.shimmerDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<AnimatedXPBar> createState() => _AnimatedXPBarState();
}

class _AnimatedXPBarState extends State<AnimatedXPBar> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late AnimationController _shimmerController;
  bool _showShimmer = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration,
    );
    if (widget.shimmer) {
      _showShimmer = true;
      _shimmerController.repeat();
      Future.delayed(widget.shimmerDuration, () {
        if (mounted) {
          setState(() {
            _showShimmer = false;
            _shimmerController.stop();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedXPBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
    if (widget.shimmer && !_showShimmer) {
      _showShimmer = true;
      _shimmerController.duration = widget.shimmerDuration;
      _shimmerController.repeat();
      Future.delayed(widget.shimmerDuration, () {
        if (mounted) {
          setState(() {
            _showShimmer = false;
            _shimmerController.stop();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _shimmerController]),
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: widget.height,
          child: CustomPaint(
            painter: GradientXPBarPainter(
              progress: _progressAnimation.value,
              color: widget.color,
              shimmer: _showShimmer,
              shimmerValue: _shimmerController.value,
            ),
          ),
        );
      },
    );
  }
}

class GradientXPBarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool shimmer;
  final double shimmerValue;

  GradientXPBarPainter({
    required this.progress,
    required this.color,
    required this.shimmer,
    required this.shimmerValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barRadius = Radius.circular(size.height / 2);
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, barRadius);
    canvas.drawRRect(rrect, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);

    final fillWidth = size.width * progress.clamp(0.0, 1.0);
    if (fillWidth <= 0) return;
    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    final fillRRect = RRect.fromRectAndRadius(fillRect, barRadius);

    // Gradient colors
    final List<Color> gradientColors = [
      color.withOpacity(0.95),
      color.withOpacity(0.8),
      color.withOpacity(0.95),
    ];
    final List<double> stops = [0.0, 0.5, 1.0];

    // Shimmer effect overlay
    Shader? shader;
    if (shimmer) {
      final shimmerWidth = size.width * 0.5;
      final shimmerStart = shimmerValue * (size.width + shimmerWidth) - shimmerWidth;
      shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.amberAccent.withOpacity(0.9),
          Colors.white.withOpacity(0.95),
          Colors.amberAccent.withOpacity(0.9),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment(-1.0 + 2 * shimmerStart / size.width, 0),
        end: Alignment(-1.0 + 2 * (shimmerStart + shimmerWidth) / size.width, 0),
        tileMode: TileMode.clamp,
      ).createShader(fillRect);
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        stops: stops,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(fillRect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(fillRRect, fillPaint);

    if (shimmer && shader != null) {
      final shimmerPaint = Paint()
        ..shader = shader
        ..blendMode = BlendMode.plus;
      canvas.drawRRect(fillRRect, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GradientXPBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.shimmerValue != shimmerValue;
  }
} 