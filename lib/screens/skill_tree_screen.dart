import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../providers/skill_provider.dart';
import '../widgets/skill_tree_view.dart';

class SkillTreeScreen extends StatefulWidget {
  final String skillId;

  const SkillTreeScreen({
    Key? key,
    required this.skillId,
  }) : super(key: key);

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SkillProvider>(
      builder: (context, skillProvider, child) {
        final skill = skillProvider.getSkill(widget.skillId);
        if (skill == null) {
          return const Scaffold(
            body: Center(
              child: Text('Skill not found'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(skill.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showSkillInfo(context, skill),
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SkillTreeView(skill: skill),
                  const SizedBox(height: 24),
                  _buildSkillStats(context, skill),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillStats(BuildContext context, Skill skill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            'Total XP',
            skill.totalXP.toString(),
            Icons.star,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'Current Level',
            skill.level.toString(),
            Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'Achievements',
            skill.achievements.length.toString(),
            Icons.emoji_events,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'Time Invested',
            _formatTimeInvested(skill.createdAt),
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatTimeInvested(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    }
  }

  void _showSkillInfo(BuildContext context, Skill skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(skill.description),
            const SizedBox(height: 16),
            Text(
              'Current Title',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(skill.title),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 