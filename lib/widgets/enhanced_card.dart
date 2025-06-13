import 'package:flutter/material.dart';
import '../core/theme/app_design_tokens.dart';

enum CardShadowLevel { low, medium, high, xHigh }

class EnhancedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? accentColor;
  final CardShadowLevel shadowLevel;
  final bool isInteractive;
  final bool isHighPriority;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EnhancedCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDesignTokens.space4),
    this.margin = const EdgeInsets.all(AppDesignTokens.space2),
    this.borderRadius,
    this.backgroundColor,
    this.accentColor,
    this.shadowLevel = CardShadowLevel.medium,
    this.isInteractive = false,
    this.isHighPriority = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _pressAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: AppDesignTokens.fast,
      vsync: this,
    );
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _pressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  List<BoxShadow> _getShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.isInteractive) {
      return AppDesignTokens.interactiveShadow(
        hoverFactor: _hoverAnimation.value,
        accentColor: widget.accentColor ?? 
                    (widget.isHighPriority ? Theme.of(context).colorScheme.primary : null),
        isPressed: _isPressed,
      );
    }

    // For high priority tasks with colored accents
    if (widget.isHighPriority && widget.accentColor != null) {
      return AppDesignTokens.coloredShadow(
        widget.accentColor!,
        intensity: 0.15 + (_hoverAnimation.value * 0.05),
      );
    }

    // Standard layered shadows based on level
    switch (widget.shadowLevel) {
      case CardShadowLevel.low:
        return isDark ? AppDesignTokens.shadowLowDark : AppDesignTokens.shadowLow;
      case CardShadowLevel.medium:
        return isDark ? AppDesignTokens.shadowMediumDark : AppDesignTokens.shadowMedium;
      case CardShadowLevel.high:
        return isDark ? AppDesignTokens.shadowHighDark : AppDesignTokens.shadowHigh;
      case CardShadowLevel.xHigh:
        return isDark ? AppDesignTokens.shadowHighDark : AppDesignTokens.shadowXHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = widget.backgroundColor ?? theme.cardColor;
    final effectiveBorderRadius = widget.borderRadius ?? AppDesignTokens.radiusLg;

    return AnimatedBuilder(
      animation: Listenable.merge([_hoverAnimation, _pressAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_pressAnimation.value * 0.02),
          child: Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              boxShadow: _getShadows(context),
              border: widget.isHighPriority && widget.accentColor != null
                  ? Border.all(
                      color: widget.accentColor!.withOpacity(0.2),
                      width: 1.0,
                    )
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(effectiveBorderRadius),
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onTapDown: widget.isInteractive ? (_) {
                  setState(() => _isPressed = true);
                  _pressController.forward();
                } : null,
                onTapUp: widget.isInteractive ? (_) {
                  setState(() => _isPressed = false);
                  _pressController.reverse();
                } : null,
                onTapCancel: widget.isInteractive ? () {
                  setState(() => _isPressed = false);
                  _pressController.reverse();
                } : null,
                onHover: widget.isInteractive ? (hovering) {
                  setState(() => _isHovered = hovering);
                  if (hovering) {
                    _hoverController.forward();
                  } else {
                    _hoverController.reverse();
                  }
                } : null,
                child: Padding(
                  padding: widget.padding!,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Button with layered shadows
class EnhancedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool isPrimary;

  const EnhancedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.isPrimary = true,
  }) : super(key: key);

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = widget.backgroundColor ?? 
        (widget.isPrimary ? theme.colorScheme.primary : theme.colorScheme.surface);
    final effectiveForegroundColor = widget.foregroundColor ?? 
        (widget.isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface);
    final effectiveBorderRadius = widget.borderRadius ?? AppDesignTokens.radiusMd;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              boxShadow: _isPressed 
                  ? AppDesignTokens.buttonShadowPressed(color: effectiveBackgroundColor)
                  : AppDesignTokens.buttonShadow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(effectiveBorderRadius),
                onTap: widget.onPressed,
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                  _controller.forward();
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                  _controller.reverse();
                },
                child: Padding(
                  padding: widget.padding ?? 
                      const EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 12
                      ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: effectiveForegroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 