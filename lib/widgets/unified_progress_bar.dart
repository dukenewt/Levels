import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../core/theme/app_design_tokens.dart';

/// A unified progress bar that feels alive and responsive
/// This replaces AnimatedXPBar, GamingXPBar, and other implementations
class UnifiedProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color primaryColor;
  final Color? secondaryColor;
  final double height;
  final String? label;
  final int? currentValue;
  final int? maxValue;
  final bool isLevelUp; // Triggers special animations
  final VoidCallback? onAnimationComplete;

  const UnifiedProgressBar({
    Key? key,
    required this.progress,
    required this.primaryColor,
    this.secondaryColor,
    this.height = 12.0,
    this.label,
    this.currentValue,
    this.maxValue,
    this.isLevelUp = false,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<UnifiedProgressBar> createState() => _UnifiedProgressBarState();
}

class _UnifiedProgressBarState extends State<UnifiedProgressBar>
    with TickerProviderStateMixin {
  // Core animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  
  // Animations
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;
  
  // Particle system for level up
  final List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    // Progress fill animation - smooth and satisfying
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Subtle pulse for the fill - makes it feel alive
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Wave effect that travels through the bar
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Glow effect for emphasis
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Set up the animations with curves
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic, // Satisfying ease-out
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimations() {
    // Start the progress animation
    _progressController.forward();
    
    // Continuous subtle pulse
    _pulseController.repeat(reverse: true);
    
    // Continuous wave effect
    _waveController.repeat();
    
    // Glow on progress changes
    if (widget.progress > 0) {
      _glowController.forward();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _glowController.safeReverse();
        }
      });
    }
    
    // Special effects for level up
    if (widget.isLevelUp) {
      _triggerLevelUpEffects();
    }
  }
  
  void _triggerLevelUpEffects() {
    // Generate celebration particles
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle.random(
        color: widget.primaryColor,
        startY: 0.5,
      ));
    }
    
    // Trigger completion callback after animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      }
    });
  }
  
  @override
  void didUpdateWidget(UnifiedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      // Animate to new progress
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      
      _progressController.forward(from: 0.0);
      
      // Trigger glow on change
      _glowController.forward();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _glowController.safeReverse();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label and value display
        if (widget.label != null || widget.currentValue != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                if (widget.currentValue != null && widget.maxValue != null)
                  TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: 0,
                      end: widget.currentValue!,
                    ),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, value, child) {
                      return Text(
                        '$value / ${widget.maxValue}',
                        style: TextStyle(
                          color: widget.primaryColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
        
        // The main progress bar
        AnimatedBuilder(
          animation: Listenable.merge([
            _progressController,
            _pulseController,
            _waveController,
            _glowController,
          ]),
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  // Glow effect
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(
                      0.3 * _glowAnimation.value,
                    ),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(
                size: Size(double.infinity, widget.height),
                painter: UnifiedProgressPainter(
                  progress: _progressAnimation.value,
                  primaryColor: widget.primaryColor,
                  secondaryColor: widget.secondaryColor ?? widget.primaryColor.withOpacity(0.3),
                  pulseValue: _pulseAnimation.value,
                  waveValue: _waveAnimation.value,
                  particles: widget.isLevelUp ? _particles : [],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Custom painter for the unified progress bar
class UnifiedProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double pulseValue;
  final double waveValue;
  final List<Particle> particles;
  
  UnifiedProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulseValue,
    required this.waveValue,
    required this.particles,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    
    // Draw background track
    _drawBackgroundTrack(canvas, size, radius);
    
    // Draw progress fill with effects
    _drawProgressFill(canvas, size, radius);
    
    // Draw particles for level up
    _drawParticles(canvas, size);
  }
  
  void _drawBackgroundTrack(Canvas canvas, Size size, double radius) {
    final trackPaint = Paint()
      ..color = secondaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final trackPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));
    
    canvas.drawPath(trackPath, trackPaint);
    
    // Inner shadow for depth
    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 2);
    
    canvas.drawPath(trackPath, innerShadowPaint);
  }
  
  void _drawProgressFill(Canvas canvas, Size size, double radius) {
    if (progress <= 0) return;
    
    final fillWidth = size.width * progress;
    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    
    // Create gradient with pulse effect
    final gradientColors = [
      primaryColor.withOpacity(0.9 + (pulseValue * 0.1)),
      primaryColor,
      primaryColor.withOpacity(0.9 + (pulseValue * 0.1)),
    ];
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        stops: const [0.0, 0.5, 1.0],
      ).createShader(fillRect)
      ..style = PaintingStyle.fill;
    
    // Main fill with rounded corners
    final fillPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        fillRect,
        Radius.circular(radius),
      ));
    
    canvas.drawPath(fillPath, fillPaint);
    
    // Wave overlay for movement
    _drawWaveOverlay(canvas, fillRect, radius);
    
    // Highlight on top edge
    _drawHighlight(canvas, fillRect, radius);
  }
  
  void _drawWaveOverlay(Canvas canvas, Rect fillRect, double radius) {
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final waveOffset = waveValue * fillRect.width;
    
    // Create a subtle wave pattern
    final wavePath = Path();
    for (double x = -50; x < fillRect.width + 50; x += 50) {
      final waveX = x + waveOffset;
      final waveY = fillRect.height / 2 + math.sin((waveX / 50) * math.pi) * 2;
      
      if (x == -50) {
        wavePath.moveTo(waveX, waveY);
      } else {
        wavePath.quadraticBezierTo(
          waveX - 25,
          waveY,
          waveX,
          waveY,
        );
      }
    }
    
    // Complete the wave shape
    wavePath.lineTo(fillRect.width + waveOffset, fillRect.height);
    wavePath.lineTo(-50 + waveOffset, fillRect.height);
    wavePath.close();
    
    // Clip to fill area
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      fillRect,
      Radius.circular(radius),
    ));
    canvas.drawPath(wavePath, wavePaint);
    canvas.restore();
  }
  
  void _drawHighlight(Canvas canvas, Rect fillRect, double radius) {
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final highlightRect = Rect.fromLTWH(
      fillRect.left,
      fillRect.top,
      fillRect.width,
      fillRect.height * 0.4,
    );
    
    final highlightPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        highlightRect,
        Radius.circular(radius),
      ));
    
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  void _drawParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.update();
      
      if (particle.life > 0) {
        final paint = Paint()
          ..color = particle.color.withOpacity(particle.life)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(
            particle.x * size.width,
            particle.y * size.height,
          ),
          particle.size,
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant UnifiedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.waveValue != waveValue ||
           particles.isNotEmpty;
  }
}

/// Simple particle class for celebrations
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double size;
  Color color;
  
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.life = 1.0,
    this.size = 3.0,
  });
  
  factory Particle.random({
    required Color color,
    double startY = 0.5,
  }) {
    final random = math.Random();
    return Particle(
      x: random.nextDouble(),
      y: startY,
      vx: (random.nextDouble() - 0.5) * 0.02,
      vy: -random.nextDouble() * 0.02 - 0.01,
      color: color,
      size: random.nextDouble() * 3 + 2,
    );
  }
  
  void update() {
    x += vx;
    y += vy;
    vy += 0.0005; // Gravity
    life -= 0.02;
  }
} 