import 'package:dailyxp/widgets/skill_progress_wheel.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';

import '../widgets/enhanced_card.dart';
import '../core/theme/app_design_tokens.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final tasksCompleted = completedTasks.length;
    final currentStreak = _calculateCurrentStreak(completedTasks);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Stats',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards section
            Text(
              'Your Stats',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    'Tasks Completed',
                    tasksCompleted.toString(),
                    Icons.check_circle_rounded,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: AppDesignTokens.space4),
                Expanded(
                  child: _buildEnhancedStatCard(
                    context,
                    'Current Streak',
                    currentStreak == 1 ? '1 day' : '$currentStreak days',
                    Icons.local_fire_department_rounded,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.space6),

            // Streaks and Consistency Section
            Text(
              'Streaks & Consistency',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            _StreaksAndConsistencySection(),
            const SizedBox(height: AppDesignTokens.space6),

            // Skill Progression Section
            Text(
              'Skill Progression',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SkillProgressIndicator(
                  skillName: 'Strength',
                  progress: 0.7,
                  color: Colors.red,
                ),
                _SkillProgressIndicator(
                  skillName: 'Intellect',
                  progress: 0.4,
                  color: Colors.blue,
                ),
                _SkillProgressIndicator(
                  skillName: 'Agility',
                  progress: 0.9,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return EnhancedCard(
      shadowLevel: CardShadowLevel.medium,
      accentColor: color,
      isHighPriority: true,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignTokens.space3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space3),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space1),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _calculateCurrentStreak(List<Task> completedTasks) {
    if (completedTasks.isEmpty) return 0;
    final dates = completedTasks
        .map((t) => DateTime(
            t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
        .toSet()
        .toList()
      ..sort();
    int streak = 0;
    DateTime day = DateTime.now();
    while (dates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _SkillProgressIndicator extends StatelessWidget {
  final String skillName;
  final double progress;
  final Color color;

  const _SkillProgressIndicator({
    Key? key,
    required this.skillName,
    required this.progress,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: SkillProgressWheel(
            progress: progress,
            color: color,
          ),
        ),
        const SizedBox(height: AppDesignTokens.space2),
        Text(
          skillName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StreaksAndConsistencySection extends StatelessWidget {
  const _StreaksAndConsistencySection();

  Map<DateTime, int> _getCompletionMap(List<Task> tasks) {
    final map = <DateTime, int>{};
    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final date = DateTime(task.completedAt!.year, task.completedAt!.month,
            task.completedAt!.day);
        map[date] = (map[date] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final completionMap = _getCompletionMap(tasks);
    if (completionMap.isEmpty) {
      return EnhancedCard(
        shadowLevel: CardShadowLevel.low,
        margin: EdgeInsets.zero,
        child: Text(
          'No completions yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      );
    }
    final allDates = completionMap.keys.toList()..sort();
    final firstDate = allDates.first;
    final lastDate = DateTime.now();
    int currentStreak = 0;
    int longestStreak = 0;
    int daysMissed = 0;
    int streak = 0;
    for (DateTime d = firstDate;
        !d.isAfter(lastDate);
        d = d.add(const Duration(days: 1))) {
      if (completionMap.containsKey(d)) {
        streak++;
        if (d.isAtSameMomentAs(lastDate)) {
          currentStreak = streak;
        }
        if (streak > longestStreak) longestStreak = streak;
      } else {
        daysMissed++;
        streak = 0;
      }
    }
    return EnhancedCard(
      shadowLevel: CardShadowLevel.medium,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStreakStat('Current Streak', currentStreak,
                  Icons.local_fire_department_rounded, Colors.orange, context),
              _buildStreakStat('Longest Streak', longestStreak,
                  Icons.emoji_events_rounded, Colors.amber, context),
              _buildStreakStat('Days Missed', daysMissed, Icons.cancel_rounded,
                  Colors.red, context),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space4),
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            ),
            child: Text(
              'Calendar heatmap coming soon!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, int value, IconData icon, Color color,
      BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesignTokens.space2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: AppDesignTokens.space2),
        Text(
          value.toString(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppDesignTokens.space1),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
