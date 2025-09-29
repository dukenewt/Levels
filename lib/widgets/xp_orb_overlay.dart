import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'dart:math';
import '../core/animation/animation_orchestrator.dart';
import '../debug/motion_debug.dart';

// Manages the overlay entry for the XP orbs
class XPOrbOverlay {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required Offset startPosition,
    required int xpAmount,
    Offset? targetPosition,
    VoidCallback? onOrbsArrive, // Callback when orbs reach the ring
  }) {
    // Remove existing overlay if any
    hide();

    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return XPOrbAnimationWidget(
          startPosition: startPosition,
          xpAmount: xpAmount,
          targetPosition: targetPosition,
          onAnimationComplete: hide,
          onOrbsArrive: onOrbsArrive,
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Convenience: compute start/target from widget GlobalKeys in overlay coords.
  static void showFromAnchors({
    required BuildContext context,
    required GlobalKey startKey,
    required GlobalKey targetKey,
    required int xpAmount,
    VoidCallback? onOrbsArrive,
  }) {
    final renderBoxStart =
        startKey.currentContext?.findRenderObject() as RenderBox?;
    final renderBoxTarget =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBoxStart == null || renderBoxTarget == null || overlay == null) {
      return;
    }
    final start = renderBoxStart.localToGlobal(Offset.zero, ancestor: overlay) +
        (renderBoxStart.size.center(Offset.zero));
    final target =
        renderBoxTarget.localToGlobal(Offset.zero, ancestor: overlay) +
            (renderBoxTarget.size.center(Offset.zero));
    show(
      context: context,
      startPosition: start,
      targetPosition: target,
      xpAmount: xpAmount,
      onOrbsArrive: onOrbsArrive,
    );
  }
}

// The main widget that handles the animation of multiple orbs
class XPOrbAnimationWidget extends StatefulWidget {
  final Offset startPosition;
  final int xpAmount;
  final VoidCallback onAnimationComplete;
  final Offset? targetPosition;
  final VoidCallback?
      onOrbsArrive; // Called when orbs reach target (~80% progress)

  const XPOrbAnimationWidget({
    Key? key,
    required this.startPosition,
    required this.xpAmount,
    this.targetPosition,
    required this.onAnimationComplete,
    this.onOrbsArrive,
  }) : super(key: key);

  @override
  _XPOrbAnimationWidgetState createState() => _XPOrbAnimationWidgetState();
}

class _XPOrbAnimationWidgetState extends State<XPOrbAnimationWidget>
    with TickerProviderStateMixin, OrchestrationMixin {
  late List<_Orb> _orbs;
  late AnimationController _controller;
  late Offset _target;
  bool _orbsArrived = false;
  late final bool _debugMarkers;

  @override
  void initState() {
    super.initState();
    _target = widget.targetPosition ?? const Offset(50.0, 50.0);
    _debugMarkers = MotionDebug.instance.showMarkers;
    _orbs = _createOrbs();
    _controller = getAnimationController(
      'xpOrbs',
      duration: const Duration(milliseconds: 1200),
    )
      ..addListener(() {
        // Notify when all orbs are >= 85% along their individual paths
        if (!_orbsArrived) {
          final allReached = _orbs.every((o) {
            final p = ((_controller.value - o.startTime) / (1.0 - o.startTime))
                .clamp(0.0, 1.0);
            return p >= 0.85;
          });
          if (allReached) {
            _orbsArrived = true;
            widget.onOrbsArrive?.call();
          }
        }
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete();
        }
      });

    // Start animation and light haptic (iOS-friendly), skip if reduced motion
    _controller.forward();
    if (!AnimationOrchestrator.instance.reducedMotion) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }

    // Timeline marker for profiling
    if (_debugMarkers) {
      dev.Timeline.startSync('xp_orb_flight');
    }
  }

  @override
  void dispose() {
    if (_debugMarkers) {
      dev.Timeline.finishSync();
    }
    // OrchestrationMixin automatically handles controller disposal
    super.dispose();
  }

  List<_Orb> _createOrbs() {
    // Create deterministic energy streams based on XP amount
    final reduced = AnimationOrchestrator.instance.reducedMotion;
    final baseStreamCount =
        (widget.xpAmount / 25).clamp(2, 6).round(); // 2-6 based on XP
    final streamCount =
        reduced ? (baseStreamCount * 0.6).round().clamp(2, 4) : baseStreamCount;

    return List.generate(streamCount, (index) {
      // Create evenly distributed direct paths to ring
      final streamAngle =
          (index / streamCount) * pi * 0.6 - (pi * 0.3); // 60° spread
      final directPath = _target - widget.startPosition;

      // Slight arc for visual appeal, but mostly direct
      final arcOffset = sin(streamAngle) * (reduced ? 15.0 : 25.0);
      final controlPoint = widget.startPosition +
          (directPath * 0.5) +
          Offset(arcOffset, -arcOffset.abs() * 0.5); // Slight upward arc

      return _Orb(
        startX: widget.startPosition.dx,
        startY: widget.startPosition.dy,
        controlX: controlPoint.dx,
        controlY: controlPoint.dy,
        endX: _target.dx,
        endY: _target.dy,
        startTime:
            index * (reduced ? 0.05 : 0.08), // More staggered for stream effect
        streamIndex: index, // Add stream identifier
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          foregroundPainter: _debugMarkers
              ? _MarkerPainter(
                  start: widget.startPosition,
                  target: _target,
                )
              : null,
          painter: _OrbPainter(
            orbs: _orbs,
            animationValue: _controller.value,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// Data class for a single energy stream's animation path
class _Orb {
  final double startX, startY, controlX, controlY, endX, endY;
  final double startTime; // Value from 0.0 to 1.0
  final int streamIndex; // Identifier for this stream

  _Orb({
    required this.startX,
    required this.startY,
    required this.controlX,
    required this.controlY,
    required this.endX,
    required this.endY,
    required this.startTime,
    required this.streamIndex,
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

// The painter that draws energy streams flowing to the ring
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
    for (final orb in orbs) {
      final progress =
          ((animationValue - orb.startTime) / (1.0 - orb.startTime))
              .clamp(0.0, 1.0);
      if (progress > 0) {
        _drawEnergyStream(canvas, orb, progress);
      }
    }
  }

  void _drawEnergyStream(Canvas canvas, _Orb orb, double progress) {
    // Simple energy particle moving along path
    if (progress <= 0) return;

    final currentPosition = orb.getPosition(progress + orb.startTime);

    // Better sized particles - ring is 14px thick, so make particles more visible
    final baseSize = 4.5; // Increased from 3.0 for better visibility
    final particleSize =
        baseSize + sin(progress * pi * 2) * 0.8; // More noticeable pulse

    // Improved visual with more contrast
    final particlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.5) // Increased glow for better visibility
      ..style = PaintingStyle.fill
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 3.5); // Slightly larger glow

    // Add a bright core for better visibility
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Draw layers: glow → particle → bright core
    canvas.drawCircle(currentPosition, particleSize * 1.6, glowPaint);
    canvas.drawCircle(currentPosition, particleSize, particlePaint);
    canvas.drawCircle(
        currentPosition, particleSize * 0.4, corePaint); // Bright center
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _MarkerPainter extends CustomPainter {
  final Offset start;
  final Offset target;
  const _MarkerPainter({required this.start, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final paintStart = Paint()
      ..color = const Color(0xff4caf50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final paintTarget = Paint()
      ..color = const Color(0xfff44336)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(start, 10, paintStart);
    canvas.drawLine(start, target, paintStart..strokeWidth = 1);
    canvas.drawCircle(target, 10, paintTarget);
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.target != target;
  }
}
