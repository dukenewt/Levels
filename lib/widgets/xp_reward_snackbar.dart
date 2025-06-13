import 'package:flutter/material.dart';
import '../services/intelligent_xp_engine.dart';
import '../core/theme/app_design_tokens.dart';

/// Enhanced snackbar that shows XP rewards with beautiful animations and breakdown
class XPRewardSnackbar extends StatefulWidget {
  final int xpGained;
  final int? streakBonus;

  const XPRewardSnackbar({
    Key? key,
    required this.xpGained,
    this.streakBonus,
  }) : super(key: key);

  @override
  State<XPRewardSnackbar> createState() => _XPRewardSnackbarState();

  /// Static method to show the XP reward snackbar
  static void show(BuildContext context, int xpGained, int? streakBonus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: XPRewardSnackbar(xpGained: xpGained, streakBonus: streakBonus),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _XPRewardSnackbarState extends State<XPRewardSnackbar>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _xpController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _xpCountAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _xpController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    ));

    _xpCountAnimation = Tween<double>(
      begin: 0.0,
      end: widget.xpGained.toDouble(),
    ).animate(CurvedAnimation(
      parent: _xpController,
      curve: Curves.easeOutQuart,
    ));

    // Start animations
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _xpController.safeForward();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _xpController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * _slideAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // XP Icon with pulse animation
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // XP breakdown
                        _buildXPBreakdown(theme),
                      ],
                    ),
                  ),
                  
                  // Animated XP counter
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${_xpCountAnimation.value.round()}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildXPBreakdown(ThemeData theme) {
    if (widget.streakBonus == null || widget.streakBonus == 0) {
      return Text(
        '+${widget.xpGained} XP',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.9),
        ),
      );
    }

    final baseXP = widget.xpGained - widget.streakBonus!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+$baseXP base XP',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 12,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                '+${widget.streakBonus} streak bonus',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 