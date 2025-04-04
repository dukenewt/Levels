import 'package:flutter/foundation.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;

  TaskProvider() {
    // Initialize with mock tasks
    _tasks = [
      Task(
        id: '1',
        title: 'Complete Project Setup',
        description: 'Set up the initial project structure and dependencies',
        category: 'Work',
        xpReward: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: true,
      ),
      Task(
        id: '2',
        title: 'Design UI Components',
        description: 'Create reusable UI components for the app',
        category: 'Work',
        xpReward: 15,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        isCompleted: false,
      ),
      Task(
        id: '3',
        title: 'Exercise',
        description: '30 minutes of cardio',
        category: 'Health',
        xpReward: 10,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isCompleted: false,
      ),
    ];
  }

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> addTask(Task task) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _tasks = [..._tasks, task];
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        final updatedTask = task.copyWith(isCompleted: true);
        
        _tasks = [
          ..._tasks.sublist(0, taskIndex),
          updatedTask,
          ..._tasks.sublist(taskIndex + 1),
        ];
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
      _tasks = _tasks.where((task) => task.id != taskId).toList();
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