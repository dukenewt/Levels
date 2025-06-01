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
import '../widgets/task_creation_dialog.dart';

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

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  String? _error;

  // --- Interactive flip animation fields ---
  late AnimationController _flipController;
  double _dragStartX = 0.0;
  double _dragDx = 0.0;
  bool _isDragging = false;
  DateTime? _pendingDay; // The day to show during the flip

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _initializeData();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: -1.0,
      upperBound: 1.0,
      value: 0.0,
    );
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
    _flipController.dispose();
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
                            _flipController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onHorizontalDragStart: (details) {
                              _dragStartX = details.localPosition.dx;
                              _dragDx = 0.0;
                              _isDragging = true;
                            },
                            onHorizontalDragUpdate: (details) {
                              if (!_isDragging) return;
                              _dragDx = details.localPosition.dx - _dragStartX;
                              double progress = (_dragDx / 200.0).clamp(-1.0, 1.0);
                              _flipController.value = progress;
                              setState(() {
                                if (progress > 0.0) {
                                  _pendingDay = _selectedDay?.subtract(const Duration(days: 1));
                                } else if (progress < 0.0) {
                                  _pendingDay = _selectedDay?.add(const Duration(days: 1));
                                } else {
                                  _pendingDay = null;
                                }
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              _isDragging = false;
                              final threshold = 0.4;
                              if (_flipController.value > threshold) {
                                // Flip to previous day
                                _flipController.animateTo(1.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut).then((_) {
                                  if (!mounted) return;
                                  setState(() {
                                    _selectedDay = _selectedDay?.subtract(const Duration(days: 1));
                                    _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                                    _pendingDay = null;
                                    _flipController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                  });
                                });
                              } else if (_flipController.value < -threshold) {
                                // Flip to next day
                                _flipController.animateTo(-1.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut).then((_) {
                                  if (!mounted) return;
                                  setState(() {
                                    _selectedDay = _selectedDay?.add(const Duration(days: 1));
                                    _focusedDay = _focusedDay.add(const Duration(days: 1));
                                    _pendingDay = null;
                                    _flipController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                  });
                                });
                              } else {
                                // Snap back
                                _flipController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                setState(() {
                                  _pendingDay = null;
                                });
                              }
                            },
                            child: AnimatedBuilder(
                              animation: _flipController,
                              builder: (context, child) {
                                final double animValue = _flipController.value;
                                final double angle = animValue * 1.5708; // up to +/- 90 degrees
                                final bool showPending = _pendingDay != null && animValue.abs() > 0.01;
                                final DateTime displayDay = showPending ? _pendingDay! : (_selectedDay ?? DateTime.now());
                                // Fade and shadow effect
                                final double fade = 1.0 - (animValue.abs() * 0.7);
                                final double shadowStrength = (animValue.abs() * 0.18) + 0.04;
                                return Opacity(
                                  opacity: fade.clamp(0.3, 1.0),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateY(angle),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(shadowStrength),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        DateFormat('EEEE, MMMM d, yyyy').format(displayDay),
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                            _flipController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
                        if (direction == DismissDirection.startToEnd) {
                          // Delete
                          final deletedTask = task;
                          await taskProvider.deleteTask(task.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Task deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await taskProvider.createTask(deletedTask);
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                          setState(() {});
                        } else if (direction == DismissDirection.endToStart) {
                          // Complete
                          await taskProvider.completeTask(task.id);
                          if (!mounted) return;
                          setState(() {});
                        }
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
                        if (direction == DismissDirection.startToEnd) {
                          final deletedTask = task;
                          await taskProvider.deleteTask(task.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Task deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await taskProvider.createTask(deletedTask);
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                          setState(() {});
                        } else if (direction == DismissDirection.endToStart) {
                          await taskProvider.completeTask(task.id);
                          if (!mounted) return;
                          setState(() {});
                        }
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
                        if (direction == DismissDirection.startToEnd) {
                          final deletedTask = task;
                          await taskProvider.deleteTask(task.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Task deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await taskProvider.createTask(deletedTask);
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                          setState(() {});
                        } else if (direction == DismissDirection.endToStart) {
                          await taskProvider.completeTask(task.id);
                          if (!mounted) return;
                          setState(() {});
                        }
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
              showDialog(
                context: context,
                builder: (context) => TaskCreationDialog(),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
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
      default:
        return Icons.star;
    }
  }
} 