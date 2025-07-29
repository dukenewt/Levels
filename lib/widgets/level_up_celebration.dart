import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_rank.dart';
import '../models/celebration_data.dart';
import '../core/theme/app_design_tokens.dart';

/// Enhanced level up celebration widget with beautiful animations and confetti
/// This widget is purely presentational - it only handles the visual appearance
/// The logic for when and how to show celebrations is handled by EnhancedCelebrationController
class LevelUpCelebration extends StatefulWidget {
  final CelebrationData celebrationData;
  final VoidCallback onDismiss;

  const LevelUpCelebration({
    Key? key,
    required this.celebrationData,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _backgroundAnimation;
  
  final List<_ConfettiParticle> _confetti = [];
  final int _confettiCount = 50;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateConfetti();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Main celebration animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    // Pulse animation for the level text
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Set up animations
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.black.withOpacity(0.8),
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));
  }

  void _generateConfetti() {
    final random = math.Random();
    for (int i = 0; i < _confettiCount; i++) {
      _confetti.add(_ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3 - 0.1, // Start above screen
        vx: (random.nextDouble() - 0.5) * 0.02,
        vy: random.nextDouble() * 0.01 + 0.005,
        color: _getRandomConfettiColor(),
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  Color _getRandomConfettiColor() {
    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  void _startAnimations() {
    _mainController.forward();
    _confettiController.forward();
    _slideController.forward();
    
    // Start pulse animation after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.safeRepeat(reverse: true);
      }
    });

    // Auto dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _pulseController.safeStop();
    _mainController.safeReverse()?.then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _confettiController,
          _pulseController,
          _slideController,
        ]),
        builder: (context, child) {
          return Container(
            width: screenSize.width,
            height: screenSize.height,
            color: _backgroundAnimation.value,
            child: Stack(
              children: [
                // Confetti layer
                if (_confettiController.isAnimating)
                  CustomPaint(
                    size: screenSize,
                    painter: _ConfettiPainter(
                      confetti: _confetti,
                      animationValue: _confettiController.value,
                    ),
                  ),
                
                // Main celebration content
                Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Trophy icon with glow effect
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.amber.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 80,
                                  color: Colors.amber,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Level Up text with pulse animation
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Text(
                                  'LEVEL UP!',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Level progression
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLevelBadge(widget.celebrationData.oldLevel, false),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildLevelBadge(widget.celebrationData.newLevel, true),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Rank information (if available)
                              if (widget.celebrationData.newRank != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.celebrationData.rankColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: widget.celebrationData.rankColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: widget.celebrationData.rankColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.celebrationData.rankName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: widget.celebrationData.rankColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              
                              // Show unlocked perks if any
                              if (widget.celebrationData.hasUnlockedPerks) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'New Perks Unlocked!',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...widget.celebrationData.unlockedPerks.map(
                                        (perk) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.fiber_new,
                                                size: 16,
                                                color: theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                perk,
                                                style: theme.textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              
                              // Continue button
                              ElevatedButton(
                                onPressed: _dismiss,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Continue',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelBadge(int level, bool isNew) {
    final theme = Theme.of(context);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNew ? theme.colorScheme.primary : Colors.grey,
        boxShadow: isNew ? [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          level.toString(),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Confetti particle class for celebration effects
class _ConfettiParticle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.0008; // Gravity
    rotation += rotationSpeed;
    
    // Wind effect
    vx += (math.Random().nextDouble() - 0.5) * 0.0001;
  }
}

/// Custom painter for confetti animation
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> confetti;
  final double animationValue;

  _ConfettiPainter({
    required this.confetti,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in confetti) {
      particle.update();
      
      if (particle.y < 1.2) { // Only draw if still on screen
        final paint = Paint()..color = particle.color;
        
        canvas.save();
        canvas.translate(
          particle.x * size.width,
          particle.y * size.height,
        );
        canvas.rotate(particle.rotation);
        
        // Draw confetti as small rectangles
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 