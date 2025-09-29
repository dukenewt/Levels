import 'package:flutter/widgets.dart';
import 'dart:math' as math;

/// Singleton to expose the global position/size of the primary XP ring.
class RingAnchor {
  RingAnchor._();
  static final RingAnchor instance = RingAnchor._();

  /// Attach this key to the widget that visually represents the outer ring.
  final GlobalKey ringKey = GlobalKey(debugLabel: 'OuterRingAnchor');

  Rect? globalBounds(BuildContext context) {
    final ctx = ringKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Offset? globalCenter(BuildContext context) {
    final r = globalBounds(context);
    if (r == null) return null;
    return r.center;
  }

  /// Calculate the endpoint of the current XP progress arc
  Offset? getProgressEndpoint(BuildContext context, double progress) {
    final bounds = globalBounds(context);
    if (bounds == null) return null;

    final center = bounds.center;

    // Match exact calculation from WheelOfTimeRingsPainter
    final maxRadius = bounds.width / 2;
    final outerRadius = maxRadius - 10; // This is the XP progress ring radius

    // Ring starts at top (-pi/2) and progresses clockwise
    final startAngle = -math.pi / 2;
    final currentAngle = startAngle + (2 * math.pi * progress);

    // Calculate the position at the current progress point
    final endX = center.dx + math.cos(currentAngle) * outerRadius;
    final endY = center.dy + math.sin(currentAngle) * outerRadius;

    return Offset(endX, endY);
  }
}
