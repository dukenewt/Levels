import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../models/user_rank.dart';
import '../models/user.dart' as app;
import '../services/smooth_xp_animation_service.dart';
import '../core/animation/animation_orchestrator.dart';
import '../screens/stats_screen.dart';
import 'ring_unraveling_celebration.dart';
import '../core/theme/app_design_tokens.dart';
import '../core/animation/ring_anchor.dart';

class WheelOfTimeProgress extends StatefulWidget {
  const WheelOfTimeProgress({Key? key}) : super(key: key);

  @override
  State<WheelOfTimeProgress> createState() => _WheelOfTimeProgressState();
}

class _WheelOfTimeProgressState extends State<WheelOfTimeProgress>
    with TickerProviderStateMixin, OrchestrationMixin {
  // Streamlined controllers using the new architecture
  late AnimationController _ambientController;
  late AnimationController _progressController;

  // Consolidated animations
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _xpProgressAnimation;

  // Track previous XP values for smooth animation
  double _previousXPProgress = 0.0;
  double _currentDisplayedXPProgress = 0.0;
  int _previousXP = 0;
  int _previousNextLevelXP = 1;
  bool _isInitialized = false;
  int? _previousLevel;
  bool _celebratingLevel = false;

  @override
  void initState() {
    super.initState();

    // Initialize XP tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user != null) {
          _previousXP = userProvider.user!.currentXp;
          _previousNextLevelXP = userProvider.nextLevelXp;
          _previousXPProgress = userProvider.nextLevelXp > 0
              ? userProvider.user!.currentXp / userProvider.nextLevelXp
              : 0.0;
          _currentDisplayedXPProgress = _previousXPProgress;
          _previousLevel = userProvider.user!.level;
        }
      }
    });

    // Initialize orchestrated animations - MUCH CLEANER!
    _setupAnimations();
    _startAmbientAnimations();

    // Mark as initialized
    _isInitialized = true;
  }

  void _setupAnimations() {
    // Get controllers from the orchestrator
    _ambientController = getAnimationController(
      'ambient',
      duration: const Duration(seconds: 60),
    );

    _progressController = getAnimationController(
      'progress',
      duration: const Duration(milliseconds: 800),
    );

    // Create animations using the orchestrator
    _rotationAnimation = createAnimation(
      _ambientController,
      Tween<double>(begin: 0, end: 2 * math.pi),
      curve: Curves.linear,
    );

    _pulseAnimation = createAnimation(
      _ambientController,
      Tween<double>(begin: 0.98, end: 1.02),
      curve: Curves.easeInOut,
    );

    _xpProgressAnimation = createAnimation(
      _progressController,
      Tween<double>(begin: 0.0, end: 0.0),
      curve: Curves.easeOutCubic,
    );
  }

  void _startAmbientAnimations() {
    // Start ambient animations unless reduced motion is enabled
    if (!AnimationOrchestrator.instance.reducedMotion) {
      _ambientController.repeat();
    }
  }

  void _animateXPProgress(double newProgress,
      {bool triggerCelebration = false}) {
    if (!mounted || !_isInitialized) return;

    // Use orchestrator to animate XP progress smoothly
    final progressTween = Tween<double>(
      begin: _currentDisplayedXPProgress,
      end: newProgress,
    );

    _xpProgressAnimation = createAnimation(
      _progressController,
      progressTween,
      curve: Curves.easeOutCubic,
    );

    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) {
        _currentDisplayedXPProgress = newProgress;
      }
    });

    // Trigger celebration using orchestrated sequence
    if (triggerCelebration && newProgress > _currentDisplayedXPProgress) {
      runAnimationSequence(
        'xpCelebration',
        [
          AnimationStep(
            type: AnimationStepType.delay,
            duration: Duration(milliseconds: 200),
          ),
          AnimationStep.custom(() async {
            // Brief pulse for satisfaction
            await _ambientController.forward();
            await _ambientController.reverse();
          }),
        ],
      );
    }
  }

  /// Navigate to the detailed stats screen
  void _navigateToStatsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StatsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    // OrchestrationMixin automatically handles disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);
    final user = userProvider.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    // Detect level up and show ring celebration
    if (_previousLevel != null &&
        user.level > _previousLevel! &&
        !_celebratingLevel) {
      _celebratingLevel = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          barrierColor: Colors.black54,
          pageBuilder: (ctx, a1, a2) {
            return RingUnravelingCelebration(
              initialProgress: 0.0,
              oldLevel: _previousLevel!,
              newLevel: user.level,
              ringColor: Theme.of(context).colorScheme.primary,
              unlockedPerks: const [],
              onComplete: () {
                Navigator.of(ctx).maybePop();
                _celebratingLevel = false;
              },
            );
          },
        );
      });
    }
    _previousLevel = user.level;

    // Calculate the current XP progress
    final currentXPProgress = userProvider.nextLevelXp > 0
        ? user.currentXp / userProvider.nextLevelXp
        : 0.0;

    // Check if XP has changed and animate if needed
    if (_isInitialized &&
        (user.currentXp != _previousXP ||
            userProvider.nextLevelXp != _previousNextLevelXP)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isInitialized) {
          final xpIncreased = user.currentXp > _previousXP;
          debugPrint(
              '🎯 XP changed: $_previousXP -> ${user.currentXp}, animating from $_currentDisplayedXPProgress to $currentXPProgress');
          _animateXPProgress(currentXPProgress,
              triggerCelebration: xpIncreased);
          _previousXP = user.currentXp;
          _previousNextLevelXP = userProvider.nextLevelXp;
          _previousXPProgress = currentXPProgress;
        }
      });
    }

    final currentRank = UserRank.ranks.firstWhere((r) => r.name == user.rank,
        orElse: () => UserRank.ranks.first);
    final nextRank = UserRank.getNextRank(user.level);
    final rankProgress = nextRank != null
        ? (user.level - currentRank.requiredLevel) /
            (nextRank.requiredLevel - currentRank.requiredLevel)
        : 1.0;

    final completedTasks =
        taskProvider.tasks.where((task) => task.isCompleted).length;
    final totalTasks = taskProvider.tasks.length;
    final tasksProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateToStatsScreen(context),
        child: Card(
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Test button for XP animation (debug mode only)
                if (kDebugMode)
                  ElevatedButton(
                    onPressed: () => _testXPAnimation(context),
                    child: Text('Test XP Animation (+25 XP)'),
                  ),

                // The main wheel - now with streamlined animations
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _ambientController,
                    _progressController,
                  ]),
                  builder: (context, child) {
                    // Use the animated XP progress value
                    final displayedXPProgress = _progressController.isAnimating
                        ? _xpProgressAnimation.value
                        : currentXPProgress;

                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Transform.rotate(
                        angle: _progressController.isAnimating
                            ? _rotationAnimation.value *
                                0.02 // Slow down but don't stop completely
                            : _rotationAnimation.value *
                                0.1, // Normal slow rotation
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              KeyedSubtree(
                                key: RingAnchor.instance.ringKey,
                                child: CustomPaint(
                                  size: const Size(
                                      200, 200), // Explicitly set size
                                  painter: WheelOfTimeRingsPainter(
                                    xpProgress: displayedXPProgress,
                                    rankProgress: rankProgress,
                                    tasksProgress: tasksProgress,
                                    xpColor: theme.colorScheme.primary,
                                    rankColor: currentRank.color,
                                    tasksColor: theme.colorScheme.secondary,
                                    backgroundColor:
                                        AppDesignTokens.neutralRingTrack,
                                    pulseValue: _pulseAnimation.value,
                                    // Add visual feedback for XP animation
                                    isXPAnimating:
                                        _progressController.isAnimating,
                                  ),
                                ),
                              ),
                              _LevelNumberBadge(level: user.level),
                              if (kDebugMode)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Legend
                _buildLegend(
                    context, user, userProvider, completedTasks, totalTasks),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Debug method to test XP animation
  void _testXPAnimation(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;
    SmoothXPAnimationService.instance.testXPAnimation(userProvider);
  }

  Widget _buildLegend(BuildContext context, app.User user,
      UserProvider userProvider, int completedTasks, int totalTasks) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // XP Progress - now with streamlined animation feedback
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return _buildLegendItem(
              context,
              color: theme.colorScheme.primary,
              label: 'XP Progress',
              current: user.currentXp,
              max: userProvider.nextLevelXp,
              isAnimating: _progressController.isAnimating,
            );
          },
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          context,
          color: UserRank.ranks
              .firstWhere((r) => r.name == user.rank,
                  orElse: () => UserRank.ranks.first)
              .color,
          label: 'Rank Progress',
          current: user.level,
          max: UserRank.getNextRank(user.level)?.requiredLevel ?? user.level,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          context,
          color: theme.colorScheme.secondary,
          label: 'Tasks Complete',
          current: completedTasks,
          max: totalTasks,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int current,
    required int max,
    bool isAnimating = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // Add subtle glow when animating
            boxShadow: isAnimating
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isAnimating ? FontWeight.w600 : FontWeight.normal,
              color: isAnimating ? color : null,
            ),
          ),
        ),
        // Animated text for XP values
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: isAnimating ? FontWeight.bold : FontWeight.normal,
            color: isAnimating ? color : theme.textTheme.bodyMedium!.color,
          ),
          child: Text('$current / $max'),
        ),
      ],
    );
  }
}

class WheelOfTimeRingsPainter extends CustomPainter {
  final double xpProgress;
  final double rankProgress;
  final double tasksProgress;
  final Color xpColor;
  final Color rankColor;
  final Color tasksColor;
  final Color backgroundColor;
  final double pulseValue;
  final bool isXPAnimating;

  WheelOfTimeRingsPainter({
    required this.xpProgress,
    required this.rankProgress,
    required this.tasksProgress,
    required this.xpColor,
    required this.rankColor,
    required this.tasksColor,
    required this.backgroundColor,
    required this.pulseValue,
    this.isXPAnimating = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Ring dimensions
    const ringWidth = 14.0;
    const gapBetweenRings = 8.0;

    final outerRadius = maxRadius - 10;
    final middleRadius = outerRadius - ringWidth - gapBetweenRings;
    final innerRadius = middleRadius - ringWidth - gapBetweenRings;

    // Background rings
    _drawBackgroundRing(canvas, center, outerRadius, ringWidth);
    _drawBackgroundRing(canvas, center, middleRadius, ringWidth);
    _drawBackgroundRing(canvas, center, innerRadius, ringWidth);

    // Progress rings with mystical effects
    _drawProgressRing(canvas, center, outerRadius, ringWidth, xpProgress,
        xpColor, 0, isXPAnimating);
    _drawProgressRing(canvas, center, middleRadius, ringWidth, rankProgress,
        rankColor, math.pi / 3, false);
    _drawProgressRing(canvas, center, innerRadius, ringWidth, tasksProgress,
        tasksColor, 2 * math.pi / 3, false);

    // Center content handled by overlay badge widget
  }

  void _drawBackgroundRing(
      Canvas canvas, Offset center, double radius, double strokeWidth) {
    final paint = Paint()
      ..color =
          backgroundColor.withOpacity(AppDesignTokens.neutralRingTrackOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawProgressRing(
      Canvas canvas,
      Offset center,
      double radius,
      double strokeWidth,
      double progress,
      Color color,
      double startAngleOffset,
      bool isAnimating) {
    if (progress <= 0) return;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    // Create gradient effect
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: startAngle + startAngleOffset,
      endAngle: startAngle + startAngleOffset + sweepAngle,
      colors: [
        color.withOpacity(0.6),
        color,
        color.withOpacity(0.9),
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Enhanced glow effect when animating
    final glowIntensity = isAnimating ? pulseValue * 0.6 : pulseValue * 0.3;
    final glowPaint = Paint()
      ..color = color.withOpacity(glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + (isAnimating ? 6 : 3)
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isAnimating ? 4 : 2);

    canvas.drawArc(
      rect,
      startAngle + startAngleOffset,
      sweepAngle,
      false,
      glowPaint,
    );

    canvas.drawArc(
      rect,
      startAngle + startAngleOffset,
      sweepAngle,
      false,
      paint,
    );

    // Add sparkle effect when XP is animating
    if (isAnimating && progress > 0.1) {
      _drawSparkleEffect(canvas, center, radius,
          startAngle + startAngleOffset + sweepAngle, color);
    }
  }

  void _drawSparkleEffect(
      Canvas canvas, Offset center, double radius, double angle, Color color) {
    final sparklePosition = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    final sparklePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // Draw a small sparkle at the end of the progress arc
    canvas.drawCircle(sparklePosition, 3, sparklePaint);

    // Add a subtle star effect
    final starPath = Path();
    const starSize = 8.0;
    for (int i = 0; i < 4; i++) {
      final starAngle = angle + (i * math.pi / 2);
      final starPoint = Offset(
        sparklePosition.dx + math.cos(starAngle) * starSize,
        sparklePosition.dy + math.sin(starAngle) * starSize,
      );
      if (i == 0) {
        starPath.moveTo(starPoint.dx, starPoint.dy);
      } else {
        starPath.lineTo(starPoint.dx, starPoint.dy);
      }
    }
    starPath.close();

    final starPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant WheelOfTimeRingsPainter oldDelegate) {
    return oldDelegate.xpProgress != xpProgress ||
        oldDelegate.rankProgress != rankProgress ||
        oldDelegate.tasksProgress != tasksProgress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isXPAnimating != isXPAnimating;
  }
}

class _LevelNumberBadge extends StatelessWidget {
  final int level;
  const _LevelNumberBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.28),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: primary.withOpacity(0.25), width: 1),
      ),
      child: Text(
        level.toString(),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
