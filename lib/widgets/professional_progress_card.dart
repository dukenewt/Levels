import 'package:flutter/material.dart';
import '../core/theme/app_design_tokens.dart';
import 'dart:io' show Platform;

class ProfessionalProgressCard extends StatefulWidget {
  final String title;
  final int currentValue;
  final int maxValue;
  final Color color;
  final String subtitle;
  final VoidCallback? onTap;

  const ProfessionalProgressCard({
    Key? key,
    required this.title,
    required this.currentValue,
    required this.maxValue,
    required this.color,
    required this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfessionalProgressCard> createState() => _ProfessionalProgressCardState();
}

class _ProfessionalProgressCardState extends State<ProfessionalProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: AppDesignTokens.slow,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentValue / widget.maxValue,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    Future.delayed(AppDesignTokens.medium, () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    return Semantics(
      label: widget.title,
      value: '${widget.currentValue} of ${widget.maxValue}',
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppDesignTokens.space4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: widget.color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppDesignTokens.space1),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.space3,
                      vertical: AppDesignTokens.space2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                    ),
                    child: Text(
                      '${widget.currentValue}/${widget.maxValue}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesignTokens.space4),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color,
                                widget.color.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(0.3),
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
            ],
          ),
        ),
      ),
    );
  }
} 