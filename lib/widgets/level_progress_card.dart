import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'animated_xp_bar.dart';
import '../screens/level_up_branch_screen.dart';

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

class _LevelProgressCardState extends State<LevelProgressCard> with TickerProviderStateMixin {
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
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _progressAnimation = Tween<double>(
      begin: _displayedXp / widget.nextLevelXp,
      end: _displayedXp / widget.nextLevelXp,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _tileScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tileScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _tileScaleController, curve: Curves.easeOutBack),
    );
  }
  
  @override
  void didUpdateWidget(LevelProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.currentXp != oldWidget.currentXp || widget.level != oldWidget.level) {
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
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showShimmer = false;
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _tileScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentRank = userProvider.currentRank;
    final xpBarColor = theme.colorScheme.primary;
    
    return ScaleTransition(
      scale: _tileScaleAnimation,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const LevelUpBranchScreen(),
            ),
          );
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
                
                // Animated Progress Bar
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return AnimatedXPBar(
                      progress: _progressAnimation.value,
                      color: xpBarColor,
                      height: 8,
                      shimmer: _showShimmer,
                      duration: const Duration(milliseconds: 1000),
                      shimmerDuration: const Duration(seconds: 4),
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