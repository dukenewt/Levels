import 'package:flutter/material.dart';
import 'dart:math';

// Manages the overlay entry for the XP orbs
class XPOrbOverlay {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required Offset startPosition,
    required int xpAmount,
  }) {
    // Remove existing overlay if any
    hide();

    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return XPOrbAnimationWidget(
          startPosition: startPosition,
          xpAmount: xpAmount,
          onAnimationComplete: hide,
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// The main widget that handles the animation of multiple orbs
class XPOrbAnimationWidget extends StatefulWidget {
  final Offset startPosition;
  final int xpAmount;
  final VoidCallback onAnimationComplete;

  const XPOrbAnimationWidget({
    Key? key,
    required this.startPosition,
    required this.xpAmount,
    required this.onAnimationComplete,
  }) : super(key: key);

  @override
  _XPOrbAnimationWidgetState createState() => _XPOrbAnimationWidgetState();
}

class _XPOrbAnimationWidgetState extends State<XPOrbAnimationWidget>
    with TickerProviderStateMixin {
  late List<_Orb> _orbs;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _orbs = _createOrbs();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..addListener(() {
        setState(() {});
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Orb> _createOrbs() {
    final random = Random();
    // Create fewer orbs for small XP amounts for performance and clarity
    final orbCount = (widget.xpAmount / 5).clamp(1, 15).toInt();
    
    return List.generate(orbCount, (index) {
      // Spread orbs out in an arc
      final angle = (random.nextDouble() - 0.5) * pi * 0.8; 
      final distance = random.nextDouble() * 50 + 20;

      return _Orb(
        startX: widget.startPosition.dx,
        startY: widget.startPosition.dy,
        controlX: widget.startPosition.dx + cos(angle) * distance * 2,
        controlY: widget.startPosition.dy + sin(angle) * distance - 100, // Move upwards
        endX: 50.0, // Target X (e.g., corner of the screen)
        endY: 50.0, // Target Y (e.g., corner of the screen)
        startTime: index * 0.05, // Stagger start times
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _OrbPainter(
          orbs: _orbs,
          animationValue: _controller.value,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// Data class for a single orb's animation path
class _Orb {
  final double startX, startY, controlX, controlY, endX, endY;
  final double startTime; // Value from 0.0 to 1.0

  _Orb({
    required this.startX,
    required this.startY,
    required this.controlX,
    required this.controlY,
    required this.endX,
    required this.endY,
    required this.startTime,
  });

  Offset getPosition(double t) {
    // Only start moving after startTime
    final progress = ((t - startTime) / (1.0 - startTime)).clamp(0.0, 1.0);
    
    if (progress <= 0) return Offset(startX, startY);

    // Quadratic bezier curve for the path
    final oneMinusT = 1.0 - progress;
    final x = oneMinusT * oneMinusT * startX +
              2 * oneMinusT * progress * controlX +
              progress * progress * endX;
    final y = oneMinusT * oneMinusT * startY +
              2 * oneMinusT * progress * controlY +
              progress * progress * endY;
    return Offset(x, y);
  }
}

// The painter that draws all the orbs
class _OrbPainter extends CustomPainter {
  final List<_Orb> orbs;
  final double animationValue;
  final Color color;

  _OrbPainter({
    required this.orbs,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    
    for (final orb in orbs) {
      final progress = ((animationValue - orb.startTime) / (1.0 - orb.startTime)).clamp(0.0, 1.0);
      if (progress > 0) {
        final position = orb.getPosition(animationValue);
        // Fade out and shrink the orb as it nears the end
        final sizeFactor = (1.0 - progress * 0.7).clamp(0.3, 1.0);
        paint.color = color.withOpacity((1.0 - progress).clamp(0.0, 1.0));
        canvas.drawCircle(position, 5.0 * sizeFactor, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 