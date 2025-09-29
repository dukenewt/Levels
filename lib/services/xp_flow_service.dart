import 'package:flutter/widgets.dart';
import '../core/animation/ring_anchor.dart';
import '../widgets/xp_orb_overlay.dart';

/// Helper to visualize XP flowing from a source into the outer ring.
class XPFlowService {
  XPFlowService._();
  static final XPFlowService instance = XPFlowService._();

  void feedXP({
    required BuildContext context,
    required Offset startPosition,
    required int xpAmount,
    double? currentProgress, // Current XP progress (0.0 to 1.0)
    VoidCallback? onOrbsArrive, // Called when orbs reach the ring
  }) {
    // Add post-frame callback to ensure ring anchor is properly positioned
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Offset? target;

        // If we have current progress, target the end of the progress arc
        if (currentProgress != null) {
          target =
              RingAnchor.instance.getProgressEndpoint(context, currentProgress);
        }

        // Fallback to ring center if progress endpoint unavailable
        target ??= RingAnchor.instance.globalCenter(context);

        if (target == null) {
          target = _getScreenCenter(context);
        }

        XPOrbOverlay.show(
          context: context,
          startPosition: startPosition,
          xpAmount: xpAmount,
          targetPosition: target,
          onOrbsArrive: onOrbsArrive,
        );
      }
    });
  }

  /// Get screen center as fallback when ring anchor unavailable
  Offset _getScreenCenter(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Offset(
      mediaQuery.size.width / 2,
      mediaQuery.size.height / 2,
    );
  }
}
