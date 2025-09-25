import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'settings_screen.dart';
import '../widgets/task_creation_dialog.dart';
import '../widgets/task_tile.dart';
// import '../widgets/professional_progress_card.dart';
import '../widgets/task_editing_dialog.dart';
import '../widgets/unified_progress_bar.dart';
import '../widgets/wheel_of_time_progress.dart';
import '../services/enhanced_game_experience_manager.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  final List<String> _defaultCategories = [
    'Work',
    'Personal',
    'Health',
    'Learning',
    'Other'
  ];
  List<String> _customCategories = [];

  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'agenda'; // 'agenda', 'today', 'week'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Initialize the enhanced game experience manager after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        EnhancedGameExperienceManager.instance.initialize(context);
        debugPrint('🎮 Enhanced GameExperienceManager initialized');
      }
    });
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
        dateKey = DateTime(
            task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
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

      final taskDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return !taskDate.isBefore(startDate) && !taskDate.isAfter(endDate);
    }).toList();

    return _groupTasksByDate(relevant);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar with view mode selector
          SliverAppBar(
            title: Text('TaskBound',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            floating: true,
            actions: [
              // View mode selector
              Container(
                margin: const EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: PopupMenuButton<String>(
                  initialValue: _viewMode,
                  onSelected: (value) => setState(() => _viewMode = value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'agenda',
                      child: Text('Agenda (7 days)'),
                    ),
                    PopupMenuItem(
                      value: 'today',
                      child: Text('Today Only'),
                    ),
                    PopupMenuItem(
                      value: 'week',
                      child: Text('This Week'),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _viewMode.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),

          // Progress card - Wheel of Time style
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: const WheelOfTimeProgress(),
            ),
          ),

          // Date navigation (for today/week views)
          if (_viewMode != 'agenda')
            SliverToBoxAdapter(child: _buildDateNavigation()),

          // Task sections based on view mode
          ..._buildTaskSections(taskProvider.getFilteredActiveTasks(context)),

          // Completed tasks section
          _buildCompletedTasksSection(taskProvider.completedTasks),
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
            onPressed: () => showDialog(
                context: context, builder: (context) => TaskCreationDialog()),
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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
    final sortedDates = groupedTasks.keys.toList()
      ..sort((a, b) {
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TaskTile(
        key: ValueKey(task.id),
        task: task,
        onEdit: () => _showEditTaskDialog(context, task: task),
        confirmDismiss: (direction) =>
            _handleSwipeDismiss(context, task, direction),
      ),
    );
  }

  /// Handle swipe gestures on tasks
  Future<bool> _handleSwipeDismiss(
      BuildContext context, Task task, DismissDirection direction) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (direction == DismissDirection.startToEnd) {
      // Swipe right to complete
      if (!task.isCompleted) {
        await taskProvider.completeTask(context, task);
        return true; // Allow dismissal
      }
      return false; // Prevent dismissal if already completed
    } else if (direction == DismissDirection.endToStart) {
      // Swipe left to delete - show confirmation, but don't dismiss yet
      _showDeleteConfirmation(context, task);
      return false; // Prevent immediate dismissal
    }

    return false; // Default: prevent dismissal
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
            'Are you sure you want to delete "${task.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.deleteTask(task.id);

      // Show undo snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${task.title}"'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () => taskProvider.undoTaskDeletion(context, task),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildCompletedTasksSection(List<Task> completedTasks) {
    if (completedTasks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ExpansionTile(
          title: Text(
            'Completed (${completedTasks.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          children: completedTasks.map((task) => _buildTaskTile(task)).toList(),
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, {required Task task}) {
    TaskEditingDialog.showEditDialog(context, task);
  }

  // Helper methods for different view modes
  Map<DateTime, List<Task>> _getTodayTasks(List<Task> allTasks) {
    final today =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final relevantTasks = allTasks.where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return false;

      final taskDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return taskDate.isAtSameMomentAs(today);
    }).toList();

    return {today: relevantTasks};
  }

  Map<DateTime, List<Task>> _getWeekTasks(List<Task> allTasks) {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final relevantTasks = allTasks.where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return false;

      final taskDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return !taskDate.isBefore(startOfWeek) && !taskDate.isAfter(endOfWeek);
    }).toList();

    return _groupTasksByDate(relevantTasks);
  }
}
