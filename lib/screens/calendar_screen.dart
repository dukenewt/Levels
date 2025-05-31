import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import '../widgets/task_creation_dialog.dart';
import '../widgets/task_editing_dialog.dart';
import '../providers/user_provider.dart';
import '../screens/task_dashboard_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/profile_screen.dart';
import 'dart:async';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _events = {};
  late AnimationController _animationController;
  String? _selectedCategory;
  bool _showMiniCalendar = false;
  String _currentView = 'day'; // 'day', 'week', or 'month'
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  String? _error;

  final List<String> _categories = ['All', 'Work', 'Personal', 'Health', 'Learning', 'Other'];
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<int> _workWeekDays = [1, 2, 3, 4, 5]; // Monday to Friday

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Defer recurring task window maintenance until after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      // taskProvider.maintainRecurringTaskWindow().then((_) {
      //   _initializeData();
      // });
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Load data in parallel using Future.wait
      await Future.wait([
        _loadEvents(),
        _loadCategories(),
      ]);
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

  Future<void> _loadEvents() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    Map<DateTime, List<Task>> newEvents = {};
    
    // Calculate the date range based on current view
    DateTime startDate;
    DateTime endDate;
    
    if (_currentView == 'day') {
      startDate = _focusedDay;
      endDate = _focusedDay;
    } else if (_currentView == 'week') {
      startDate = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else { // month view
      startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    }
    
    // Load tasks for each day in the range
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final tasks = await taskProvider.getTasksForDate(date);
      newEvents[DateTime(date.year, date.month, date.day)] = tasks;
    }
    
    if (!mounted) return;
    
    setState(() {
      _events = newEvents;
    });
  }

  Future<void> _loadCategories() async {
    // Load categories from storage or use defaults
    if (!mounted) return;
    
    setState(() {
      _selectedCategory = 'All';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Task> _getEventsForDay(DateTime day) {
    // Normalize the date to remove time component
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final tasks = _events[normalizedDate] ?? [];
    
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return tasks;
    }
    return tasks.where((task) => task.category == _selectedCategory).toList();
  }

  List<Task> _getEventsForTimeSlot(DateTime day, TimeOfDay time) {
    return _getEventsForDay(day).where((task) {
      if (task.scheduledTime == null) return false;
      return task.scheduledTime!.hour == time.hour && 
             task.scheduledTime!.minute == time.minute;
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return const Color(0xFF78A1E8);
      case 'personal':
        return const Color(0xFFF5AC3D);
      case 'health':
        return const Color(0xFF4CAF50);
      case 'learning':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }

  Widget _buildTaskTile(Task task, BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    return Dismissible(
      key: ValueKey('calendar-${task.id}'),
      direction: DismissDirection.startToEnd, // swipe right to delete
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await taskProvider.deleteTask(task.id);
        _loadEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Optionally, implement undo logic here if you want
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => TaskEditingDialog(task: task),
          ).then((_) {
            _loadEvents();
          });
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Task'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => TaskEditingDialog(task: task),
                    ).then((_) {
                      _loadEvents();
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Mark as Complete'),
                  onTap: () {
                    Navigator.pop(context);
                    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                    taskProvider.completeTask(task.id);
                    _loadEvents();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Task', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Task'),
                        content: const Text('Are you sure you want to delete this task?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                              taskProvider.deleteTask(task.id);
                              Navigator.pop(context);
                              _loadEvents();
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getCategoryColor(task.category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (task.scheduledTime != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    task.scheduledTime!.format(context),
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (task.recurrencePattern != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.recurrencePattern!.substring(0, 1).toUpperCase() + task.recurrencePattern!.substring(1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekGridView() {
    final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final hours = List.generate(24, (i) => i);

    return SizedBox(
      height: 1440.0, // 24 hours * 60px per hour
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 7 * 120.0 + 60, // 120 per day + 60 for hour column
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    Container(width: 60, height: 40), // Empty top-left
                    ...days.map((day) => Container(
                          width: 120,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                            border: Border(
                              right: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          child: Text(
                            DateFormat('EEE\nMM/dd').format(day),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        )),
                  ],
                ),
                // All hour rows
                ...hours.map((hour) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                          border: Border(
                            right: BorderSide(color: Theme.of(context).dividerColor),
                            top: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      ...days.map((day) {
                        final tasks = _getEventsForTimeSlot(day, TimeOfDay(hour: hour, minute: 0));
                        return Container(
                          width: 120,
                          height: 60,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Theme.of(context).dividerColor),
                              top: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          child: tasks.isEmpty
                              ? null
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...tasks.take(2).map((task) => Row(
                                      children: [
                                        if (task.recurrencePattern != null)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 2),
                                            child: Icon(Icons.repeat, size: 12, color: Theme.of(context).colorScheme.secondary),
                                          ),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )),
                                    if (tasks.length > 2)
                                      Text('+${tasks.length - 2} more', style: Theme.of(context).textTheme.labelSmall),
                                  ],
                                ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyView() {
    // Get all tasks for the focused day (like week/month views)
    final dayTasks = _getEventsForDay(_focusedDay)
        .where((task) => !task.isCompleted)
        .toList();
    // Floating tasks: no dueDate and not completed
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final floatingTasks = taskProvider.tasks
        .where((task) => task.dueDate == null && !task.isCompleted)
        .toList();

    // Group dayTasks by hour for display
    Map<int, List<Task>> tasksByHour = {};
    for (var task in dayTasks) {
      int hour = 0;
      if (task.scheduledTime != null) {
        hour = task.scheduledTime!.hour;
      } else if (task.dueDate != null) {
        hour = task.dueDate!.hour;
      }
      tasksByHour.putIfAbsent(hour, () => []).add(task);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                });
                _loadEvents();
              },
            ),
            Text(
              DateFormat('EEEE, MMMM d, y').format(_focusedDay),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = _focusedDay.add(const Duration(days: 1));
                });
                _loadEvents();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Floating Tasks Section
        if (floatingTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Floating Tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...floatingTasks.map((task) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildTaskTile(task, context),
          )),
        ],
        // Timed Tasks by Hour (including all-day tasks at hour 0)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 24, // Hours in a day
          itemBuilder: (context, hour) {
            final tasks = tasksByHour[hour] ?? [];
            return Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      TimeOfDay(hour: hour, minute: 0).format(context),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: tasks.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tasks.length,
                            itemBuilder: (context, idx) {
                              final task = tasks[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: _buildTaskTile(task, context),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildXPProgressBar() {
    final userProvider = Provider.of<UserProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    
    final totalTasks = taskProvider.tasks.length;
    final completedTasks = taskProvider.tasks.where((task) => task.isCompleted).length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$completedTasks/$totalTasks Tasks',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current XP: ${userProvider.currentXp}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Level ${userProvider.level}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButton<String>(
        value: _currentView,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'day', child: Text('Day View')),
          DropdownMenuItem(value: 'week', child: Text('Week View')),
          DropdownMenuItem(value: 'month', child: Text('Month View')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _currentView = value;
              if (value == 'month') {
                _calendarFormat = CalendarFormat.month;
              } else if (value == 'week') {
                _calendarFormat = CalendarFormat.week;
              }
            });
            _loadEvents();
          }
        },
      ),
    );
  }

  Widget _buildTaskDot(Task task) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _getCategoryColor(task.category),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTaskDots(List<Task> tasks) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tasks.take(3).map(_buildTaskDot).toList(),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                if (_currentView == 'day') {
                  _selectedTime = TimeOfDay.now();
                }
              });
              _loadEvents();
              _animationController.forward(from: 0);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleLarge!,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: _buildTaskDots(events.cast<Task>()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    
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
              selected: true,
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
              onTap: () {
                debugPrint('Drawer: Profile tapped');
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != 'ProfileScreen') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                      settings: const RouteSettings(name: 'ProfileScreen'),
                    ),
                  );
                }
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
        title: const Text('Calendar'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _currentView == 'day' 
                ? _buildDailyView() 
                : _currentView == 'week' 
                  ? _buildWeekGridView() 
                  : _buildMonthView(),
              const SizedBox(height: 16),
              _buildViewSelector(),
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(category),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                          });
                        },
                        backgroundColor: theme.cardColor,
                        selectedColor: _getCategoryColor(category),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _buildXPProgressBar(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => TaskCreationDialog(
              initialDate: _selectedDay,
              initialTime: _selectedTime,
            ),
          ).then((_) {
            _loadEvents();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthView() {
    // Get all tasks for the month
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final allMonthTasks = <Task>[];
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      final day = firstDayOfMonth.add(Duration(days: i));
      allMonthTasks.addAll(_getEventsForDay(day).where((task) => !task.isCompleted));
    }
    // Group tasks by date
    final Map<String, List<Task>> tasksByDate = {};
    for (final task in allMonthTasks) {
      if (task.dueDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(task.dueDate!);
        tasksByDate.putIfAbsent(dateKey, () => []).add(task);
      }
    }
    final sortedDateKeys = tasksByDate.keys.toList()..sort();
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sortedDateKeys.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }
        final dateKey = sortedDateKeys[index - 1];
        final date = DateTime.parse(dateKey);
        final tasks = tasksByDate[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                DateFormat('EEE, MMM d').format(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...tasks.map((task) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildTaskTile(task, context),
            )),
          ],
        );
      },
    );
  }
} 