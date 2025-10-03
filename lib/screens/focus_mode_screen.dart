import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pomodoro_timer_service.dart';
import '../services/break_suggestion_service.dart';
import '../services/task_prioritization_service.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/pomodoro_timer_widget.dart';
import '../core/theme/app_design_tokens.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({Key? key}) : super(key: key);

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  PrioritizationStrategy _selectedStrategy = PrioritizationStrategy.easyFirst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final hasLevel10 = userProvider.user?.talentChoices.values.any(
          (id) => id.startsWith('locked_in_10'),
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showFocusModeInfo(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pomodoro Timer (Level 5 feature)
            const PomodoroTimerWidget(),

            if (hasLevel10) ...[
              const SizedBox(height: AppDesignTokens.space5),
              _buildBreakSuggestionCard(theme),
              const SizedBox(height: AppDesignTokens.space5),
              _buildTaskPrioritizationCard(theme),
            ],

            const SizedBox(height: AppDesignTokens.space5),
            _buildFocusTips(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakSuggestionCard(ThemeData theme) {
    return Consumer<BreakSuggestionService>(
      builder: (context, breakService, child) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDesignTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: AppDesignTokens.space2),
                    Text(
                      'Break Suggestions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.space4),

                // Work tracking status
                if (breakService.isTracking) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDesignTokens.space3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusMd),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Working for:',
                              style: theme.textTheme.bodyLarge,
                            ),
                            Text(
                              breakService.currentWorkDurationFormatted,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (breakService.shouldSuggestBreak) ...[
                          const SizedBox(height: AppDesignTokens.space3),
                          Container(
                            padding:
                                const EdgeInsets.all(AppDesignTokens.space3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusSm),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    color: Colors.orange),
                                const SizedBox(width: AppDesignTokens.space2),
                                Expanded(
                                  child: Text(
                                    'Time for a break! ${breakService.suggestedBreakType.displayName}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          breakService.takeBreak(null);
                          _showBreakDialog(
                              context, breakService.suggestedBreakType);
                        },
                        icon: const Icon(Icons.free_breakfast),
                        label: const Text('Take Break'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: breakService.stopTracking,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Tracking'),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: breakService.startTracking,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Work Session'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignTokens.space5,
                          vertical: AppDesignTokens.space3,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppDesignTokens.space3),
                Divider(color: theme.dividerColor),
                const SizedBox(height: AppDesignTokens.space2),

                // Session stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(
                      context,
                      'Sessions Today',
                      '${breakService.consecutiveWorkSessions}',
                      Icons.work_history,
                    ),
                    if (breakService.lastBreakTime != null)
                      _buildStat(
                        context,
                        'Last Break',
                        breakService.getTimeSinceLastBreak() ?? '--',
                        Icons.schedule,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskPrioritizationCard(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final incompleteTasks =
            taskProvider.tasks.where((t) => !t.isCompleted).toList();
        final prioritizedTasks = TaskPrioritizationService.prioritizeTasks(
          incompleteTasks,
          _selectedStrategy,
        );
        final goalSuggestion =
            TaskPrioritizationService.getCompletionGoalSuggestion(
                incompleteTasks);
        final urgentTasks =
            TaskPrioritizationService.getUrgentTasks(incompleteTasks);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDesignTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: AppDesignTokens.space2),
                    Text(
                      'Smart Prioritization',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.space4),

                // Goal suggestion
                Container(
                  padding: const EdgeInsets.all(AppDesignTokens.space3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusMd),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppDesignTokens.space2),
                      Expanded(
                        child: Text(
                          goalSuggestion,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDesignTokens.space4),

                // Strategy selector
                DropdownButtonFormField<PrioritizationStrategy>(
                  value: _selectedStrategy,
                  decoration: InputDecoration(
                    labelText: 'Prioritization Strategy',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusMd),
                    ),
                    prefixIcon: const Icon(Icons.sort),
                  ),
                  items: PrioritizationStrategy.values.map((strategy) {
                    return DropdownMenuItem(
                      value: strategy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strategy.displayName,
                            style: theme.textTheme.bodyLarge,
                          ),
                          Text(
                            strategy.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStrategy = value);
                    }
                  },
                ),

                const SizedBox(height: AppDesignTokens.space4),

                // Urgent tasks highlight
                if (urgentTasks.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDesignTokens.space3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusMd),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.red),
                            const SizedBox(width: AppDesignTokens.space2),
                            Text(
                              '${urgentTasks.length} Urgent ${urgentTasks.length == 1 ? 'Task' : 'Tasks'}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDesignTokens.space2),
                        ...urgentTasks.take(3).map((task) {
                          final urgencyLevel =
                              TaskPrioritizationService.getUrgencyLevel(task);
                          final difficultyColor =
                              TaskPrioritizationService.getDifficultyColor(
                            task.difficulty,
                            theme.colorScheme,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppDesignTokens.space1),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: difficultyColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: AppDesignTokens.space2),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  urgencyLevel == 3 ? 'OVERDUE' : 'DUE SOON',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.space3),
                ],

                // Quick stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      context,
                      'Total Tasks',
                      '${incompleteTasks.length}',
                      Icons.task_alt,
                    ),
                    _buildStat(
                      context,
                      'Urgent',
                      '${urgentTasks.length}',
                      Icons.priority_high,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: AppDesignTokens.space1),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFocusTips(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: theme.colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: AppDesignTokens.space2),
                Text(
                  'Focus Tips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.space3),
            _buildTip(
                'Use Quiet Mode during work sessions to block all notifications'),
            _buildTip('Take breaks regularly to maintain productivity'),
            _buildTip('Prioritize tasks based on your energy levels'),
            _buildTip('Complete easy tasks first to build momentum'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: AppDesignTokens.space2),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showFocusModeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer, color: Colors.orange),
            SizedBox(width: AppDesignTokens.space2),
            Text('Focus Mode'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Focus Mode helps you stay productive with:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppDesignTokens.space3),
              Text('🍅 Pomodoro Timer - 25 min work, 5 min breaks'),
              SizedBox(height: AppDesignTokens.space2),
              Text('🔕 Quiet Mode - Block notifications during focus'),
              SizedBox(height: AppDesignTokens.space2),
              Text('☕ Break Suggestions - Smart break reminders'),
              SizedBox(height: AppDesignTokens.space2),
              Text('📋 Task Prioritization - Complete what matters'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showBreakDialog(BuildContext context, BreakType breakType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.self_improvement, color: Colors.green),
            const SizedBox(width: AppDesignTokens.space2),
            Text(breakType.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(breakType.description),
            const SizedBox(height: AppDesignTokens.space3),
            Text(
              'Suggested duration: ${breakType.suggestedDuration.inMinutes} minutes',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
