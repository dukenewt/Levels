import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_design_tokens.dart';

/// Interactive scale animation widget for tactile feedback
class InteractiveScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final Curve curve;
  final bool enableHaptic;
  final bool enabled;

  const InteractiveScale({
    Key? key,
    required this.child,
    this.onTap,
    this.scaleDown = AppDesignTokens.scaleDown,
    this.duration = AppDesignTokens.microMedium,
    this.curve = AppDesignTokens.dampedCurve,
    this.enableHaptic = true,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends State<InteractiveScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scale = Tween<double>(
      begin: AppDesignTokens.scaleNormal,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (!widget.enabled) return;

    _controller.forward();
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp() {
    if (!widget.enabled) return;

    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _handleTapDown() : null,
      onTapUp: widget.enabled ? (_) => _handleTapUp() : null,
      onTapCancel: widget.enabled ? () => _handleTapCancel() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: AnimatedOpacity(
            opacity: widget.enabled
                ? 1.0
                : AppDesignTokens.interactionOpacityDisabled,
            duration: AppDesignTokens.microFast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Interactive button with micro animations and multiple states
class InteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? pressedColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool enabled;
  final bool isLoading;
  final List<BoxShadow>? shadows;

  const InteractiveButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.pressedColor,
    this.borderRadius,
    this.padding,
    this.enabled = true,
    this.isLoading = false,
    this.shadows,
  }) : super(key: key);

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scale;
  late Animation<Color?> _colorAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: AppDesignTokens.microMedium,
      vsync: this,
    );

    _colorController = AnimationController(
      duration: AppDesignTokens.microFast,
      vsync: this,
    );

    _scale = Tween<double>(
      begin: AppDesignTokens.scaleNormal,
      end: AppDesignTokens.scaleDown,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppDesignTokens.dampedCurve,
    ));

    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final pressedColor =
        widget.pressedColor ?? backgroundColor.withOpacity(0.8);

    _colorAnimation = ColorTween(
      begin: backgroundColor,
      end: pressedColor,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateColorAnimation();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (!_canInteract) return;

    setState(() => _isPressed = true);
    _scaleController.forward();
    _colorController.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp() {
    if (!_canInteract) return;

    setState(() => _isPressed = false);
    _scaleController.reverse();
    _colorController.reverse();

    Future.delayed(AppDesignTokens.hapticDelay, () {
      widget.onPressed?.call();
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    _colorController.reverse();
  }

  bool get _canInteract =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: _canInteract ? (_) => _handleTapDown() : null,
      onTapUp: _canInteract ? (_) => _handleTapUp() : null,
      onTapCancel: _canInteract ? () => _handleTapCancel() : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _colorAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: AnimatedContainer(
              duration: AppDesignTokens.microFast,
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: widget.borderRadius ??
                    BorderRadius.circular(AppDesignTokens.radiusMd),
                boxShadow: _isPressed
                    ? AppDesignTokens.buttonShadowPressed()
                    : (widget.shadows ?? AppDesignTokens.buttonShadow),
              ),
              child: AnimatedOpacity(
                opacity: widget.isLoading
                    ? AppDesignTokens.interactionOpacityLoading
                    : (_canInteract
                        ? 1.0
                        : AppDesignTokens.interactionOpacityDisabled),
                duration: AppDesignTokens.microFast,
                child: Padding(
                  padding: widget.padding ??
                      const EdgeInsets.symmetric(
                        horizontal: AppDesignTokens.space4,
                        vertical: AppDesignTokens.space3,
                      ),
                  child: widget.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Interactive card with hover and press effects
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final List<BoxShadow>? shadows;
  final bool enabled;
  final bool enableHoverEffect;

  const InteractiveCard({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
    this.padding,
    this.shadows,
    this.enabled = true,
    this.enableHoverEffect = true,
  }) : super(key: key);

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _elevationController;
  late Animation<double> _scale;
  late Animation<double> _elevation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: AppDesignTokens.microMedium,
      vsync: this,
    );

    _elevationController = AnimationController(
      duration: AppDesignTokens.microSlow,
      vsync: this,
    );

    _scale = Tween<double>(
      begin: AppDesignTokens.scaleNormal,
      end: AppDesignTokens.scaleDown,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AppDesignTokens.springCurve,
    ));

    _elevation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _elevationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _elevationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (!widget.enabled) return;

    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp() {
    if (!widget.enabled) return;

    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleHoverEnter() {
    if (!widget.enabled || !widget.enableHoverEffect) return;

    setState(() => _isHovered = true);
    _elevationController.forward();
  }

  void _handleHoverExit() {
    setState(() => _isHovered = false);
    _elevationController.reverse();
  }

  List<BoxShadow> _getShadows() {
    if (widget.shadows != null) return widget.shadows!;

    if (_isPressed) {
      return AppDesignTokens.buttonShadowPressed();
    } else if (_isHovered) {
      return AppDesignTokens.shadowMedium;
    } else {
      return AppDesignTokens.shadowLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHoverEnter(),
      onExit: (_) => _handleHoverExit(),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => _handleTapDown() : null,
        onTapUp: widget.enabled ? (_) => _handleTapUp() : null,
        onTapCancel: widget.enabled ? () => _handleTapCancel() : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scale, _elevation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: AnimatedContainer(
                duration: AppDesignTokens.microSlow,
                decoration: BoxDecoration(
                  color: widget.color ?? Theme.of(context).cardColor,
                  borderRadius: widget.borderRadius ??
                      BorderRadius.circular(AppDesignTokens.radiusLg),
                  boxShadow: _getShadows(),
                ),
                child: AnimatedOpacity(
                  opacity: widget.enabled
                      ? 1.0
                      : AppDesignTokens.interactionOpacityDisabled,
                  duration: AppDesignTokens.microFast,
                  child: Padding(
                    padding: widget.padding ??
                        const EdgeInsets.all(AppDesignTokens.space4),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animated ripple effect for buttons and interactive areas
class AnimatedRipple extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? rippleColor;
  final Duration duration;

  const AnimatedRipple({
    Key? key,
    required this.child,
    this.onTap,
    this.rippleColor,
    this.duration = AppDesignTokens.medium,
  }) : super(key: key);

  @override
  State<AnimatedRipple> createState() => _AnimatedRippleState();
}

class _AnimatedRippleState extends State<AnimatedRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reset();
      widget.onTap?.call();
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: RipplePainter(
                    animation: _animation,
                    color: widget.rippleColor ??
                        Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  RipplePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value == 0.0) return;

    final paint = Paint()
      ..color = color.withOpacity(1.0 - animation.value)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * animation.value;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}
