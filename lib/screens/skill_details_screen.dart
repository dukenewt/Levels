import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';

class SkillDetailsScreen extends StatelessWidget {
  final Skill skill;

  const SkillDetailsScreen({
    Key? key,
    required this.skill,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    // Get tasks related to this skill
    final relatedTasks = taskProvider.tasks.where((task) => task.skillId == skill.id).toList();
    final activeTasks = relatedTasks.where((task) => !task.isCompleted).toList();
    final completedTasks = relatedTasks.where((task) => task.isCompleted).toList();
    final upcomingTasks = relatedTasks
        .where((task) => !task.isCompleted && task.dueDate != null && task.dueDate!.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: skill.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(skill.icon),
                color: skill.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(skill.name),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill Progress Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level ${skill.level}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                skill.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: skill.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${skill.currentXp}/${skill.xpToNextLevel} XP',
                            style: TextStyle(
                              color: skill.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: skill.progressPercentage / 100,
                        backgroundColor: skill.color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(skill.color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Active Tasks Section
            if (activeTasks.isNotEmpty) ...[
              Text(
                'Active Tasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...activeTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskTile(
                  task: task,
                  onComplete: () async {
                    await taskProvider.completeTask(context, task);
                  },
                ),
              )),
              const SizedBox(height: 24),
            ],
            // Upcoming Tasks Section
            if (upcomingTasks.isNotEmpty) ...[
              Text(
                'Upcoming Tasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...upcomingTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskTile(
                  task: task,
                  onComplete: () async {
                    await taskProvider.completeTask(context, task);
                  },
                ),
              )),
              const SizedBox(height: 24),
            ],
            // Completed Tasks Section
            if (completedTasks.isNotEmpty) ...[
              Text(
                'Completed Tasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...completedTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskTile(
                  task: task,
                  onComplete: () async {
                    await taskProvider.completeTask(context, task);
                  },
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'code':
        return Icons.code;
      case 'music_note':
        return Icons.music_note;
      case 'brush':
        return Icons.brush;
      default:
        return Icons.help_outline;
    }
  }
} 