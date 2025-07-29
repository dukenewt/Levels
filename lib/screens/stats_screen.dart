import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

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
        title: Text('Your Stats', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            
            // Weekly completion chart
            Text(
              'Weekly Progress',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            _WeeklyTaskTrendsChart(),
            
            const SizedBox(height: AppDesignTokens.space6),
            
            // Task Difficulty Analysis
            Text(
              'Task Difficulty Analysis',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space2),
            Text(
              'Easy: 0-25 XP   Medium: 25-50 XP   Hard: 50-100 XP   Epic: 100-250 XP',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            _TaskDifficultyAnalysis(),
            
            const SizedBox(height: AppDesignTokens.space6),
            
            // Category breakdown
            Text(
              'Tasks by Category',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            _buildCategoryChart(context),
            
            // Category legend
            const SizedBox(height: AppDesignTokens.space4),
            _buildCategoryLegend(context),
            const SizedBox(height: AppDesignTokens.space6),
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

  Widget _buildCategoryChart(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final categoryData = _calculateCategoryData(tasks);
    
    if (categoryData.isEmpty) {
      return EnhancedCard(
        shadowLevel: CardShadowLevel.medium,
        margin: EdgeInsets.zero,
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Text(
            'No tasks to display',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return EnhancedCard(
      shadowLevel: CardShadowLevel.medium,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: categoryData.entries.map((entry) {
              final percentage = (entry.value['percentage'] as double) * 100;
              return PieChartSectionData(
                value: entry.value['percentage'] as double,
                title: '${percentage.round()}%',
                color: entry.value['color'] as Color,
                radius: 70,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateCategoryData(List<Task> tasks) {
    if (tasks.isEmpty) return {};
    
    // Count tasks by category and track completion
    final categoryCount = <String, int>{};
    final categoryCompleted = <String, int>{};
    
    for (final task in tasks) {
      final category = task.category.isNotEmpty ? task.category : 'Other';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      
      if (task.isCompleted) {
        categoryCompleted[category] = (categoryCompleted[category] ?? 0) + 1;
      }
    }
    
    final totalTasks = tasks.length;
    final categoryData = <String, Map<String, dynamic>>{};
    
    // Generate colors for categories
    final categoryColors = _generateCategoryColors(categoryCount.keys.toList());
    
    // Calculate percentages, completion rates, and assign colors
    for (final entry in categoryCount.entries) {
      final category = entry.key;
      final count = entry.value;
      final completed = categoryCompleted[category] ?? 0;
      final percentage = count / totalTasks;
      final completionRate = count > 0 ? completed / count : 0.0;
      
      categoryData[category] = {
        'count': count,
        'completed': completed,
        'percentage': percentage,
        'completionRate': completionRate,
        'color': categoryColors[category]!,
      };
    }
    
    return categoryData;
  }

  Map<String, Color> _generateCategoryColors(List<String> categories) {
    const predefinedColors = [
      Colors.blue,
      Colors.green, 
      Colors.purple,
      Colors.red,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
    
    final categoryColors = <String, Color>{};
    
    for (int i = 0; i < categories.length; i++) {
      categoryColors[categories[i]] = predefinedColors[i % predefinedColors.length];
    }
    
    return categoryColors;
  }

  Widget _buildCategoryLegend(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final categoryData = _calculateCategoryData(tasks);
    
    if (categoryData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDesignTokens.space4),
        child: Text(
          'No categories to display',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }
    
    // Sort categories by count (descending) for better visual organization
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend chips
        Wrap(
          spacing: AppDesignTokens.space4,
          runSpacing: AppDesignTokens.space2,
          children: sortedCategories.map((entry) {
            final category = entry.key;
            final data = entry.value;
            final color = data['color'] as Color;
            final count = data['count'] as int;
            final completed = data['completed'] as int;
            
            return _buildCategoryLegendItem(
              '$category ($completed/$count)', 
              color,
            );
          }).toList(),
        ),
        
        // Additional category stats
        const SizedBox(height: AppDesignTokens.space3),
        Text(
          'Category Completion Rates:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppDesignTokens.space2),
                                   for (final entry in sortedCategories) 
           Padding(
             padding: const EdgeInsets.only(bottom: AppDesignTokens.space1),
             child: () {
               final category = entry.key;
               final data = entry.value;
               final color = data['color'] as Color;
               final completionRate = data['completionRate'] as double;
               
               return Row(
                 children: [
                   Container(
                     width: 8,
                     height: 8,
                     decoration: BoxDecoration(
                       color: color,
                       shape: BoxShape.circle,
                     ),
                   ),
                   const SizedBox(width: AppDesignTokens.space2),
                   Expanded(
                     flex: 2,
                     child: Text(
                       category,
                       style: Theme.of(context).textTheme.bodySmall,
                     ),
                   ),
                   Expanded(
                     flex: 3,
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                       child: LinearProgressIndicator(
                         value: completionRate,
                         backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                         valueColor: AlwaysStoppedAnimation<Color>(color),
                         minHeight: 4,
                       ),
                     ),
                   ),
                   const SizedBox(width: AppDesignTokens.space2),
                   SizedBox(
                     width: 40,
                     child: Text(
                       '${(completionRate * 100).round()}%',
                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
                         fontWeight: FontWeight.w500,
                         color: color,
                       ),
                       textAlign: TextAlign.end,
                     ),
                   ),
                 ],
               );
             }(),
           ),
      ],
    );
  }

  // Helper to calculate current streak from completed tasks
  int _calculateCurrentStreak(List<Task> completedTasks) {
    if (completedTasks.isEmpty) return 0;
    final dates = completedTasks
        .map((t) => DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
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

class _WeeklyTaskTrendsChart extends StatelessWidget {
  List<int> _getCompletedTasksPerDay(List<Task> tasks) {
    final now = DateTime.now();
    List<int> counts = List.filled(7, 0);
    for (var task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final daysAgo = now.difference(DateTime(task.completedAt!.year, task.completedAt!.month, task.completedAt!.day)).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          counts[6 - daysAgo] += 1;
        }
      }
    }
    return counts;
  }

  double _calculateInterval(int maxCount) {
    if (maxCount <= 6) return 1;
    return (maxCount / 6).ceilToDouble();
  }

  double _calculateMaxY(int maxCount) {
    if (maxCount <= 6) return 6;
    // Round up to the next multiple of interval
    final interval = _calculateInterval(maxCount);
    return ((maxCount / interval).ceil() * interval).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final counts = _getCompletedTasksPerDay(tasks);
    final maxCount = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 1;
    final minCount = counts.isNotEmpty ? counts.reduce((a, b) => a < b ? a : b) : 0;
    final bestDay = counts.indexOf(maxCount);
    final worstDay = counts.indexOf(minCount);
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final interval = _calculateInterval(maxCount);
    final maxY = _calculateMaxY(maxCount);
    return EnhancedCard(
      shadowLevel: CardShadowLevel.medium,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey,
              tooltipBorderRadius: BorderRadius.circular(8),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(weekdays[value.toInt()]);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text('${value.toInt()}');
                },
                interval: interval,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final isBest = i == bestDay && maxCount > 0;
            final isWorst = i == worstDay && minCount > 0 && maxCount != minCount;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: isBest
                      ? Colors.green
                      : isWorst
                          ? Colors.red
                          : Colors.indigo,
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
        ),
      ),
    );
  }
}

class _TaskDifficultyAnalysis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    
    // Calculate difficulty distribution
    final difficultyCounts = {
      'easy': 0,
      'medium': 0,
      'hard': 0,
      'epic': 0,
    };
    
    final completedByDifficulty = {
      'easy': 0,
      'medium': 0,
      'hard': 0,
      'epic': 0,
    };
    
    for (var task in tasks) {
      difficultyCounts[task.difficulty] = (difficultyCounts[task.difficulty] ?? 0) + 1;
      if (task.isCompleted) {
        completedByDifficulty[task.difficulty] = (completedByDifficulty[task.difficulty] ?? 0) + 1;
      }
    }
    
    // Calculate completion rates
    final completionRates = {
      'easy': difficultyCounts['easy']! > 0 ? completedByDifficulty['easy']! / difficultyCounts['easy']! : 0.0,
      'medium': difficultyCounts['medium']! > 0 ? completedByDifficulty['medium']! / difficultyCounts['medium']! : 0.0,
      'hard': difficultyCounts['hard']! > 0 ? completedByDifficulty['hard']! / difficultyCounts['hard']! : 0.0,
      'epic': difficultyCounts['epic']! > 0 ? completedByDifficulty['epic']! / difficultyCounts['epic']! : 0.0,
    };
    
    // Calculate average XP earned per difficulty
    final xpByDifficulty = {
      'easy': 0,
      'medium': 0,
      'hard': 0,
      'epic': 0,
    };
    
    for (var task in completedTasks) {
      xpByDifficulty[task.difficulty] = (xpByDifficulty[task.difficulty] ?? 0) + task.xpReward;
    }
    
    return EnhancedCard(
      shadowLevel: CardShadowLevel.medium,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty Distribution
          Text(
            'Task Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space3),
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxBarHeight = constraints.maxHeight - 32; // leave space for text
                final maxCount = [
                  difficultyCounts['easy']!,
                  difficultyCounts['medium']!,
                  difficultyCounts['hard']!,
                  difficultyCounts['epic']!,
                ].reduce((a, b) => a > b ? a : b);
                double getBarHeight(int count) {
                  if (maxCount == 0) return 0;
                  return (count / maxCount) * maxBarHeight;
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildDifficultyBar('Easy', difficultyCounts['easy']!, Colors.green, getBarHeight(difficultyCounts['easy']!), context),
                    _buildDifficultyBar('Medium', difficultyCounts['medium']!, Colors.orange, getBarHeight(difficultyCounts['medium']!), context),
                    _buildDifficultyBar('Hard', difficultyCounts['hard']!, Colors.red, getBarHeight(difficultyCounts['hard']!), context),
                    _buildDifficultyBar('Epic', difficultyCounts['epic']!, Colors.purple, getBarHeight(difficultyCounts['epic']!), context),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppDesignTokens.space4),
          
          // Completion Rates
          Text(
            'Completion Rates',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space3),
          Column(
            children: [
              _buildCompletionRateRow('Easy', completionRates['easy']!, Colors.green, context),
              _buildCompletionRateRow('Medium', completionRates['medium']!, Colors.orange, context),
              _buildCompletionRateRow('Hard', completionRates['hard']!, Colors.red, context),
              _buildCompletionRateRow('Epic', completionRates['epic']!, Colors.purple, context),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space4),
          
          // XP Earned
          Text(
            'XP Earned by Difficulty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space3),
          Column(
            children: [
              _buildXPRow('Easy', xpByDifficulty['easy']!, Colors.green, context),
              _buildXPRow('Medium', xpByDifficulty['medium']!, Colors.orange, context),
              _buildXPRow('Hard', xpByDifficulty['hard']!, Colors.red, context),
              _buildXPRow('Epic', xpByDifficulty['epic']!, Colors.purple, context),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDifficultyBar(String label, int count, Color color, double barHeight, BuildContext context) {
    return SizedBox(
      width: 36,
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 24,
                height: barHeight, // This will be scaled by parent
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionRateRow(String difficulty, double rate, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              difficulty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: AppDesignTokens.space2),
          Text(
            '${(rate * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildXPRow(String difficulty, int xp, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              difficulty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$xp XP',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreaksAndConsistencySection extends StatelessWidget {
  const _StreaksAndConsistencySection();

  Map<DateTime, int> _getCompletionMap(List<Task> tasks) {
    final map = <DateTime, int>{};
    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final date = DateTime(task.completedAt!.year, task.completedAt!.month, task.completedAt!.day);
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
    for (DateTime d = firstDate; !d.isAfter(lastDate); d = d.add(const Duration(days: 1))) {
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
              _buildStreakStat('Current Streak', currentStreak, Icons.local_fire_department_rounded, Colors.orange, context),
              _buildStreakStat('Longest Streak', longestStreak, Icons.emoji_events_rounded, Colors.amber, context),
              _buildStreakStat('Days Missed', daysMissed, Icons.cancel_rounded, Colors.red, context),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space4),
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
            ),
            child: Text(
              'Calendar heatmap coming soon!', 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, int value, IconData icon, Color color, BuildContext context) {
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

Widget _buildCategoryLegendItem(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppDesignTokens.space3,
      vertical: AppDesignTokens.space1,
    ),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDesignTokens.space2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
} 