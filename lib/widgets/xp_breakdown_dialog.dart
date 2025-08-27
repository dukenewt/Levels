import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/character_progression/application/intelligent_xp_engine.dart';
import '../models/task.dart';

class XpBreakdownDialog extends StatefulWidget {
  final XPCalculationBreakdown breakdown;
  final Task task;

  const XpBreakdownDialog({
    Key? key,
    required this.breakdown,
    required this.task,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required XPCalculationBreakdown breakdown,
    required Task task,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool shouldShowDialog =
        prefs.getBool('showXpBreakdownDialog') ?? true;

    if (shouldShowDialog && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => XpBreakdownDialog(
          breakdown: breakdown,
          task: task,
        ),
      );
    }
  }

  @override
  _XpBreakdownDialogState createState() => _XpBreakdownDialogState();
}

class _XpBreakdownDialogState extends State<XpBreakdownDialog>
    with TickerProviderStateMixin {
  bool _dontShowAgain = false;
  late AnimationController _animationController;
  late AnimationController _lootBoxController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _lootBoxScaleAnimation;
  late Animation<double> _lootBoxShimmerAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Loot box animations (only if loot box was triggered)
    if (widget.breakdown.lootBoxResult.wasTriggered) {
      _lootBoxController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      _lootBoxScaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _lootBoxController,
        curve: Curves.elasticOut,
      ));

      _lootBoxShimmerAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _lootBoxController,
        curve: Curves.easeInOut,
      ));

      // Start loot box animation after main animation
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _lootBoxController.forward();
        }
      });
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.breakdown.lootBoxResult.wasTriggered) {
      _lootBoxController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeCalculation(theme),
                      const SizedBox(height: 16),
                      _buildMultipliers(theme),
                      const SizedBox(height: 16),
                      _buildBonuses(theme),
                      const SizedBox(height: 20),
                      _buildTotalSection(theme),
                      const SizedBox(height: 20),
                      _buildDetailsToggle(theme),
                      if (_showDetails) ...[
                        const SizedBox(height: 16),
                        _buildDetailedExplanations(theme),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XP Calculation Breakdown',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Understanding your ${widget.breakdown.totalXP} XP reward',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCalculation(ThemeData theme) {
    return _buildCalculationCard(
      theme,
      title: 'Time Investment',
      icon: Icons.schedule,
      children: [
        _buildCalculationRow(
          '${widget.task.timeCostMinutes} minutes',
          '${widget.breakdown.baseTimeXP} XP',
          subtitle:
              'Base calculation: 10 × √${widget.task.timeCostMinutes} + 5',
        ),
      ],
    );
  }

  Widget _buildMultipliers(ThemeData theme) {
    return _buildCalculationCard(
      theme,
      title: 'Impact Multipliers',
      icon: Icons.trending_up,
      children: [
        if (widget.breakdown.categoryMultiplier != 1.0)
          _buildCalculationRow(
            '${widget.task.category} Category',
            'x${widget.breakdown.categoryMultiplier.toStringAsFixed(1)}',
            subtitle: widget.breakdown.categoryReason,
          ),
        _buildCalculationRow(
          '${widget.task.difficulty.name.toUpperCase()} Difficulty',
          'x${widget.breakdown.difficultyMultiplier.toStringAsFixed(1)}',
          subtitle: widget.breakdown.difficultyReason,
        ),
        const Divider(height: 16),
        _buildCalculationRow(
          'Final Base XP',
          '${widget.breakdown.finalBaseXP} XP',
          isResult: true,
          subtitle:
              '${widget.breakdown.baseTimeXP} × ${widget.breakdown.categoryMultiplier.toStringAsFixed(1)} × ${widget.breakdown.difficultyMultiplier.toStringAsFixed(1)}',
        ),
      ],
    );
  }

  Widget _buildBonuses(ThemeData theme) {
    final hasBonuses = widget.breakdown.totalBonusXP > 0;

    return Column(
      children: [
        _buildCalculationCard(
          theme,
          title: 'Consistency Bonuses',
          icon: Icons.local_fire_department,
          children: [
            if (widget.breakdown.streakBonus > 0)
              _buildCalculationRow(
                'Streak Bonus (${widget.breakdown.currentStreak} days)',
                '+${widget.breakdown.streakBonus} XP',
                subtitle: 'Consistency builds momentum!',
              ),
            if (widget.breakdown.morningBonus > 0)
              _buildCalculationRow(
                'Morning Achievement',
                '+${widget.breakdown.morningBonus} XP',
                subtitle: 'Early bird gets the XP!',
              ),
            if (widget.breakdown.perfectWeekBonus > 0)
              _buildCalculationRow(
                'Perfect Week Bonus',
                '+${widget.breakdown.perfectWeekBonus} XP',
                subtitle: 'Exceptional weekly consistency',
              ),
            if (!hasBonuses && !widget.breakdown.lootBoxResult.wasTriggered)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No bonuses this time - build streaks for extra rewards!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        if (widget.breakdown.lootBoxResult.wasTriggered) ...[
          const SizedBox(height: 12),
          _buildLootBoxCard(theme),
        ],
      ],
    );
  }

  Widget _buildTotalSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total XP Earned',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.breakdown.finalBaseXP} base + ${widget.breakdown.totalBonusXP} bonus',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${widget.breakdown.totalXP}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsToggle(ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _showDetails = !_showDetails),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _showDetails ? Icons.expand_less : Icons.expand_more,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _showDetails ? 'Hide Details' : 'Show Optimization Tips',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedExplanations(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTipCard(
          theme,
          'Maximize Your XP',
          Icons.lightbulb_outline,
          [
            'Build daily streaks for consistent bonus XP',
            'Complete morning habits early for 10% bonus',
            'Focus on Health and Learning tasks for higher multipliers',
            'Challenge yourself with harder difficulties',
            'Easy tasks have higher loot box chances (15%) for momentum building',
          ],
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          theme,
          'XP Calculation Formula',
          Icons.calculate,
          [
            'Base XP = 10 × √(minutes) + 5',
            'Category multiplier ranges from 0.9x to 1.5x',
            'Difficulty multiplier ranges from 0.8x to 2.0x',
            'Streak bonus grows with square root scaling',
            'Loot box chances: Easy 15%, Medium 10%, Hard 6%, Epic 3%',
            'Loot box multipliers: 1.5x (60%), 2x (25%), 2.5x (11%), 3x (4%)',
          ],
        ),
      ],
    );
  }

  Widget _buildTipCard(
      ThemeData theme, String title, IconData icon, List<String> tips) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(color: theme.colorScheme.primary)),
                    Expanded(
                      child: Text(
                        tip,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCalculationCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    String? subtitle,
    bool isResult = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isResult ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLootBoxCard(ThemeData theme) {
    final lootBox = widget.breakdown.lootBoxResult;

    return AnimatedBuilder(
      animation: _lootBoxController,
      builder: (context, child) {
        return Transform.scale(
          scale: _lootBoxScaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber
                      .withOpacity(0.2 + _lootBoxShimmerAnimation.value * 0.1),
                  Colors.orange
                      .withOpacity(0.3 + _lootBoxShimmerAnimation.value * 0.1),
                  Colors.deepOrange
                      .withOpacity(0.2 + _lootBoxShimmerAnimation.value * 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber
                    .withOpacity(0.5 + _lootBoxShimmerAnimation.value * 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber
                      .withOpacity(0.3 + _lootBoxShimmerAnimation.value * 0.2),
                  blurRadius: 12 + _lootBoxShimmerAnimation.value * 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOOT BOX BONUS!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                          Text(
                            lootBox.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.6),
                        ),
                      ),
                      child: Text(
                        '+${lootBox.bonusXP} XP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${lootBox.multiplier.toStringAsFixed(1)}x Multiplier Applied!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _dontShowAgain,
              onChanged: (value) {
                setState(() {
                  _dontShowAgain = value!;
                });
              },
            ),
            Expanded(
              child: Text(
                "Don't show breakdown for future completions",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (_dontShowAgain) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('showXpBreakdownDialog', false);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Awesome! Got it'),
          ),
        ),
      ],
    );
  }
}
