import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/animation/animation_orchestrator.dart';

/// Overlay effect that creates a brief gem-like shatter burst at a point.
class GemShatterOverlay {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required Offset position,
    required Color color,
  }) {
    hide();

    final reduced = AnimationOrchestrator.instance.reducedMotion;
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (context) => _GemShatterWidget(
        position: position,
        color: color,
        reducedMotion: reduced,
        onDone: hide,
      ),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _GemShatterWidget extends StatefulWidget {
  final Offset position;
  final Color color;
  final bool reducedMotion;
  final VoidCallback onDone;

  const _GemShatterWidget({
    Key? key,
    required this.position,
    required this.color,
    required this.reducedMotion,
    required this.onDone,
  }) : super(key: key);

  @override
  State<_GemShatterWidget> createState() => _GemShatterWidgetState();
}

class _GemShatterWidgetState extends State<_GemShatterWidget>
    with TickerProviderStateMixin, OrchestrationMixin {
  late AnimationController _controller;
  late List<_Shard> _shards;

  @override
  void initState() {
    super.initState();

    // Use orchestrated controller with automatic lifecycle management
    _controller = getAnimationController(
      'shatter',
      duration: widget.reducedMotion
          ? const Duration(milliseconds: 260)
          : const Duration(milliseconds: 500),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          widget.onDone();
        }
      })
      ..addListener(() => setState(() {}));

    _shards = _createShards(widget.position, widget.color,
        reduced: widget.reducedMotion);
    _controller.forward();

    // Skip haptic feedback if reduced motion is enabled
    if (!widget.reducedMotion) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    // OrchestrationMixin automatically handles controller disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GemShatterPainter(
          shards: _shards,
          t: _controller.value,
          reduced: widget.reducedMotion,
        ),
      ),
    );
  }

  List<_Shard> _createShards(Offset origin, Color color,
      {bool reduced = false}) {
    final rng = math.Random();
    final count = reduced ? 6 : 14;
    final baseSpeed = reduced ? 120.0 : 220.0;
    final shards = <_Shard>[];
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (rng.nextDouble() - 0.5) * 0.4;
      final speed = baseSpeed * (0.7 + rng.nextDouble() * 0.6);
      final size = reduced
          ? (3.0 + rng.nextDouble() * 3.0)
          : (4.0 + rng.nextDouble() * 5.0);
      final rotSpeed = (rng.nextDouble() - 0.5) * (reduced ? 2.0 : 4.0);
      shards.add(_Shard(
        origin: origin,
        angle: angle,
        speed: speed,
        size: size,
        color: color,
        rotationSpeed: rotSpeed,
      ));
    }
    return shards;
  }
}

class _GemShatterPainter extends CustomPainter {
  final List<_Shard> shards;
  final double t; // 0..1
  final bool reduced;

  _GemShatterPainter({
    required this.shards,
    required this.t,
    required this.reduced,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fade = CurvedAnimation(
      parent: AlwaysStoppedAnimation(t),
      curve: reduced ? Curves.easeOut : Curves.easeOutCubic,
    ).value;

    final opacity = 1.0 - fade;
    for (final s in shards) {
      final dx = math.cos(s.angle) * s.speed * fade;
      final dy = math.sin(s.angle) * s.speed * fade;
      final pos = s.origin + Offset(dx, dy);

      final paint = Paint()
        ..color = s.color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      // Draw a simple triangle shard
      final path = Path();
      final rot = s.rotationSpeed * fade * math.pi;
      final p1 = _rotate(Offset(0, -s.size), rot);
      final p2 = _rotate(Offset(s.size * 0.6, s.size * 0.8), rot);
      final p3 = _rotate(Offset(-s.size * 0.6, s.size * 0.8), rot);

      path.moveTo(pos.dx + p1.dx, pos.dy + p1.dy);
      path.lineTo(pos.dx + p2.dx, pos.dy + p2.dy);
      path.lineTo(pos.dx + p3.dx, pos.dy + p3.dy);
      path.close();
      canvas.drawPath(path, paint);

      // Subtle glow at origin early on
      if (!reduced && t < 0.3) {
        final glowPaint = Paint()
          ..color = s.color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(s.origin, 18 * (1 - t / 0.3), glowPaint);
      }
    }
  }

  Offset _rotate(Offset o, double r) {
    final c = math.cos(r);
    final s = math.sin(r);
    return Offset(o.dx * c - o.dy * s, o.dx * s + o.dy * c);
  }

  @override
  bool shouldRepaint(covariant _GemShatterPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.shards != shards;
  }
}

class _Shard {
  final Offset origin;
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;

  _Shard({
    required this.origin,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}
