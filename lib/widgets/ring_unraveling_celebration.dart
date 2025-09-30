import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_design_tokens.dart';
import 'dart:math' as math;
import '../core/animation/animation_orchestrator.dart';

/// The foundation for your ring unraveling celebration animation
/// This breaks down the complex animation into understandable phases
class RingUnravelingCelebration extends StatefulWidget {
  final double initialProgress; // Current XP progress (0.0 to 1.0)
  final int oldLevel;
  final int newLevel;
  final Color ringColor;
  final List<String> unlockedPerks;
  final VoidCallback onComplete;

  const RingUnravelingCelebration({
    Key? key,
    required this.initialProgress,
    required this.oldLevel,
    required this.newLevel,
    required this.ringColor,
    required this.unlockedPerks,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<RingUnravelingCelebration> createState() =>
      _RingUnravelingCelebrationState();
}

class _RingUnravelingCelebrationState extends State<RingUnravelingCelebration>
    with TickerProviderStateMixin, OrchestrationMixin {
  // Phase controllers - each controls a different part of the animation
  late AnimationController _unravelController;
  late AnimationController _expansionController;
  late AnimationController _reformController;

  // Animation values that drive the visual effects
  late Animation<double> _unravelAnimation;
  late Animation<double> _expansionAnimation;
  late Animation<double> _reformAnimation;

  // Current animation phase tracking
  AnimationPhase _currentPhase = AnimationPhase.initial;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startCelebration();
  }

  void _setupAnimations() {
    // Phase 1: Unraveling (the ring breaks apart into segments)
    _unravelController = getAnimationController(
      'unravel',
      duration: AppDesignTokens.ringUnravel,
    );
    _unravelAnimation = createAnimation(
      _unravelController,
      Tween<double>(begin: 0.0, end: 1.0),
      curve: AppDesignTokens.asmrEase,
    );

    // Phase 2: Expansion (segments spread across screen showing celebration)
    _expansionController = getAnimationController(
      'expansion',
      duration: AppDesignTokens.ringExpand,
    );
    _expansionAnimation = createAnimation(
      _expansionController,
      Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
    );

    // Phase 3: Reformation (segments come back together as new ring)
    _reformController = getAnimationController(
      'reform',
      duration: AppDesignTokens.ringReform,
    );
    _reformAnimation = createAnimation(
      _reformController,
      Tween<double>(begin: 0.0, end: 1.0),
      curve: AppDesignTokens.reformEase,
    );
  }

  void _startCelebration() async {
    // Orchestrate the phases to avoid conflicts and respect Reduced Motion
    await runAnimationSequence('ringCelebration', [
      AnimationStep.custom(() async {
        if (mounted) setState(() => _currentPhase = AnimationPhase.unraveling);
        try {
          await HapticFeedback.selectionClick();
        } catch (_) {}
      }),
      AnimationStep(
          type: AnimationStepType.forward, controller: _unravelController),
      AnimationStep.custom(() async {
        if (mounted) setState(() => _currentPhase = AnimationPhase.expanding);
        try {
          await HapticFeedback.lightImpact();
        } catch (_) {}
      }),
      AnimationStep(
          type: AnimationStepType.forward, controller: _expansionController),
      AnimationStep(
          type: AnimationStepType.delay,
          duration: AnimationOrchestrator.instance.reducedMotion
              ? const Duration(milliseconds: 800)
              : const Duration(milliseconds: 1200)),
      AnimationStep.custom(() async {
        if (mounted) setState(() => _currentPhase = AnimationPhase.reforming);
        try {
          await HapticFeedback.selectionClick();
        } catch (_) {}
      }),
      AnimationStep(
          type: AnimationStepType.forward, controller: _reformController),
      AnimationStep.custom(() async {
        if (mounted) widget.onComplete();
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black
          .withOpacity(0.85), // Slightly darker overlay for better contrast
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _handleDoubleTapDismiss,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: AnimatedBuilder(
            // Listen to all animation controllers
            animation: Listenable.merge([
              _unravelController,
              _expansionController,
              _reformController,
            ]),
            builder: (context, child) {
              return SizedBox.expand(
                child: CustomPaint(
                  painter: RingCelebrationPainter(
                    progress: widget.initialProgress,
                    unravelProgress: _unravelAnimation.value,
                    expansionProgress: _expansionAnimation.value,
                    reformProgress: _reformAnimation.value,
                    currentPhase: _currentPhase,
                    ringColor: widget.ringColor,
                    oldLevel: widget.oldLevel,
                    newLevel: widget.newLevel,
                    unlockedPerks: widget.unlockedPerks,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleDoubleTapDismiss() {
    // Fast path to reform and complete
    runAnimationSequence('ringEarlyDismiss', [
      AnimationStep.custom(() async {
        if (!mounted) return;
        setState(() => _currentPhase = AnimationPhase.reforming);
        try {
          _unravelController.stop();
          _expansionController.stop();
        } catch (_) {}
        try {
          _reformController.reset();
        } catch (_) {}
      }),
      AnimationStep(
          type: AnimationStepType.forward, controller: _reformController),
      AnimationStep.custom(() async {
        if (mounted) widget.onComplete();
      }),
    ]);
  }

  @override
  void dispose() {
    // Controllers are managed/disposed by OrchestrationMixin
    super.dispose();
  }
}

/// Custom painter that handles all the visual magic
/// This is where we transform the ring through its different states
class RingCelebrationPainter extends CustomPainter {
  final double progress;
  final double unravelProgress;
  final double expansionProgress;
  final double reformProgress;
  final AnimationPhase currentPhase;
  final Color ringColor;
  final int oldLevel;
  final int newLevel;
  final List<String> unlockedPerks;

  // Optimized segment count for better performance
  static const int segmentCount = 60;

  RingCelebrationPainter({
    required this.progress,
    required this.unravelProgress,
    required this.expansionProgress,
    required this.reformProgress,
    required this.currentPhase,
    required this.ringColor,
    required this.oldLevel,
    required this.newLevel,
    required this.unlockedPerks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 4;

    switch (currentPhase) {
      case AnimationPhase.initial:
        _drawInitialRing(canvas, center, radius);
        break;
      case AnimationPhase.unraveling:
        _drawUnravelingRing(canvas, center, radius);
        break;
      case AnimationPhase.expanding:
        _drawExpandedCelebration(canvas, size, center);
        break;
      case AnimationPhase.reforming:
        _drawReformingRing(canvas, center, radius);
        break;
    }
  }

  void _drawInitialRing(Canvas canvas, Offset center, double radius) {
    // Draw the original progress ring with XP bar styling
    _drawXPStyleRing(canvas, center, radius, progress, 1.0);
  }

  void _drawXPStyleRing(Canvas canvas, Offset center, double radius,
      double progressValue, double opacity) {
    // Create XP bar gradient colors
    final gradientColors = [
      ringColor.withOpacity(0.6 * opacity),
      ringColor.withOpacity(opacity),
      ringColor.withOpacity(0.8 * opacity),
    ];

    // Background track
    final backgroundPaint = Paint()
      ..color = ringColor.withOpacity(0.15 * opacity)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress fill with gradient
    if (progressValue > 0) {
      final sweepAngle = 2 * math.pi * progressValue;
      final rect = Rect.fromCircle(center: center, radius: radius);

      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: gradientColors,
        stops: const [0.0, 0.5, 1.0],
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Add glow effect
      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.4 * opacity)
        ..strokeWidth = 20
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  void _drawUnravelingRing(Canvas canvas, Offset center, double radius) {
    // Calculate how many segments to show based on original progress
    final activeSegments = (segmentCount * progress).round();

    // Create gradient colors for the XP bar effect
    final baseColors = [
      ringColor.withOpacity(0.6),
      ringColor,
      ringColor.withOpacity(0.8),
    ];

    for (int i = 0; i < activeSegments; i++) {
      final segmentProgress = i / activeSegments;
      final segmentAngle = (2 * math.pi * progress) / activeSegments;
      final startAngle = -math.pi / 2 + (i * segmentAngle);

      // Enhanced unraveling with variable timing
      final unravelDelay = segmentProgress * 0.3; // Stagger the unraveling
      final adjustedUnravelProgress = math
          .max(0.0, math.min(1.0, (unravelProgress - unravelDelay) / 0.7))
          .toDouble();

      if (adjustedUnravelProgress <= 0) {
        // Still part of the ring - draw as connected segment
        final segmentPaint = Paint()
          ..color = baseColors[1]
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle * 0.9,
          false,
          segmentPaint,
        );
      } else {
        // Unraveling - break into dots with physics-like movement
        final unravelFactor = adjustedUnravelProgress;

        // Simplified curved trajectory using easing
        final easedProgress =
            Curves.easeOutCubic.transform(unravelFactor).toDouble();
        final maxDistance =
            150.0 + (segmentProgress * 50.0); // Varying distances
        final currentDistance = radius + (maxDistance * easedProgress);

        // Gentle arc movement instead of complex physics
        final arcAmount = math.sin(easedProgress * math.pi) * 20.0;
        final arcAngle = startAngle + (arcAmount / currentDistance);

        final dotCenter = Offset(
          center.dx + math.cos(arcAngle) * currentDistance,
          center.dy + math.sin(arcAngle) * currentDistance,
        );

        // Variable dot sizes based on position and timing
        final baseDotSize =
            6.0 + (segmentProgress * 2.0); // 6-8 range (smaller)
        final sizePulse =
            1.0 + (math.sin(easedProgress * 8) * 0.2); // Gentler pulse
        final dotSize = baseDotSize *
            sizePulse *
            (1.0 - easedProgress * 0.2); // Subtle shrinking

        // Color based on position in the gradient
        final colorIndex = (segmentProgress * (baseColors.length - 1)).floor();
        final colorLerp =
            (segmentProgress * (baseColors.length - 1)) - colorIndex;
        final dotColor = colorIndex < baseColors.length - 1
            ? Color.lerp(
                baseColors[colorIndex], baseColors[colorIndex + 1], colorLerp)!
            : baseColors.last;

        // Create multiple paint layers for enhanced visual effect
        final glowPaint = Paint()
          ..color = dotColor.withOpacity(0.6 * (1.0 - unravelFactor * 0.5))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotSize * 0.8);

        final dotPaint = Paint()
          ..color = dotColor.withOpacity(1.0 - unravelFactor * 0.3)
          ..style = PaintingStyle.fill;

        // Draw glow first, then dot
        canvas.drawCircle(dotCenter, dotSize * 1.5, glowPaint);
        canvas.drawCircle(dotCenter, dotSize, dotPaint);

        // Add trailing effect for faster-moving dots
        if (unravelFactor > 0.3) {
          final trailPaint = Paint()
            ..color = dotColor.withOpacity(0.3 * (1.0 - unravelFactor))
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;

          final trailStart = Offset(
            dotCenter.dx - math.cos(startAngle) * dotSize * 2,
            dotCenter.dy - math.sin(startAngle) * dotSize * 2,
          );

          canvas.drawLine(trailStart, dotCenter, trailPaint);
        }
      }
    }
  }

  void _drawExpandedCelebration(Canvas canvas, Size size, Offset center) {
    // This is where the magic happens - show the celebration content

    // Draw background effect
    _drawExpansionBackground(canvas, size, center);

    // Draw level up text
    _drawLevelUpText(canvas, size, center);

    // Draw unlocked perks
    _drawUnlockedPerks(canvas, size, center);

    // Draw scattered segments as enhanced floating dots
    _drawEnhancedScatteredSegments(canvas, size, center);
  }

  void _drawExpansionBackground(Canvas canvas, Size size, Offset center) {
    // Create a radial gradient background that pulses with the expansion
    final gradient = RadialGradient(
      colors: [
        ringColor.withOpacity(0.4 * expansionProgress),
        ringColor.withOpacity(0.2 * expansionProgress),
        ringColor.withOpacity(0.05 * expansionProgress),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
            center: center, radius: size.width * expansionProgress * 0.8),
      );

    canvas.drawCircle(center, size.width * expansionProgress * 0.8, paint);
  }

  void _drawLevelUpText(Canvas canvas, Size size, Offset center) {
    // Draw the main level up announcement with enhanced styling
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'LEVEL ${newLevel}!',
        style: TextStyle(
          fontSize: (56 * expansionProgress).toDouble(),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            Shadow(
              color: ringColor.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2 - 60,
    );

    // Only show when expansion is significant
    if (expansionProgress > 0.2) {
      // Add glow effect behind text
      final glowPainter = TextPainter(
        text: TextSpan(
          text: 'LEVEL ${newLevel}!',
          style: TextStyle(
            fontSize: (56 * expansionProgress).toDouble(),
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..color = ringColor.withOpacity(0.5)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      glowPainter.layout();
      glowPainter.paint(canvas, textOffset);
      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawUnlockedPerks(Canvas canvas, Size size, Offset center) {
    // Draw the unlocked perks as they animate in
    if (unlockedPerks.isEmpty || expansionProgress < 0.4) return;

    for (int i = 0; i < unlockedPerks.length; i++) {
      final perkProgress = math.max(
          0, (expansionProgress - 0.4) * 1.67); // Start after main text
      if (perkProgress <= 0) continue;

      final angle = (i * 2 * math.pi / unlockedPerks.length) - math.pi / 2;
      final baseDistance = 140;
      final animatedDistance = baseDistance * (0.5 + perkProgress * 0.5);

      final perkOffset = Offset(
        center.dx + math.cos(angle) * animatedDistance,
        center.dy + math.sin(angle) * animatedDistance + 80,
      );

      // Enhanced perk styling
      final perkPainter = TextPainter(
        text: TextSpan(
          text: unlockedPerks[i],
          style: TextStyle(
            fontSize: (18 * perkProgress).toDouble(),
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: ringColor.withOpacity(0.8),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      perkPainter.layout();

      // Add background for perks
      final perkBg = Paint()
        ..color = ringColor.withOpacity(0.2 * perkProgress)
        ..style = PaintingStyle.fill;

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          perkOffset.dx - perkPainter.width / 2 - 8,
          perkOffset.dy - perkPainter.height / 2 - 4,
          perkPainter.width + 16,
          perkPainter.height + 8,
        ),
        const Radius.circular(12),
      );

      canvas.drawRRect(bgRect, perkBg);

      perkPainter.paint(
        canvas,
        Offset(
          perkOffset.dx - perkPainter.width / 2,
          perkOffset.dy - perkPainter.height / 2,
        ),
      );
    }
  }

  void _drawEnhancedScatteredSegments(Canvas canvas, Size size, Offset center) {
    // Draw enhanced scattered segments with variable sizes and colors
    final baseColors = [
      ringColor.withOpacity(0.8),
      ringColor.withOpacity(0.6),
      ringColor.withOpacity(0.4),
    ];

    for (int i = 0; i < 40; i++) {
      final angle = (i * 2 * math.pi / 40) + (expansionProgress * math.pi / 4);
      final baseDistance = 180 + (i * 8);
      final distance = baseDistance * expansionProgress;

      final segmentCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      // Variable dot sizes based on position
      final baseDotSize = 4.0 + ((i % 5) * 2.0); // 4-12 range
      final pulseFactor =
          1.0 + (math.sin((expansionProgress * 10) + (i * 0.5)) * 0.4);
      final dotSize = baseDotSize * pulseFactor * expansionProgress;

      // Color variation
      final colorIndex = i % baseColors.length;
      final dotColor = baseColors[colorIndex];

      // Enhanced visual effect with multiple layers
      final glowPaint = Paint()
        ..color = dotColor.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotSize);

      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(segmentCenter, dotSize * 1.8, glowPaint);
      canvas.drawCircle(segmentCenter, dotSize, dotPaint);
    }
  }

  void _drawReformingRing(Canvas canvas, Offset center, double radius) {
    // Draw the ring reforming for the new level with enhanced XP bar styling
    final reformedProgress = reformProgress;

    // Draw the reformed ring with enhanced XP bar styling
    _drawXPStyleRing(canvas, center, radius, reformedProgress, reformProgress);

    // Add reformation particle effects
    if (reformProgress > 0.1) {
      for (int i = 0; i < 20; i++) {
        final angle = (i * 2 * math.pi / 20);
        final particleProgress = math.max(0, (reformProgress - 0.1) * 1.11);

        // Particles moving inward to form the ring
        final startDistance = 300;
        final endDistance = radius;
        final currentDistance =
            startDistance - ((startDistance - endDistance) * particleProgress);

        final particleCenter = Offset(
          center.dx + math.cos(angle) * currentDistance,
          center.dy + math.sin(angle) * currentDistance,
        );

        final particleSize = 3.0 * (1.0 - particleProgress);
        final particleOpacity = 0.8 * (1.0 - particleProgress);

        final particlePaint = Paint()
          ..color = ringColor.withOpacity(particleOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(particleCenter, particleSize, particlePaint);
      }
    }

    // Add enhanced glow effect to the reformed ring
    if (reformProgress > 0.8) {
      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.4)
        ..strokeWidth = 20
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final reformAngle = 2 * math.pi * reformProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        reformAngle,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingCelebrationPainter oldDelegate) {
    // Repaint when any animation value changes
    return oldDelegate.unravelProgress != unravelProgress ||
        oldDelegate.expansionProgress != expansionProgress ||
        oldDelegate.reformProgress != reformProgress ||
        oldDelegate.currentPhase != currentPhase;
  }
}

/// Tracks which phase of the animation we're currently in
enum AnimationPhase {
  initial,
  unraveling,
  expanding,
  reforming,
}
