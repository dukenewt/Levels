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

  Future<void> completeTask(String taskId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        if (!task.isCompleted) {
          _tasks[taskIndex] = task.copyWith(isCompleted: true);
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