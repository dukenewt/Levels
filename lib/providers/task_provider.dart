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
  List<Task> _tasks = [];
  final Map<String, List<Task>> _tasksByCategory = {};
  final TaskRepository _taskRepository;
  final UserProvider _userProvider;
  final SkillProvider _skillProvider;
  bool _isLoading = false;
  final _uuid = const Uuid();

  TaskProvider({
    required StorageService storage,
    required UserProvider userProvider,
    required SkillProvider skillProvider,
  }) : _taskRepository = storage.taskRepository,
       _userProvider = userProvider,
       _skillProvider = skillProvider {
    _loadTasks();
  }

  List<Task> get tasks => _tasks;
  Map<String, List<Task>> get tasksByCategory => _tasksByCategory;
  
  // Get active (uncompleted) tasks
  List<Task> get activeTasks => _tasks.where((task) => !task.isCompleted).toList();
  
  // Get filtered active tasks based on settings
  List<Task> getFilteredActiveTasks(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks.where((task) {
      // Filter out completed tasks
      if (task.isCompleted) return false;
      
      // For recurring tasks, check if they're due today or in the future
      if (task.recurrencePattern != null) {
        if (task.dueDate == null) return true;
        
        final dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        
        // Include tasks due today or in the future
        return !dueDate.isBefore(today);
      }
      
      // For non-recurring tasks, check if they're due today or in the future
      if (task.dueDate != null) {
        final dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        return !dueDate.isBefore(today);
      }
      
      // Include tasks with no due date
      return true;
    }).toList();
  }

  // Get tasks for a specific date
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      
      final taskDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      
      return taskDate.isAtSameMomentAs(targetDate);
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
      return completedDate.isAtSameMomentAs(today) && task.isCompleted;
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
        await _taskRepository.updateTask(task);
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

  Future<void> completeTask(String taskId) async {
    // Get a local copy of the task before any async operations
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    if (task.isCompleted) return;

    // Store task data we'll need later
    final xpReward = task.xpReward;
    final skillId = task.skillId;
    final recurrencePattern = task.recurrencePattern;

    try {
      // Update task completion status immediately
      _tasks[taskIndex] = task.complete();
      notifyListeners();

      // Save the task state
      await _saveTasks();

      // Handle XP and skills in a separate try-catch
      try {
        // Add XP to the user's overall XP
        await _userProvider.addXp(xpReward);

        // Add XP to the associated skill
        if (skillId != null) {
          await _skillProvider.addXP(skillId, xpReward);
        }
      } catch (e) {
        debugPrint('Error adding XP: $e');
        // Don't rethrow - we want to continue with task completion even if XP addition fails
      }

      // Handle recurring tasks
      if (recurrencePattern != null && task.dueDate != null) {
        DateTime? nextOccurrence = task.calculateNextOccurrence(task.dueDate);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Keep calculating next occurrences until we find one in the future
        while (nextOccurrence != null && !nextOccurrence.isAfter(today)) {
          nextOccurrence = task.calculateNextOccurrence(nextOccurrence);
        }

        if (nextOccurrence != null) {
          // Create a new task instance for the next occurrence
          final newTask = task.copyWith(
            id: const Uuid().v4(),
            dueDate: nextOccurrence,
            isCompleted: false,
            completedAt: null,
            parentTaskId: task.id,
          );

          // Add the new task
          _tasks.add(newTask);
          await _saveTasks();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error completing task: $e');
      // If we failed to complete the task, revert the completion status
      if (taskIndex < _tasks.length) {
        _tasks[taskIndex] = task;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> createTask(Task task) async {
    // Calculate XP reward based on difficulty if not provided
    final xpReward = task.xpReward == 50 ? Task.calculateXPReward(task.difficulty) : task.xpReward;
    
    final newTask = task.copyWith(
      id: const Uuid().v4(),
      xpReward: xpReward,
    );

    _tasks.add(newTask);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    try {
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      await _taskRepository.deleteTask(taskId);
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

  Future<void> updateTasksList(List<Task> newTasks) async {
    _tasks = newTasks;
    _updateTasksByCategory();
    await _saveTasks();
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedTasks = await _taskRepository.getTasks();
      _tasks = loadedTasks;
      _updateTasksByCategory();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    try {
      await _taskRepository.saveTasks(_tasks);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
} 