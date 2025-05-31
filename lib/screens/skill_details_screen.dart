import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../widgets/skill_economy_tab.dart';

class SkillDetailsScreen extends StatefulWidget {
  final Skill skill;

  const SkillDetailsScreen({
    Key? key,
    required this.skill,
  }) : super(key: key);

  @override
  State<SkillDetailsScreen> createState() => _SkillDetailsScreenState();
}

class _SkillDetailsScreenState extends State<SkillDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    // Get tasks related to this skill
    final relatedTasks = taskProvider.tasks.where((task) => task.skillId == widget.skill.id).toList();
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
                color: widget.skill.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(widget.skill.icon),
                color: widget.skill.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.skill.name),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Tasks'),
            Tab(text: 'Economy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, theme),
          _buildTasksTab(context, theme, activeTasks, completedTasks, upcomingTasks),
          SkillEconomyTab(skillId: widget.skill.id),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
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
                              'Level ${widget.skill.level}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.skill.description,
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
                          color: widget.skill.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.skill.currentXp} / ${widget.skill.xpForNextLevel} XP',
                          style: TextStyle(
                            color: widget.skill.color,
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
                      value: widget.skill.progressPercentage / 100,
                      backgroundColor: widget.skill.color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.skill.color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksTab(
    BuildContext context,
    ThemeData theme,
    List<Task> activeTasks,
    List<Task> completedTasks,
    List<Task> upcomingTasks,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeTasks.isNotEmpty) ...[
            Text(
              'Active Tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...activeTasks.map((task) => TaskTile(task: task)),
            const SizedBox(height: 24),
          ],
          if (upcomingTasks.isNotEmpty) ...[
            Text(
              'Upcoming Tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...upcomingTasks.map((task) => TaskTile(task: task)),
            const SizedBox(height: 24),
          ],
          if (completedTasks.isNotEmpty) ...[
            Text(
              'Completed Tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...completedTasks.map((task) => TaskTile(task: task)),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map icon names to Material Icons
    final iconMap = {
      'work': Icons.work,
      'fitness': Icons.fitness_center,
      'book': Icons.book,
      'code': Icons.code,
      'music': Icons.music_note,
      'art': Icons.palette,
      'language': Icons.language,
      'cooking': Icons.restaurant,
      'default': Icons.star,
    };
    return iconMap[iconName] ?? iconMap['default']!;
  }
} 