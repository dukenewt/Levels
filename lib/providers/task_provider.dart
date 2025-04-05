import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import 'user_provider.dart';
import '../widgets/level_up_overlay.dart';

class TaskProvider with ChangeNotifier {
  final UserProvider _userProvider;
  List<Task> _tasks = [];
  bool _isLoading = false;

  int _totalXP = 0;
  int _currentLevel = 1;
  static const int _xpPerLevel = 100;

  int get totalXP => _totalXP;
  int get currentLevel => (_totalXP ~/ _xpPerLevel) + 1;
  int get xpForNextLevel => currentLevel * _xpPerLevel;
  int get xpInCurrentLevel => _totalXP % _xpPerLevel;

  TaskProvider(this._userProvider) {
    // Initialize with mock tasks
    _tasks = [
      Task(
        id: '1',
        title: 'Complete Project Setup',
        description: 'Set up the initial project structure and dependencies',
        category: 'Work',
        xpReward: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: false,
      ),
      Task(
        id: '2',
        title: 'Design UI Components',
        description: 'Create wireframes and mockups for the main UI components',
        category: 'Design',
        xpReward: 150,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        isCompleted: false,
      ),
      Task(
        id: '3',
        title: 'Exercise',
        description: '30 minutes of cardio and strength training',
        category: 'Health',
        xpReward: 50,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isCompleted: false,
      ),
    ];
  }

  List<Task> get tasks => _tasks;
  
  // Get active (uncompleted) tasks
  List<Task> get activeTasks => _tasks.where((task) => !task.isCompleted).toList();
  
  // Get completed tasks for today
  List<Task> get completedTasksToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks.where((task) => 
      task.isCompleted && 
      task.completedAt != null && 
      DateTime(
        task.completedAt!.year, 
        task.completedAt!.month, 
        task.completedAt!.day
      ).isAtSameMomentAs(today)
    ).toList();
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
  
  bool get isLoading => _isLoading;

  Future<void> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _tasks.add(task);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final taskIndex = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = updatedTask;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _calculateNextOccurrence(Task task) {
    if (task.recurrencePattern == null || task.dueDate == null) {
      return task.dueDate!;
    }

    final now = DateTime.now();
    DateTime nextDate;

    switch (task.recurrencePattern) {
      case 'daily':
        nextDate = task.dueDate!.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDate = task.dueDate!.add(const Duration(days: 7));
        break;
      case 'monthly':
        nextDate = DateTime(
          task.dueDate!.year + (task.dueDate!.month == 12 ? 1 : 0),
          task.dueDate!.month == 12 ? 1 : task.dueDate!.month + 1,
          task.dueDate!.day,
          task.dueDate!.hour,
          task.dueDate!.minute,
        );
        break;
      default:
        nextDate = task.dueDate!;
    }

    while (nextDate.isBefore(now)) {
      switch (task.recurrencePattern) {
        case 'daily':
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDate = DateTime(
            nextDate.year + (nextDate.month == 12 ? 1 : 0),
            nextDate.month == 12 ? 1 : nextDate.month + 1,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
      }
    }

    return nextDate;
  }

  void _checkLevelUp(BuildContext context) {
    final previousLevel = _currentLevel;
    _currentLevel = currentLevel;
    if (_currentLevel > previousLevel) {
      _showLevelUpOverlay(context);
    }
  }

  void _showLevelUpOverlay(BuildContext context) {
    OverlayEntry? overlay;
    overlay = OverlayEntry(
      builder: (context) => LevelUpOverlay(
        newLevel: _currentLevel,
        totalXP: _totalXP,
        onAnimationComplete: () {
          overlay?.remove();
        },
      ),
    );

    Overlay.of(context).insert(overlay);
  }

  Future<void> completeTask(BuildContext context, Task task) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex != -1) {
      _tasks[taskIndex] = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      _totalXP += task.xpReward;
      
      // Check for level up before notifying listeners
      _checkLevelUp(context);
      notifyListeners();
      
      // Handle recurring tasks
      if (task.recurrencePattern != null) {
        _createNextRecurrence(task);
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _tasks.removeWhere((task) => task.id == taskId);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  void _createNextRecurrence(Task task) {
    if (task.recurrencePattern != null && task.dueDate != null) {
      final nextDate = _calculateNextOccurrence(task);
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: task.title,
        description: task.description,
        category: task.category,
        xpReward: task.xpReward,
        dueDate: nextDate,
        recurrencePattern: task.recurrencePattern,
        createdAt: DateTime.now(),
        isCompleted: false,
      );
      _tasks.add(newTask);
      notifyListeners();
    }
  }
} 