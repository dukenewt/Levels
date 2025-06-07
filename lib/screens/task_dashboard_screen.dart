import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/secure_user_provider.dart';
import '../providers/secure_task_provider.dart';
import '../providers/skill_provider.dart';
import '../widgets/level_progress_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_tasks_placeholder.dart';
import '../models/task.dart';
import '../models/skill.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';
import 'skills_screen.dart';
import 'skill_details_screen.dart';
import '../widgets/level_indicator.dart';
import 'settings_screen.dart';
import '../providers/settings_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../widgets/task_creation_dialog.dart';
import 'notification_preferences_screen.dart';
import '../widgets/professional_task_tile.dart';
import '../widgets/professional_progress_card.dart';
import '../widgets/smart_suggestions_widget.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  final List<String> _defaultCategories = ['Work', 'Personal', 'Health', 'Learning', 'Other'];
  List<String> _customCategories = [];

  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'agenda'; // 'agenda', 'today', 'week'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400) {
      if (!_showScrollToTop) setState(() => _showScrollToTop = true);
    } else {
      if (_showScrollToTop) setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  // Group tasks by date for display
  Map<DateTime, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final Map<DateTime, List<Task>> grouped = {};
    
    for (final task in tasks) {
      DateTime dateKey;
      
      if (task.dueDate != null) {
        // Use the task's due date (normalized to day only)
        dateKey = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      } else {
        // Tasks without dates go to a special "No Date" category
        dateKey = DateTime(1970, 1, 1); // Epoch as placeholder for "no date"
      }
      
      grouped.putIfAbsent(dateKey, () => []).add(task);
    }
    
    return grouped;
  }

  // Get tasks for the next 7 days for agenda view
  Map<DateTime, List<Task>> _getAgendaTasks(List<Task> allTasks) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(const Duration(days: 7));
    
    final relevant = allTasks.where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return true; // Include no-date tasks
      
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return !taskDate.isBefore(startDate) && !taskDate.isAfter(endDate);
    }).toList();
    
    return _groupTasksByDate(relevant);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<SecureUserProvider>(context);
    final taskProvider = Provider.of<SecureTaskProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar with view mode selector
          SliverAppBar(
            title: Text('Daily XP', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            floating: true,
            actions: [
              // View mode selector
              PopupMenuButton<String>(
                initialValue: _viewMode,
                onSelected: (value) => setState(() => _viewMode = value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'agenda', child: Text('Agenda (7 days)')),
                  const PopupMenuItem(value: 'today', child: Text('Today Only')),
                  const PopupMenuItem(value: 'week', child: Text('This Week')),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_viewMode.toUpperCase(), style: const TextStyle(fontSize: 12)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to settings
                },
              ),
            ],
          ),

          // Progress card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Consumer<SecureUserProvider>(
                    builder: (context, userProvider, child) {
                      return ProfessionalProgressCard(
                        title: 'Level',
                        currentValue: userProvider.currentXp,
                        maxValue: userProvider.nextLevelXp,
                        color: theme.colorScheme.primary,
                        subtitle: 'Level ${userProvider.level}',
                        onTap: () {},
                      );
                    },
                  ),
                  const SmartSuggestionsWidget(),
                ],
              ),
            ),
          ),

          // Date navigation (for today/week views)
          if (_viewMode != 'agenda')
            SliverToBoxAdapter(child: _buildDateNavigation()),

          // Task sections based on view mode
          ..._buildTaskSections(taskProvider.getFilteredActiveTasks(context)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_showScrollToTop)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FloatingActionButton.small(
                heroTag: 'scrollToTop',
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_upward),
              ),
            ),
          FloatingActionButton(
            heroTag: 'addTask',
            onPressed: () => showDialog(context: context, builder: (context) => TaskCreationDialog()),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            }),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
            }),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskSections(List<Task> allTasks) {
    Map<DateTime, List<Task>> groupedTasks;
    
    switch (_viewMode) {
      case 'today':
        groupedTasks = _getTodayTasks(allTasks);
        break;
      case 'week':
        groupedTasks = _getWeekTasks(allTasks);
        break;
      case 'agenda':
      default:
        groupedTasks = _getAgendaTasks(allTasks);
        break;
    }

    if (groupedTasks.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('No tasks found for this period')),
        )
      ];
    }

    final sections = <Widget>[];
    
    // Sort dates (but put "no date" tasks at the end)
    final sortedDates = groupedTasks.keys.toList()..sort((a, b) {
      // Put epoch date (no date tasks) at the end
      if (a.year == 1970) return 1;
      if (b.year == 1970) return -1;
      return a.compareTo(b);
    });

    for (final date in sortedDates) {
      final tasks = groupedTasks[date]!;
      sections.add(_buildDateSection(date, tasks));
    }

    return sections;
  }

  Widget _buildDateSection(DateTime date, List<Task> tasks) {
    // Handle "no date" tasks
    if (date.year == 1970) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeader('No Date Set', tasks.length),
          ...tasks.map((task) => _buildTaskTile(task)),
          const SizedBox(height: 16),
        ]),
      );
    }

    // Regular date sections
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    String sectionTitle;
    if (date.isAtSameMomentAs(today)) {
      sectionTitle = 'Today';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      sectionTitle = 'Tomorrow';
    } else {
      sectionTitle = DateFormat('EEEE, MMM d').format(date);
    }

    // Group by time within the day
    final timedTasks = tasks.where((t) => t.scheduledTime != null).toList();
    final allDayTasks = tasks.where((t) => t.scheduledTime == null).toList();

    // Sort timed tasks by time
    timedTasks.sort((a, b) {
      final aTime = a.scheduledTime!.hour * 60 + a.scheduledTime!.minute;
      final bTime = b.scheduledTime!.hour * 60 + b.scheduledTime!.minute;
      return aTime.compareTo(bTime);
    });

    return SliverList(
      delegate: SliverChildListDelegate([
        _buildSectionHeader(sectionTitle, tasks.length),
        
        // All day tasks first
        if (allDayTasks.isNotEmpty) ...[
          _buildSubSectionHeader('All Day'),
          ...allDayTasks.map((task) => _buildTaskTile(task)),
        ],
        
        // Timed tasks
        if (timedTasks.isNotEmpty) ...[
          if (allDayTasks.isNotEmpty) _buildSubSectionHeader('Scheduled'),
          ...timedTasks.map((task) => _buildTaskTile(task)),
        ],
        
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 24, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ProfessionalTaskTile(
        key: ValueKey(task.id),
        task: task,
        onComplete: () async {
          final taskProvider = Provider.of<SecureTaskProvider>(context, listen: false);
          await taskProvider.completeTask(task.id);
        },
        onEdit: () {
          // Handle edit
        },
        showTime: true,
      ),
    );
  }

  // Helper methods for different view modes
  Map<DateTime, List<Task>> _getTodayTasks(List<Task> allTasks) {
    final today = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final relevantTasks = allTasks.where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return false;
      
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return taskDate.isAtSameMomentAs(today);
    }).toList();
    
    return {today: relevantTasks};
  }

  Map<DateTime, List<Task>> _getWeekTasks(List<Task> allTasks) {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final relevantTasks = allTasks.where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return false;
      
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return !taskDate.isBefore(startOfWeek) && !taskDate.isAfter(endOfWeek);
    }).toList();
    
    return _groupTasksByDate(relevantTasks);
  }
} 