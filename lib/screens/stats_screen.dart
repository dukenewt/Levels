import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../screens/task_dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/user_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final tasksCompleted = completedTasks.length;
    final currentStreak = _calculateCurrentStreak(completedTasks);
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.onPrimary,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProvider.user?.displayName ?? 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    userProvider.user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Tasks'),
              onTap: () async {
                debugPrint('Drawer: Tasks tapped');
                Navigator.pop(context);
                await Future.microtask(() {
                  if (!context.mounted) return;
                  if (ModalRoute.of(context)?.settings.name != 'TaskDashboardScreen') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TaskDashboardScreen(),
                        settings: const RouteSettings(name: 'TaskDashboardScreen'),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () async {
                debugPrint('Drawer: Calendar tapped');
                Navigator.pop(context);
                await Future.microtask(() {
                  if (!context.mounted) return;
                  if (ModalRoute.of(context)?.settings.name != 'CalendarScreen') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalendarScreen(),
                        settings: const RouteSettings(name: 'CalendarScreen'),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Stats'),
              selected: true,
              onTap: () async {
                debugPrint('Drawer: Stats tapped');
                Navigator.pop(context);
                await Future.microtask(() {
                  if (!context.mounted) return;
                  if (ModalRoute.of(context)?.settings.name != 'StatsScreen') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatsScreen(),
                        settings: const RouteSettings(name: 'StatsScreen'),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Achievements'),
              onTap: () async {
                debugPrint('Drawer: Achievements tapped');
                Navigator.pop(context);
                await Future.microtask(() {
                  if (!context.mounted) return;
                  if (ModalRoute.of(context)?.settings.name != 'AchievementsScreen') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AchievementsScreen(),
                        settings: const RouteSettings(name: 'AchievementsScreen'),
                      ),
                    );
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () async {
                debugPrint('Drawer: Profile tapped');
                Navigator.pop(context);
                await Future.microtask(() {
                  if (!context.mounted) return;
                  if (ModalRoute.of(context)?.settings.name != 'ProfileScreen') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                        settings: const RouteSettings(name: 'ProfileScreen'),
                      ),
                    );
                  }
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                debugPrint('Drawer: Sign Out tapped');
                Navigator.pop(context);
                userProvider.signOut();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Your Stats'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Tasks Completed',
                    tasksCompleted.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Current Streak',
                    currentStreak == 1 ? '1 day' : '$currentStreak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Streaks and Consistency Section
            const Text(
              'Streaks & Consistency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _StreaksAndConsistencySection(),
            const SizedBox(height: 24),
            
            // Skill Levels Section
            const Text(
              'Skill Levels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _SkillLevelsSection(),
            const SizedBox(height: 24),
            
            // Weekly completion chart
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _WeeklyTaskTrendsChart(),
            
            const SizedBox(height: 24),
            
            // Task Difficulty Analysis
            const Text(
              'Task Difficulty Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Easy: 0-25 XP   Medium: 25-50 XP   Hard: 50-100 XP   Epic: 100-250 XP',
              style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _TaskDifficultyAnalysis(),
            
            const SizedBox(height: 24),
            
            // Category breakdown
            const Text(
              'Tasks by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 35,
                      title: '35%',
                      color: Colors.blue,
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 25,
                      title: '25%',
                      color: Colors.green,
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: Colors.purple,
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: Colors.red,
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Category legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 16,
                children: [
                  _buildCategoryLegendItem('Work', Colors.blue),
                  _buildCategoryLegendItem('Home', Colors.green),
                  _buildCategoryLegendItem('Personal', Colors.purple),
                  _buildCategoryLegendItem('Health', Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.indigo,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
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

class _SkillLevelsSection extends StatelessWidget {
  Color _getContrastingTextColor(Color background) {
    // Simple luminance check for contrast
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final skills = Provider.of<SkillProvider>(context).skills;
    if (skills.isEmpty) {
      return const Text('No skills tracked yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: skills.map((skill) {
        final xpToNext = skill.xpForNextLevel - skill.currentXp;
        final progress = skill.xpForNextLevel == 0 ? 0.0 : skill.currentXp / skill.xpForNextLevel;
        final textColor = _getContrastingTextColor(skill.color);
        return Card(
          color: skill.color,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(skill.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    Text('Level ${skill.level}', style: TextStyle(fontSize: 14, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: textColor.withOpacity(0.2),
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text('XP: ${skill.currentXp} / ${skill.xpForNextLevel}  (+$xpToNext XP to next level)', style: TextStyle(fontSize: 12, color: textColor)),
              ],
            ),
          ),
        );
      }).toList(),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
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
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty Distribution
          const Text(
            'Task Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
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
                    _buildDifficultyBar('Easy', difficultyCounts['easy']!, Colors.green, getBarHeight(difficultyCounts['easy']!)),
                    _buildDifficultyBar('Medium', difficultyCounts['medium']!, Colors.orange, getBarHeight(difficultyCounts['medium']!)),
                    _buildDifficultyBar('Hard', difficultyCounts['hard']!, Colors.red, getBarHeight(difficultyCounts['hard']!)),
                    _buildDifficultyBar('Epic', difficultyCounts['epic']!, Colors.purple, getBarHeight(difficultyCounts['epic']!)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Completion Rates
          const Text(
            'Completion Rates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _buildCompletionRateRow('Easy', completionRates['easy']!, Colors.green),
              _buildCompletionRateRow('Medium', completionRates['medium']!, Colors.orange),
              _buildCompletionRateRow('Hard', completionRates['hard']!, Colors.red),
              _buildCompletionRateRow('Epic', completionRates['epic']!, Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          
          // XP Earned
          const Text(
            'XP Earned by Difficulty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _buildXPRow('Easy', xpByDifficulty['easy']!, Colors.green),
              _buildXPRow('Medium', xpByDifficulty['medium']!, Colors.orange),
              _buildXPRow('Hard', xpByDifficulty['hard']!, Colors.red),
              _buildXPRow('Epic', xpByDifficulty['epic']!, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDifficultyBar(String label, int count, Color color, double barHeight) {
    return SizedBox(
      width: 36,
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionRateRow(String difficulty, double rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              difficulty,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                backgroundColor: Colors.grey[700],
                color: color,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(rate * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
  
  Widget _buildXPRow(String difficulty, int xp, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              difficulty,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              '$xp XP',
              style: TextStyle(
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
      return const Text('No completions yet.');
    }
    final allDates = completionMap.keys.toList()..sort();
    final firstDate = allDates.first;
    final lastDate = DateTime.now();
    int currentStreak = 0;
    int longestStreak = 0;
    int daysMissed = 0;
    int streak = 0;
    DateTime? prev;
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStreakStat('Current Streak', currentStreak, Icons.local_fire_department, Colors.orange, context),
              _buildStreakStat('Longest Streak', longestStreak, Icons.emoji_events, Colors.amber, context),
              _buildStreakStat('Days Missed', daysMissed, Icons.cancel, Colors.red, context),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Calendar heatmap coming soon!', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, int value, IconData icon, Color color, BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
        ),
      ],
    );
  }
} 