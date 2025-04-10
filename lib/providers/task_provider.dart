import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'user_provider.dart';
import 'skill_provider.dart';
import 'settings_provider.dart';
import '../widgets/level_up_overlay.dart';
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';

class TaskProvider with ChangeNotifier {
  final UserProvider _userProvider;
  final SkillProvider _skillProvider;
  final StorageService _storage;
  List<Task> _tasks = [];
  final Map<String, List<Task>> _tasksByCategory = {};
  bool _isLoading = false;
  OverlayEntry? _levelUpOverlay;
  final _uuid = const Uuid();

  TaskProvider(this._userProvider, this._skillProvider, this._storage) {
    // Initialize with mock tasks
    _tasks = [
      Task(
        id: '1',
        title: 'Complete Project Setup',
        description: 'Set up the initial project structure and dependencies',
        category: 'work',
        xpReward: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: false,
      ),
      Task(
        id: '2',
        title: 'Design UI Components',
        description: 'Create wireframes and mockups for the main UI components',
        category: 'work',
        xpReward: 150,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        isCompleted: false,
      ),
      Task(
        id: '3',
        title: 'Exercise',
        description: '30 minutes of cardio and strength training',
        category: 'exercise',
        xpReward: 50,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isCompleted: false,
      ),
    ];

    _updateTasksByCategory();
  }

  List<Task> get tasks => _tasks;
  Map<String, List<Task>> get tasksByCategory => _tasksByCategory;
  
  // Get active (uncompleted) tasks
  List<Task> get activeTasks => _tasks.where((task) => !task.isCompleted).toList();
  
  // Get filtered active tasks based on settings
  List<Task> getFilteredActiveTasks(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return activeTasks.where((task) {
      if (settings.showWorkTasks && task.category.toLowerCase() == 'work') return true;
      if (settings.showSchoolTasks && task.category.toLowerCase() == 'school') return true;
      if (settings.showExerciseTasks && task.category.toLowerCase() == 'exercise') return true;
      return false;
    }).toList();
  }
  
  // Get completed tasks for today
  List<Task> get completedTasksToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final completedToday = _tasks.where((task) {
      if (!task.isCompleted || task.completedAt == null) return false;
      
      final completedDate = DateTime(
        task.completedAt!.year,
        task.completedAt!.month,
        task.completedAt!.day,
      );
      
      return completedDate.isAtSameMomentAs(today);
    }).toList();
    
    // Sort by completion time, most recent first
    completedToday.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    
    return completedToday;
  }

  // Get future tasks (tasks with due dates in the future)
  List<Task> get futureTasks {
    final now = DateTime.now();
    return _tasks.where((task) => 
      !task.isCompleted && 
      task.dueDate != null && 
      task.dueDate!.isAfter(now)
    ).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)); // Sort by due date
  }

  // Get tasks for the upcoming week
  List<Task> get tasksForUpcomingWeek {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return _tasks.where((task) {
      if (task.isCompleted) return false;
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(now) && task.dueDate!.isBefore(weekFromNow);
    }).toList();
  }
  
  bool get isLoading => _isLoading;

  void addTask(Task task) {
    _tasks.add(task);
    _updateTasksByCategory();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
        await _storage.updateTask(task);
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  DateTime _calculateNextOccurrence(Task task) {
    if (task.recurrencePattern == null || task.dueDate == null) {
      return task.dueDate!;
    }

    DateTime nextDate = task.dueDate!;
    final now = DateTime.now();

    // Calculate the next occurrence based on the recurrence pattern
    switch (task.recurrencePattern) {
      case 'daily':
        // For daily tasks, add 1 day to the current date
        nextDate = DateTime(
          now.year,
          now.month,
          now.day,
          task.dueDate!.hour,
          task.dueDate!.minute,
        ).add(const Duration(days: 1));
        break;
      case 'weekly':
        // For weekly tasks, add 7 days to the current date
        nextDate = DateTime(
          now.year,
          now.month,
          now.day,
          task.dueDate!.hour,
          task.dueDate!.minute,
        ).add(const Duration(days: 7));
        break;
      case 'monthly':
        // For monthly tasks, add 1 month to the current date
        if (now.month == 12) {
          // If current month is December, move to next year
          nextDate = DateTime(
            now.year + 1,
            1,
            task.dueDate!.day,
            task.dueDate!.hour,
            task.dueDate!.minute,
          );
        } else {
          nextDate = DateTime(
            now.year,
            now.month + 1,
            task.dueDate!.day,
            task.dueDate!.hour,
            task.dueDate!.minute,
          );
        }
        break;
      default:
        return nextDate;
    }

    // Ensure the next date is in the future
    while (nextDate.isBefore(now)) {
      switch (task.recurrencePattern) {
        case 'daily':
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          if (nextDate.month == 12) {
            nextDate = DateTime(
              nextDate.year + 1,
              1,
              nextDate.day,
              nextDate.hour,
              nextDate.minute,
            );
          } else {
            nextDate = DateTime(
              nextDate.year,
              nextDate.month + 1,
              nextDate.day,
              nextDate.hour,
              nextDate.minute,
            );
          }
          break;
      }
    }

    print('Calculated next occurrence for ${task.title}: $nextDate'); // Debug print
    return nextDate;
  }

  void _checkLevelUp(BuildContext context) {
    final previousLevel = _userProvider.level;
    final currentLevel = _userProvider.level;
    if (currentLevel > previousLevel) {
      _showLevelUpOverlay(context, currentLevel);
    }
  }

  Future<void> _showLevelUpOverlay(BuildContext context, int newLevel) async {
    if (!context.mounted) return;
    
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Level Up!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'You reached level $newLevel!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    entry.remove();
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    
    // Auto-remove after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (context.mounted && overlay.mounted) {
      entry.remove();
    }
  }

  @override
  void dispose() {
    if (_levelUpOverlay != null) {
      _levelUpOverlay!.remove();
      _levelUpOverlay = null;
    }
    super.dispose();
  }

  Future<void> completeTask(String taskId) async {
    debugPrint('Starting task completion for task: $taskId');
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    debugPrint('Adding XP reward: ${task.xpReward}');

    // Update task completion status
    _tasks[taskIndex] = task.copyWith(isCompleted: true);
    
    // Add XP to user's total XP
    await _userProvider.addXp(task.xpReward);
    
    // Add XP to the associated skill
    final skillId = task.category.toLowerCase();
    _skillProvider.addXpToSkill(skillId, task.xpReward);
    
    _updateTasksByCategory();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    try {
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      await _storage.deleteTask(taskId);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      // Mock tasks are already set in constructor
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateTasksByCategory() {
    _tasksByCategory.clear();
    for (var task in _tasks) {
      if (!_tasksByCategory.containsKey(task.category)) {
        _tasksByCategory[task.category] = [];
      }
      _tasksByCategory[task.category]!.add(task);
    }
  }

  set tasks(List<Task> newTasks) {
    _tasks = newTasks;
    notifyListeners();
  }
} 