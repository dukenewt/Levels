import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedXPBar extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;
  final AnimationType animationType;
  final Duration duration;

  const AnimatedXPBar({
    Key? key,
    required this.progress,
    required this.color,
    this.height = 8.0,
    this.animationType = AnimationType.liquid,
    this.duration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<AnimatedXPBar> createState() => _AnimatedXPBarState();
}

enum AnimationType {
  liquid,
  segmented,
  pulse,
  morphing,
}

class _AnimatedXPBarState extends State<AnimatedXPBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late List<Animation<double>> _segmentAnimations;
  late List<Animation<double>> _pulseAnimations;
  late List<Animation<double>> _waveAnimations;
  final int _numSegments = 10;
  final int _numPulses = 3;
  final int _numWaves = 3;

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

    // Initialize segment animations with scale effect
    _segmentAnimations = List.generate(_numSegments, (index) {
      final delay = index * (widget.duration.inMilliseconds ~/ _numSegments);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            delay / widget.duration.inMilliseconds,
            (delay + widget.duration.inMilliseconds ~/ _numSegments) / widget.duration.inMilliseconds,
            curve: Curves.elasticOut,
          ),
        ),
      );
    });

    // Initialize pulse animations with fade effect
    _pulseAnimations = List.generate(_numPulses, (index) {
      final delay = index * (widget.duration.inMilliseconds ~/ _numPulses);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            delay / widget.duration.inMilliseconds,
            (delay + widget.duration.inMilliseconds ~/ _numPulses) / widget.duration.inMilliseconds,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    // Initialize wave animations for liquid effect
    _waveAnimations = List.generate(_numWaves, (index) {
      final delay = index * (widget.duration.inMilliseconds ~/ _numWaves);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            delay / widget.duration.inMilliseconds,
            (delay + widget.duration.inMilliseconds ~/ _numWaves) / widget.duration.inMilliseconds,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _controller.forward();
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        switch (widget.animationType) {
          case AnimationType.liquid:
            return _buildLiquidAnimation();
          case AnimationType.segmented:
            return _buildSegmentedAnimation();
          case AnimationType.pulse:
            return _buildPulseAnimation();
          case AnimationType.morphing:
            return _buildMorphingAnimation();
        }
      },
    );
  }

  Widget _buildLiquidAnimation() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: Stack(
        children: [
          Container(
            height: widget.height,
            color: widget.color.withOpacity(0.1),
          ),
          FractionallySizedBox(
            widthFactor: _progressAnimation.value,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: List.generate(_numWaves, (index) {
                  return CustomPaint(
                    painter: LiquidFillPainter(
                      color: widget.color,
                      progress: _progressAnimation.value,
                      waveAnimation: _waveAnimations[index],
                      waveIndex: index,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedAnimation() {
    return Row(
      children: List.generate(_numSegments, (index) {
        final segmentWidth = 1.0 / _numSegments;
        final segmentProgress = math.max(0, math.min(1, (_progressAnimation.value - index * segmentWidth) / segmentWidth));
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: widget.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: Stack(
                children: [
                  Container(color: widget.color.withOpacity(0.1)),
                  Transform.scale(
                    scale: 0.8 + (_segmentAnimations[index].value * 0.2),
                    child: FractionallySizedBox(
                      widthFactor: _segmentAnimations[index].value * segmentProgress,
                      child: Container(
                        color: widget.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPulseAnimation() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Stack(
            children: [
              Container(
                height: widget.height,
                color: widget.color.withOpacity(0.1),
              ),
              FractionallySizedBox(
                widthFactor: _progressAnimation.value,
                child: Container(
                  height: widget.height,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(_numPulses, (index) {
          return Positioned(
            left: _pulseAnimations[index].value * MediaQuery.of(context).size.width,
            child: Container(
              height: widget.height,
              width: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0),
                    widget.color.withOpacity(0.8),
                    widget.color.withOpacity(0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMorphingAnimation() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: Stack(
        children: [
          Container(
            height: widget.height,
            color: widget.color.withOpacity(0.1),
          ),
          FractionallySizedBox(
            widthFactor: _progressAnimation.value,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(
                  widget.height / 2 * (1 + math.sin(_controller.value * math.pi * 2) * 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(
                      math.sin(_controller.value * math.pi * 2) * 2,
                      math.cos(_controller.value * math.pi * 2) * 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiquidFillPainter extends CustomPainter {
  final Color color;
  final double progress;
  final Animation<double> waveAnimation;
  final int waveIndex;

  LiquidFillPainter({
    required this.color,
    required this.progress,
    required this.waveAnimation,
    required this.waveIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7 - (waveIndex * 0.2))
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.3;
    final frequency = 3.0 + waveIndex;
    final phase = waveAnimation.value * math.pi * 2;

    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height - (waveHeight * math.sin((x / size.width * frequency * math.pi) + phase));
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LiquidFillPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveAnimation.value != waveAnimation.value;
  }
} 