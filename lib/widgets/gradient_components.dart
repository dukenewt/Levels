import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/theme_model.dart';
import '../core/theme/app_design_tokens.dart';

/// Enhanced gradient container that uses theme colors intelligently
class GradientContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool useFullGradient;
  final VoidCallback? onTap;

  const GradientContainer({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.borderRadius = 16,
    this.useFullGradient = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = AppTheme.getThemeByType(themeProvider.currentTheme);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: useFullGradient 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
                stops: theme.gradientColors.length == 3 
                    ? const [0.0, 0.5, 1.0]
                    : const [0.0, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.surfaceColor,
                  theme.surfaceColor.withOpacity(0.8),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Progress bar with gradient fill
class GradientProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final String? label;
  final int? currentValue;
  final int? maxValue;

  const GradientProgressBar({
    Key? key,
    required this.progress,
    this.height = 12.0,
    this.label,
    this.currentValue,
    this.maxValue,
  }) : super(key: key);

  @override
  State<GradientProgressBar> createState() => _GradientProgressBarState();
}

class _GradientProgressBarState extends State<GradientProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.safeForward(); // Using safe method
  }

  @override
  void didUpdateWidget(GradientProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.safeForward(from: 0.0); // Using safe method
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = AppTheme.getThemeByType(themeProvider.currentTheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null || widget.currentValue != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              if (widget.currentValue != null && widget.maxValue != null)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final animatedValue = (_animation.value * widget.currentValue!).round();
                    return Text(
                      '$animatedValue / ${widget.maxValue}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.textColor.withOpacity(0.8),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            color: theme.primaryColor.withOpacity(0.1),
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Background track
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      color: theme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                  // Progress fill with gradient
                  FractionallySizedBox(
                    widthFactor: _animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        gradient: LinearGradient(
                          colors: theme.gradientColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Enhanced task card with gradient accents
class GradientTaskCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isCompleted;
  final String difficulty;

  const GradientTaskCard({
    Key? key,
    required this.child,
    this.onTap,
    this.isCompleted = false,
    this.difficulty = 'medium',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = AppTheme.getThemeByType(themeProvider.currentTheme);

    // Get difficulty color from gradient
    Color getDifficultyColor() {
      switch (difficulty) {
        case 'easy':
          return theme.gradientColors.length > 2 
              ? theme.gradientColors[2] 
              : theme.gradientColors.last; // Usually the lighter color
        case 'medium':
          return theme.primaryColor;
        case 'hard':
          return theme.gradientColors.first;
        case 'epic':
          return theme.gradientColors.length > 2 
              ? theme.gradientColors[1] 
              : theme.primaryColor;
        default:
          return theme.primaryColor;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: isCompleted 
                ? Colors.green.withOpacity(0.1)
                : getDifficultyColor().withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withOpacity(0.3)
              : getDifficultyColor().withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Subtle gradient overlay for difficulty
          if (!isCompleted)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      getDifficultyColor(),
                      getDifficultyColor().withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Action Button with gradient
class GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const GradientFAB({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = AppTheme.getThemeByType(themeProvider.currentTheme);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradientColors.take(2).toList(),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: child,
      ),
    );
  }
}

/// App bar with subtle gradient background
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool useGradient;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.useGradient = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = AppTheme.getThemeByType(themeProvider.currentTheme);

    return Container(
      decoration: useGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.backgroundColor,
                  theme.backgroundColor.withOpacity(0.8),
                ],
              ),
            )
          : null,
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        backgroundColor: useGradient ? Colors.transparent : theme.backgroundColor,
        elevation: 0,
        actions: actions,
        iconTheme: IconThemeData(color: theme.textColor),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 