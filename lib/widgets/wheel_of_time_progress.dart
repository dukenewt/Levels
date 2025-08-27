import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../models/user_rank.dart';
import '../models/user.dart' as app;
import '../services/smooth_xp_animation_service.dart';
import '../providers/settings_provider.dart';
import '../core/theme/app_design_tokens.dart';
import '../screens/stats_screen.dart';

class WheelOfTimeProgress extends StatefulWidget {
  const WheelOfTimeProgress({Key? key}) : super(key: key);

  @override
  State<WheelOfTimeProgress> createState() => _WheelOfTimeProgressState();
}

class _WheelOfTimeProgressState extends State<WheelOfTimeProgress>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _xpRingController;
  late AnimationController _rankRingController;
  late AnimationController _taskRingController;

  // Smooth XP animation controller
  late AnimationController _xpProgressController;
  late AnimationController _celebrationController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _xpRingAnimation;
  late Animation<double> _rankRingAnimation;
  late Animation<double> _taskRingAnimation;

  // Smooth XP progress animation
  late Animation<double> _xpProgressAnimation;

  // Celebration animations for task completion
  late Animation<double> _celebrationScaleAnimation;
  late Animation<double> _celebrationGlowAnimation;

  // Track previous XP values for smooth animation
  double _previousXPProgress = 0.0;
  double _currentDisplayedXPProgress = 0.0;
  int _previousXP = 0;
  int _previousNextLevelXP = 1;
  bool _isInitialized = false;

  bool _reducedMotion = false;

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
        }
      }
    });

    // Accessibility: read reduced-motion preference
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      _reducedMotion = settings.reducedMotion;
    } catch (_) {
      _reducedMotion = false;
    }

    // Slow rotation for the mystical effect (skip if reduced motion)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );
    if (!_reducedMotion) {
      _rotationController.safeRepeat();
    }

    // Gentle pulse animation
    _pulseController = AnimationController(
      duration: AppDesignTokens.slow,
      vsync: this,
    );
    if (!_reducedMotion) {
      _pulseController.safeRepeat(reverse: true);
    }

    // Ring animations for progress changes
    _xpRingController = AnimationController(
      duration: _reducedMotion
          ? AppDesignTokens.microFast
          : const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rankRingController = AnimationController(
      duration: _reducedMotion
          ? AppDesignTokens.microFast
          : const Duration(milliseconds: 1200),
      vsync: this,
    );

    _taskRingController = AnimationController(
      duration: _reducedMotion
          ? AppDesignTokens.microFast
          : const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Smooth XP progress animation controller
    _xpProgressController = AnimationController(
      duration: _reducedMotion
          ? AppDesignTokens.microFast
          : const Duration(milliseconds: 800),
      vsync: this,
    );

    // Celebration animation controller for task completions
    _celebrationController = AnimationController(
      duration: _reducedMotion
          ? AppDesignTokens.microFast
          : const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _xpRingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _xpRingController,
      curve: Curves.easeOutCubic,
    ));

    _rankRingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rankRingController,
      curve: Curves.easeOutCubic,
    ));

    _taskRingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _taskRingController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize XP progress animation
    _xpProgressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _xpProgressController,
      curve: Curves.easeOutCubic, // Smooth easing for XP gains
    ));

    // Initialize celebration animations
    _celebrationScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _celebrationGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeOutCirc,
    ));

    // Start the ring animations with staggered delays (or snap complete if reduced motion)
    if (_reducedMotion) {
      _xpRingController.value = 1.0;
      _taskRingController.value = 1.0;
      _rankRingController.value = 1.0;
    } else {
      Future.delayed(AppDesignTokens.microMedium, () {
        if (mounted) _xpRingController.safeForward();
      });
      Future.delayed(
          AppDesignTokens.microSlow + const Duration(milliseconds: 300), () {
        if (mounted) _taskRingController.safeForward();
      });
      Future.delayed(AppDesignTokens.slow, () {
        if (mounted) _rankRingController.safeForward();
      });
    }

    // Mark as initialized
    _isInitialized = true;
  }

  void _animateXPProgress(double newProgress,
      {bool triggerCelebration = false}) {
    if (!mounted || !_isInitialized) return;

    // Update the tween to animate from current displayed progress to new progress
    _xpProgressAnimation = Tween<double>(
      begin: _currentDisplayedXPProgress,
      end: newProgress,
    ).animate(CurvedAnimation(
      parent: _xpProgressController,
      curve: Curves.easeOutCubic,
    ));

    // Reset and start the animation
    _xpProgressController.safeReset();
    _xpProgressController.safeForward()?.then((_) {
      if (mounted) {
        _currentDisplayedXPProgress = newProgress;
      }
    });

    // Trigger celebration animation for XP gains
    if (!_reducedMotion &&
        triggerCelebration &&
        newProgress > _currentDisplayedXPProgress) {
      _celebrationController.safeReset();
      _celebrationController.safeForward()?.then((_) {
        if (mounted) {
          // Pulse briefly to show completion satisfaction
          _pulseController.safeReset();
          _pulseController.safeForward()?.then((_) {
            if (mounted) {
              _pulseController.safeReverse();
            }
          });
        }
      });
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
    _rotationController.dispose();
    _pulseController.dispose();
    _xpRingController.dispose();
    _rankRingController.dispose();
    _taskRingController.dispose();
    _xpProgressController.dispose();
    _celebrationController.dispose();
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
              '🎯 XP changed: ${_previousXP} -> ${user.currentXp}, animating from $_currentDisplayedXPProgress to $currentXPProgress');
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

                // The main wheel
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _rotationController,
                    _pulseController,
                    _xpRingController,
                    _rankRingController,
                    _taskRingController,
                    _xpProgressController,
                    _celebrationController, // Add celebration animation
                  ]),
                  builder: (context, child) {
                    // Use the animated XP progress value - with safety check
                    final displayedXPProgress =
                        _xpProgressController.isAnimating
                            ? _xpProgressAnimation.value
                            : currentXPProgress;

                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value *
                            0.1, // Very slow rotation
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: WheelOfTimeRingsPainter(
                              xpProgress:
                                  displayedXPProgress * _xpRingAnimation.value,
                              rankProgress:
                                  rankProgress * _rankRingAnimation.value,
                              tasksProgress:
                                  tasksProgress * _taskRingAnimation.value,
                              xpColor: theme.colorScheme.primary,
                              rankColor: currentRank.color,
                              tasksColor: theme.colorScheme.secondary,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              pulseValue: _pulseAnimation.value,
                              // Add visual feedback for XP animation
                              isXPAnimating: _xpProgressController.isAnimating,
                            ),
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
        // XP Progress - now with smooth animation feedback
        AnimatedBuilder(
          animation: _xpProgressController,
          builder: (context, child) {
            return _buildLegendItem(
              context,
              color: theme.colorScheme.primary,
              label: 'XP Progress',
              current: user.currentXp,
              max: userProvider.nextLevelXp,
              isAnimating: _xpProgressController.isAnimating,
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
    const ringWidth = 12.0;
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

    // Central mystical symbol
    _drawCentralSymbol(
        canvas, center, innerRadius - ringWidth - gapBetweenRings);
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

    // Enhanced glow effect when animating
    final glowIntensity = isAnimating ? pulseValue * 0.8 : pulseValue * 0.4;
    final glowPaint = Paint()
      ..color = color.withOpacity(glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + (isAnimating ? 8 : 4)
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isAnimating ? 6 : 3);

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

  void _drawCentralSymbol(Canvas canvas, Offset center, double maxRadius) {
    final symbolPaint = Paint()
      ..color = xpColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw interconnected circles representing the Wheel of Time
    for (int i = 0; i < 3; i++) {
      final angle = i * 2 * math.pi / 3;
      final symbolCenter = Offset(
        center.dx + math.cos(angle) * maxRadius * 0.3,
        center.dy + math.sin(angle) * maxRadius * 0.3,
      );
      canvas.drawCircle(symbolCenter, maxRadius * 0.2, symbolPaint);
    }

    // Central binding circle
    canvas.drawCircle(center, maxRadius * 0.15, symbolPaint);
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
