import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_rank.dart';
import 'unified_progress_bar.dart';
import '../core/animation/animation_orchestrator.dart';

class LevelProgressCard extends StatefulWidget {
  final int level;
  final int currentXp;
  final int nextLevelXp;

  const LevelProgressCard({
    Key? key,
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
  }) : super(key: key);

  @override
  State<LevelProgressCard> createState() => _LevelProgressCardState();
}

class _LevelProgressCardState extends State<LevelProgressCard>
    with TickerProviderStateMixin, OrchestrationMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late int _displayedXp;
  late int _displayedLevel;
  bool _showShimmer = false;
  late AnimationController _tileScaleController;
  late Animation<double> _tileScaleAnimation;

  @override
  void initState() {
    super.initState();
    _displayedXp = widget.currentXp;
    _displayedLevel = widget.level;

    _animationController = getAnimationController(
      'levelProgress',
      duration: const Duration(milliseconds: 1000),
    );

    _progressAnimation = createAnimation(
      _animationController,
      Tween<double>(
        begin: _displayedXp / widget.nextLevelXp,
        end: _displayedXp / widget.nextLevelXp,
      ),
      curve: Curves.easeInOut,
    );

    _tileScaleController = getAnimationController(
      'levelScale',
      duration: const Duration(milliseconds: 400),
    );
    _tileScaleAnimation = createAnimation(
      _tileScaleController,
      Tween<double>(begin: 1.0, end: 1.05), // Reduced scale for subtlety
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(LevelProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentXp != oldWidget.currentXp ||
        widget.level != oldWidget.level) {
      _progressAnimation = Tween<double>(
        begin: _displayedXp / widget.nextLevelXp,
        end: widget.currentXp / widget.nextLevelXp,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0.0).then((_) {
        setState(() {
          _displayedXp = widget.currentXp;
          _displayedLevel = widget.level;
        });
      });
    }
    // Trigger shimmer and tile pop on level up
    if (widget.level > oldWidget.level) {
      setState(() {
        _showShimmer = true;
      });
      _tileScaleController.forward(from: 0.0).then((_) {
        _tileScaleController.reverse();
      });
      Future.delayed(
        AnimationOrchestrator.instance.reducedMotion
            ? const Duration(milliseconds: 1500) // Shorter for reduced motion
            : const Duration(seconds: 3), // Reduced from 4 seconds
        () {
          if (mounted) {
            setState(() {
              _showShimmer = false;
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    // OrchestrationMixin automatically handles controller disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final currentRank = UserRank.ranks.firstWhere((r) => r.name == user.rank,
        orElse: () => UserRank.ranks.first);
    final xpBarColor = theme.colorScheme.primary;

    return ScaleTransition(
      scale: _tileScaleAnimation,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => const LevelUpBranchScreen(),
          //   ),
          // );
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.secondary.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          color: theme.colorScheme.secondary,
          shadowColor: Colors.black.withOpacity(0.13),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar with level
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: currentRank.color,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: currentRank.color,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _displayedLevel.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Level and XP Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentRank.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: currentRank.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Level $_displayedLevel',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_displayedXp / ${widget.nextLevelXp} XP',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return UnifiedProgressBar(
                      progress: _progressAnimation.value,
                      primaryColor: xpBarColor,
                      label: "XP",
                      currentValue: _displayedXp,
                      maxValue: widget.nextLevelXp,
                      isLevelUp: _showShimmer,
                      height: 12,
                      onAnimationComplete: () {
                        setState(() {
                          _showShimmer = false;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
