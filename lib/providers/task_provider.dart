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
import '../models/task_results.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final Map<String, List<Task>> _tasksByCategory = {};
  final TaskRepository _taskRepository;
  final UserProvider _userProvider;
  final SkillProvider _skillProvider;
  bool _isLoading = false;
  final _uuid = const Uuid();
  bool _isInitialized = false;

  TaskProvider({
    required StorageService storage,
    required UserProvider userProvider,
    required SkillProvider skillProvider,
  }) : _taskRepository = storage.taskRepository,
       _userProvider = userProvider,
       _skillProvider = skillProvider {
    // Only load tasks if dependencies are ready
    if (userProvider.isInitialized && skillProvider.isInitialized) {
      _loadTasks();
    } else {
      // Listen for when dependencies become ready
      _setupDependencyListeners();
    }
  }

  void _setupDependencyListeners() {
    // Listen for when UserProvider becomes ready
    _userProvider.addListener(_checkDependenciesReady);
    _skillProvider.addListener(_checkDependenciesReady);
  }

  void _checkDependenciesReady() {
    if (_userProvider.isInitialized && 
        _skillProvider.isInitialized && 
        !_isLoading && 
        _tasks.isEmpty) {
      // Dependencies are now ready, load tasks
      _userProvider.removeListener(_checkDependenciesReady);
      _skillProvider.removeListener(_checkDependenciesReady);
      _loadTasks();
    }
  }

  @override
  void dispose() {
    _userProvider.removeListener(_checkDependenciesReady);
    _skillProvider.removeListener(_checkDependenciesReady);
    super.dispose();
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
  bool get isInitialized => _isInitialized;

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
    /// Completes a task with comprehensive error handling and state management
/// Returns a detailed result that tells us exactly what happened
Future<TaskCompletionResult> completeTask(String taskId) async {
  // Phase 1: Input validation and precondition checking
  if (taskId.isEmpty) {
    debugPrint('TaskProvider.completeTask: Invalid taskId provided');
    return TaskCompletionResult.failure(
      'Invalid task ID provided',
      TaskCompletionError.invalidInput,
    );
  }

  final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
  if (taskIndex == -1) {
    debugPrint('TaskProvider.completeTask: Task not found: $taskId');
    return TaskCompletionResult.failure(
      'Task not found',
      TaskCompletionError.taskNotFound,
    );
  }

  final task = _tasks[taskIndex];
  if (task.isCompleted) {
    debugPrint('TaskProvider.completeTask: Task already completed: $taskId');
    return TaskCompletionResult.alreadyCompleted(task);
  }

  // Phase 2: Prepare for operation and track changes
  final originalTask = task;
  final completedTask = task.complete();
  final operationStartTime = DateTime.now();
  
  debugPrint('TaskProvider.completeTask: Starting completion for task: ${task.title}');

  // Phase 3: Apply optimistic update with change tracking
  _tasks[taskIndex] = completedTask;
  notifyListeners(); // Give immediate feedback to user
  
  // Phase 4: Attempt to persist changes with comprehensive error handling
  try {
    await _saveTasks();
    debugPrint('TaskProvider.completeTask: Task completion persisted successfully');
    
    // Phase 5: Handle related operations (XP, achievements) with isolated error handling
    await _handleTaskCompletionEffects(task, completedTask);
    
    return TaskCompletionResult.success(completedTask);
    
  } catch (storageError) {
    debugPrint('TaskProvider.completeTask: Storage error occurred: $storageError');
    
    // Phase 6: Revert optimistic update on storage failure
    _tasks[taskIndex] = originalTask;
    notifyListeners();
    
    return TaskCompletionResult.failure(
      'Failed to save task completion. Please try again.',
      TaskCompletionError.storageFailure,
      originalError: storageError,
    );
  }
}

/// Handles XP and other effects of task completion with isolated error handling
Future<void> _handleTaskCompletionEffects(Task originalTask, Task completedTask) async {
  try {
    // Add XP to user - if this fails, we still want the task to remain completed
    await _userProvider.addXp(originalTask.xpReward);
    debugPrint('TaskProvider: Added ${originalTask.xpReward} XP to user');
  } catch (xpError) {
    debugPrint('TaskProvider: Failed to add user XP: $xpError');
    // We don't revert the task completion for XP failures
    // The task is completed, but we'll note the XP failure for later retry
  }

  try {
    // Add XP to skill if associated
    if (originalTask.skillId != null) {
      await _skillProvider.addXP(originalTask.skillId!, originalTask.xpReward);
      debugPrint('TaskProvider: Added ${originalTask.xpReward} XP to skill: ${originalTask.skillId}');
    }
  } catch (skillError) {
    debugPrint('TaskProvider: Failed to add skill XP: $skillError');
    // Again, we don't revert task completion for skill XP failures
  }
}
  Future<void> createTask(Task task) async {
    // If recurring, generate all instances for the next 30 days
    if (task.recurrencePattern != null) {
      final instances = Task.generateRecurringInstances(template: task, daysAhead: 30);
      print('Generated recurring instances:');
      for (var t in instances) {
        print('Instance dueDate: \'${t.dueDate}\'');
      }
      _tasks.addAll(instances);
    } else {
      final xpReward = task.xpReward == 50 ? Task.calculateXPReward(task.difficulty) : task.xpReward;
      final newTask = task.copyWith(
        id: const Uuid().v4(),
        xpReward: xpReward,
      );
      _tasks.add(newTask);
    }
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
      _isInitialized = true;
      notifyListeners();
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

  // Ensure recurring tasks have instances for the next 30 days
  Future<void> maintainRecurringTaskWindow() async {
    final now = DateTime.now();
    final windowEnd = now.add(const Duration(days: 30));
    final recurringTemplates = _tasks.where((t) => t.recurrencePattern != null && t.parentTaskId == null).toList();
    for (final template in recurringTemplates) {
      // Find the latest dueDate for this template
      final children = _tasks.where((t) => t.parentTaskId == template.id).toList();
      DateTime? latestDueDate = children.isNotEmpty
        ? children.map((t) => t.dueDate ?? now).reduce((a, b) => a.isAfter(b) ? a : b)
        : template.dueDate;
      if (latestDueDate == null) continue;
      // If latestDueDate is before windowEnd, generate more instances
      while (latestDueDate != null && latestDueDate.isBefore(windowEnd)) {
        final nextInstances = Task.generateRecurringInstances(
          template: template.copyWith(dueDate: latestDueDate),
          daysAhead: 1,
        );
        // Only add if not already present
        for (final inst in nextInstances) {
          if (!_tasks.any((t) => t.dueDate == inst.dueDate && t.parentTaskId == template.id)) {
            _tasks.add(inst);
          }
        }
        latestDueDate = nextInstances.last.dueDate ?? latestDueDate!.add(const Duration(days: 1));
      }
    }
    await _saveTasks();
    notifyListeners();
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // }
} 