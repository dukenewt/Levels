import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
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

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  final List<String> _defaultCategories = ['Work', 'Personal', 'Health', 'Learning', 'Other'];
  List<String> _customCategories = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final skillProvider = Provider.of<SkillProvider>(context, listen: false);
      
      // Use compute to run heavy operations in a separate isolate
      await Future.microtask(() {
        if (!mounted) return;
        skillProvider.loadSkills();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading data: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= 400) {
      if (!_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      }
    } else {
      if (_showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _showAddCategoryDialog(BuildContext taskDialogContext) {
    final categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name (max 20 characters)',
              counterText: '0/20',
            ),
            maxLength: 20,
            onChanged: (value) {
              // Update counter text
              (context as Element).markNeedsBuild();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCategory = categoryController.text.trim();
                if (newCategory.isNotEmpty && 
                    !_defaultCategories.contains(newCategory) && 
                    !_customCategories.contains(newCategory)) {
                  setState(() {
                    _customCategories.add(newCategory);
                  });
                  Navigator.pop(context);
                  // Force rebuild of the task dialog
                  (taskDialogContext as Element).markNeedsBuild();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A43),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final skillProvider = Provider.of<SkillProvider>(context);
    final theme = Theme.of(context);
    
    // Filter tasks for selected day
    List<Task> filteredTasks = _selectedDay == null
      ? taskProvider.getFilteredActiveTasks(context)
      : taskProvider.getFilteredActiveTasks(context).where((task) {
          if (task.dueDate == null) return false;
          return task.dueDate!.year == _selectedDay!.year &&
                 task.dueDate!.month == _selectedDay!.month &&
                 task.dueDate!.day == _selectedDay!.day;
        }).toList();

    // All Day tasks: tasks with a date but no time (00:00)
    List<Task> allDayTasks = filteredTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.hour == 0 && task.dueDate!.minute == 0;
    }).toList();

    // Timed tasks: tasks with a date and a time
    List<Task> timedTasks = filteredTasks.where((task) {
      if (task.dueDate == null) return false;
      return !(task.dueDate!.hour == 0 && task.dueDate!.minute == 0);
    }).toList();

    // No Date tasks: tasks with no dueDate at all
    List<Task> noDateTasks = taskProvider.getFilteredActiveTasks(context)
        .where((task) => task.dueDate == null && !task.isCompleted)
        .toList();

    // Get tasks for the next 7 days (week view)
    List<Map<String, dynamic>> weekTasks = List.generate(7, (i) {
      final day = _focusedDay.add(Duration(days: i - _focusedDay.weekday + 1));
      final tasksForDay = taskProvider.getFilteredActiveTasks(context).where((task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.year == day.year &&
               task.dueDate!.month == day.month &&
               task.dueDate!.day == day.day;
      }).toList();
      return {'date': day, 'tasks': tasksForDay};
    });

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
              selected: true,
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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            title: Text(
              'Daily XP',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Implement notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level Progress Card
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return LevelProgressCard(
                        level: userProvider.level,
                        currentXp: userProvider.currentXp,
                        nextLevelXp: userProvider.nextLevelXp,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Calendar Widget
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily View Header ONLY (no calendar)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _selectedDay = _selectedDay?.subtract(const Duration(days: 1));
                              _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                            });
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay ?? DateTime.now()),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              _selectedDay = _selectedDay?.add(const Duration(days: 1));
                              _focusedDay = _focusedDay.add(const Duration(days: 1));
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filteredTasks.isEmpty && noDateTasks.isEmpty)
            const SliverFillRemaining(
              child: EmptyTasksPlaceholder(),
            )
          else ...[
            SliverList(
              delegate: SliverChildListDelegate([
                // Active Tasks Section
                if (timedTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Tasks for ${DateFormat('MMM d, yyyy').format(_selectedDay!)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...timedTasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TaskTile(
                      key: ValueKey("active-${task.id}"),
                      task: task,
                      onDismissed: (direction) async {
                        await taskProvider.completeTask(task.id);
                        if (!mounted) return;
                        setState(() {}); // Refresh the UI after task completion
                      },
                    ),
                  )).toList(),
                ],
                if (allDayTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'All Day',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...allDayTasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TaskTile(
                      key: ValueKey("allday-${task.id}"),
                      task: task,
                      onDismissed: (direction) async {
                        await taskProvider.completeTask(task.id);
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  )).toList(),
                ],
                // Floating Tasks Section (move above completed)
                if (noDateTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Floating Tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...noDateTasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TaskTile(
                      key: ValueKey("floating-${task.id}"),
                      task: task,
                      onDismissed: (direction) async {
                        await taskProvider.completeTask(task.id);
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  )).toList(),
                ],
                // Skills Progress Section (move above completed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                  child: ExpansionTile(
                    title: Text(
                      'Skills Progress',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    leading: const Icon(Icons.bar_chart),
                    children: [
                      Consumer<SkillProvider>(
                        builder: (context, skillProvider, child) {
                          final skills = skillProvider.skills;
                          return Column(
                            children: skills.map((skill) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SkillDetailsScreen(skill: skill),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
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
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    skill.name,
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Level ${skill.level}',
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: skill.color.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${skill.currentXp} / ${skill.xpForNextLevel} XP',
                                                style: TextStyle(
                                                  color: skill.color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: skill.progressPercentage / 100,
                                            backgroundColor: skill.color.withOpacity(0.1),
                                            valueColor: AlwaysStoppedAnimation<Color>(skill.color),
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          skill.description,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Completed Tasks Section (move below skills progress)
                if (taskProvider.completedTasksToday.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Completed Today',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...taskProvider.completedTasksToday.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: TaskTile(
                      key: ValueKey("completed-${task.id}"),
                      task: task,
                      onDismissed: null, // Completed tasks can't be dismissed
                    ),
                  )).toList(),
                ],
                // Add some padding at the bottom
                const SizedBox(height: 24),
              ]),
            ),
          ],
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
            onPressed: () {
              _showAddTaskDialog(context, taskProvider);
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
  
  void _showAddTaskDialog(BuildContext context, TaskProvider taskProvider) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = _defaultCategories.first;
    int xpReward = 50;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? selectedRecurrence;
    String? selectedSkillId;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final skillProvider = Provider.of<SkillProvider>(context, listen: false);
            final skills = skillProvider.skills;

            return AlertDialog(
              title: const Text('Add New Task'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task Title Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          hintText: 'Enter task title',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter task description (optional)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // XP Reward Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'XP Reward',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8A43).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$xpReward XP',
                                style: const TextStyle(
                                  color: Color(0xFFFF8A43),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFFF8A43),
                            inactiveTrackColor: const Color(0xFFFF8A43).withOpacity(0.1),
                            thumbColor: const Color(0xFFFF8A43),
                            overlayColor: const Color(0xFFFF8A43).withOpacity(0.1),
                            valueIndicatorColor: const Color(0xFFFF8A43),
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8.0,
                              elevation: 2.0,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16.0,
                            ),
                          ),
                          child: Slider(
                            value: xpReward.toDouble(),
                            min: 10,
                            max: 200,
                            divisions: 190,
                            label: '$xpReward XP',
                            onChanged: (value) {
                              setDialogState(() {
                                xpReward = value.round();
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '10 XP',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8A43).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$xpReward XP',
                                  style: const TextStyle(
                                    color: Color(0xFFFF8A43),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '200 XP',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Skill Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Related Skill',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSkillId,
                              isExpanded: true,
                              hint: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Select a skill (optional)',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              iconSize: 24,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'None',
                                      style: TextStyle(
                                        color: selectedSkillId == null 
                                            ? const Color(0xFFFF8A43)
                                            : Colors.grey[800],
                                        fontWeight: selectedSkillId == null 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                ...skills.map((skill) => DropdownMenuItem<String>(
                                  value: skill.id,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: skill.color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            _getIconData(skill.icon),
                                            color: skill.color,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            skill.name,
                                            style: TextStyle(
                                              color: selectedSkillId == skill.id
                                                  ? const Color(0xFFFF8A43)
                                                  : Colors.grey[800],
                                              fontWeight: selectedSkillId == skill.id
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedSkillId = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Due Date & Time Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date & Time',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(
                                  'Date',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  selectedDate != null 
                                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                    : 'Not set',
                                  style: TextStyle(
                                    color: selectedDate != null ? Colors.grey[800] : Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.calendar_today, size: 20),
                                  color: const Color(0xFFFF8A43),
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setDialogState(() => selectedDate = date);
                                    }
                                  },
                                ),
                              ),
                              if (selectedDate != null) ...[
                                const Divider(height: 1),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  title: Text(
                                    'Time',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    selectedTime != null 
                                      ? selectedTime!.format(context)
                                      : 'Not set',
                                    style: TextStyle(
                                      color: selectedTime != null ? Colors.grey[800] : Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.access_time, size: 20),
                                    color: const Color(0xFFFF8A43),
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (time != null) {
                                        setDialogState(() => selectedTime = time);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Recurrence Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recurrence',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedRecurrence,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              hintText: 'Select recurrence pattern',
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'No recurrence',
                                  style: TextStyle(
                                    color: selectedRecurrence == null 
                                        ? const Color(0xFFFF8A43)
                                        : Colors.grey[800],
                                    fontWeight: selectedRecurrence == null 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'daily',
                                child: Text(
                                  'Daily',
                                  style: TextStyle(
                                    color: selectedRecurrence == 'daily'
                                        ? const Color(0xFFFF8A43)
                                        : Colors.grey[800],
                                    fontWeight: selectedRecurrence == 'daily'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text(
                                  'Weekly',
                                  style: TextStyle(
                                    color: selectedRecurrence == 'weekly'
                                        ? const Color(0xFFFF8A43)
                                        : Colors.grey[800],
                                    fontWeight: selectedRecurrence == 'weekly'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'monthly',
                                child: Text(
                                  'Monthly',
                                  style: TextStyle(
                                    color: selectedRecurrence == 'monthly'
                                        ? const Color(0xFFFF8A43)
                                        : Colors.grey[800],
                                    fontWeight: selectedRecurrence == 'monthly'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedRecurrence = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      final task = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        description: descriptionController.text.trim(),
                        category: '', // No category
                        xpReward: xpReward,
                        dueDate: selectedDate != null && selectedTime != null
                            ? DateTime(
                                selectedDate!.year,
                                selectedDate!.month,
                                selectedDate!.day,
                                selectedTime!.hour,
                                selectedTime!.minute,
                              )
                            : null,
                        recurrencePattern: selectedRecurrence,
                        skillId: selectedSkillId,
                      );

                      taskProvider.addTask(task);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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
      default:
        return Icons.star;
    }
  }
} 