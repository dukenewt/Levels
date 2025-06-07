import 'package:flutter/material.dart';
import 'dart:math' as math;

// XP Bar that looks like energy meters from RPG games
class GamingXPBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color primaryColor;
  final Color secondaryColor;
  final String label;
  final int currentValue;
  final int maxValue;
  final bool showPulse;

  const GamingXPBar({
    Key? key,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.label,
    required this.currentValue,
    required this.maxValue,
    this.showPulse = false,
  }) : super(key: key);

  @override
  State<GamingXPBar> createState() => _GamingXPBarState();
}

class _GamingXPBarState extends State<GamingXPBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fillController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for when XP is being gained
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Fill animation for smooth progress changes
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start the fill animation
    _fillController.forward();
    
    // Start pulse if needed
    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GamingXPBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate to new progress value
    if (oldWidget.progress != widget.progress) {
      _fillAnimation = Tween<double>(
        begin: _fillAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ));
      
      _fillController.forward(from: 0.0);
    }
    
    // Handle pulse animation
    if (widget.showPulse && !oldWidget.showPulse) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showPulse && oldWidget.showPulse) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _fillController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label with current/max values
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${widget.currentValue} / ${widget.maxValue}',
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace', // Makes numbers feel more digital
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // The actual progress bar
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Background with subtle pattern
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade800,
                              Colors.grey.shade900,
                            ],
                          ),
                        ),
                        child: CustomPaint(
                          painter: CircuitPatternPainter(),
                        ),
                      ),
                      
                      // Progress fill with animated gradient
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _fillAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.secondaryColor,
                                widget.primaryColor,
                                widget.primaryColor.withBlue(
                                  math.min(255, widget.primaryColor.blue + 50),
                                ),
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                          ),
                          child: CustomPaint(
                            painter: EnergyFlowPainter(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      
                      // Shine effect overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Border overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.primaryColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Hexagonal skill progress indicator - common in RPGs
class HexagonalSkillMeter extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final String skillName;
  final int level;
  final IconData icon;

  const HexagonalSkillMeter({
    Key? key,
    required this.progress,
    required this.color,
    required this.skillName,
    required this.level,
    required this.icon,
  }) : super(key: key);

  @override
  State<HexagonalSkillMeter> createState() => _HexagonalSkillMeterState();
}

class _HexagonalSkillMeterState extends State<HexagonalSkillMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    // Continuous slow rotation for visual interest
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating background pattern
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: HexagonBackgroundPainter(
                    color: widget.color.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
          
          // Main hexagon with progress
          CustomPaint(
            size: const Size(100, 100),
            painter: HexagonProgressPainter(
              progress: widget.progress,
              color: widget.color,
              backgroundColor: Colors.grey.shade800,
            ),
          ),
          
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'LVL ${widget.level}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Skill name below
          Positioned(
            bottom: 0,
            child: Text(
              widget.skillName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painters for the visual effects

class CircuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Draw simple circuit-like lines
    for (int i = 0; i < size.width; i += 10) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnergyFlowPainter extends CustomPainter {
  final Color color;
  
  EnergyFlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw flowing energy lines
    final path = Path();
    for (double x = 0; x < size.width; x += 15) {
      path.moveTo(x, 0);
      path.quadraticBezierTo(x + 7, size.height / 2, x + 15, size.height);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HexagonProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  HexagonProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    
    // Draw background hexagon
    final backgroundPath = _createHexagonPath(center, radius);
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawPath(backgroundPath, backgroundPaint);
    
    // Draw progress hexagon
    final progressPath = _createHexagonPath(center, radius);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    // Calculate path metrics for progress
    final pathMetrics = progressPath.computeMetrics().first;
    final progressPath2 = pathMetrics.extractPath(
      0,
      pathMetrics.length * progress,
    );
    
    canvas.drawPath(progressPath2, progressPaint);
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(progressPath2, glowPaint);
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HexagonBackgroundPainter extends CustomPainter {
  final Color color;
  
  HexagonBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw multiple hexagon rings for depth
    for (double radius = 20; radius < size.width / 2; radius += 15) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60) * math.pi / 180;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 