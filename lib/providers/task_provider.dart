import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'user_provider.dart';

class TaskProvider with ChangeNotifier {
  final UserProvider _userProvider;
  List<Task> _tasks = [];
  bool _isLoading = false;

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

  DateTime _calculateNextOccurrence(Task task) {
    if (task.recurrencePattern == null || task.dueDate == null) {
      return task.dueDate!;
    }

    final now = DateTime.now();
    DateTime nextDate;

    switch (task.recurrencePattern) {
      case 'daily':
        // Set to same time tomorrow
        nextDate = DateTime(
          now.year,
          now.month,
          now.day + 1,
          task.dueDate!.hour,
          task.dueDate!.minute,
        );
        break;
      case 'weekly':
        // Calculate days until next occurrence of the same weekday
        int daysUntilNext = (task.dueDate!.weekday - now.weekday + 7) % 7;
        if (daysUntilNext == 0) daysUntilNext = 7; // If same day, move to next week
        nextDate = DateTime(
          now.year,
          now.month,
          now.day + daysUntilNext,
          task.dueDate!.hour,
          task.dueDate!.minute,
        );
        break;
      case 'monthly':
        // Set to same day next month
        if (now.month == 12) {
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
        nextDate = task.dueDate!;
    }

    return nextDate;
  }

  Future<void> completeTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        
        // Only proceed if the task exists and is not already completed
        if (!task.isCompleted) {
          // Remove the task from the list first
          _tasks.removeAt(taskIndex);
          
          // Create next occurrence for recurring tasks
          if (task.recurrencePattern != null) {
            final nextOccurrence = _calculateNextOccurrence(task);
            final newTask = Task(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: task.title,
              description: task.description,
              category: task.category,
              xpReward: task.xpReward,
              dueDate: nextOccurrence,
              recurrencePattern: task.recurrencePattern,
              nextOccurrence: nextOccurrence,
              parentTaskId: task.parentTaskId ?? task.id,
            );
            _tasks.add(newTask);
          }
          
          // Add the completed task back to the list
          _tasks.add(task.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          ));
          
          // Add XP to user when task is completed
          await _userProvider.addXp(task.xpReward);
        }
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
} 