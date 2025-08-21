import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_notification_service.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'user_provider.dart';
import 'package:collection/collection.dart';

import 'settings_provider.dart';
import '../widgets/level_up_overlay.dart';
import 'package:uuid/uuid.dart';
import '../services/secure_storage_service.dart';
import '../core/error_handling.dart';
import '../models/task_results.dart';
import '../features/task_management/application/task_completion_service.dart';
import '../features/character_progression/application/intelligent_xp_engine.dart';
import '../widgets/xp_reward_snackbar.dart';
import '../widgets/recurring_task_edit_dialog.dart';
import '../widgets/xp_breakdown_dialog.dart';
import 'epic_provider.dart';
import 'theme_provider.dart';
import '../models/theme_model.dart';
import '../features/task_management/application/completion_pipeline.dart';

/// States for async operations to provide proper loading indicators
enum TaskOperationState {
  idle,
  loading,
  saving,
  deleting,
  completing,
}

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final Map<String, List<Task>> _tasksByCategory = {};
  final SecureStorageService _storage;
  final UserProvider _userProvider;
  final IntelligentXPEngine _xpEngine;
  
  // State management
  TaskOperationState _operationState = TaskOperationState.idle;
  AppException? _lastError;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  final _uuid = const Uuid();

  TaskProvider({
    required SecureStorageService storage,
    required UserProvider userProvider,
  }) : _storage = storage,
       _userProvider = userProvider,
       _xpEngine = IntelligentXPEngine() { // Instantiate the engine
    // Only initialize if dependencies are ready
    if (userProvider.user != null) {
      _initializeProvider();
    } else {
      _setupDependencyListeners();
    }
  }

  void updateUserProvider(UserProvider userProvider) {
    _userProvider.removeListener(_checkDependenciesReady);
    _setupDependencyListeners();
    _initializeProvider();
  }

  // Getters with safety checks
  List<Task> get tasks => List.unmodifiable(_tasks);
  Map<String, List<Task>> get tasksByCategory => Map.unmodifiable(_tasksByCategory);
  TaskOperationState get operationState => _operationState;
  AppException? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _operationState == TaskOperationState.loading;
  
  /// Initialize the provider with comprehensive error handling
  Future<void> _initializeProvider() async {
    if (_isInitializing || _isInitialized) return;
    
    _isInitializing = true;
    _operationState = TaskOperationState.loading;
    notifyListeners();
    
    try {
      debugPrint('🎯 TaskProvider: Starting initialization...');
      
      final result = await _loadTasks();
      if (result.isSuccess) {
        _isInitialized = true;
        debugPrint('✅ TaskProvider: Initialization completed successfully');
      } else {
        debugPrint('⚠️ TaskProvider: Initialization completed with warnings');
        _lastError = result.error;
        // Still mark as initialized to keep app functional
        _isInitialized = true;
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ TaskProvider: Initialization failed: $e');
      _lastError = AppException('Failed to initialize task provider', originalError: e);
      ErrorHandlingService().logError(_lastError!, stackTrace: stackTrace);
      
      // Initialize with empty data to keep app functional
      _tasks = [];
      _updateTasksByCategory();
      _isInitialized = true;
      
    } finally {
      _isInitializing = false;
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  void _setupDependencyListeners() {
    debugPrint('📡 TaskProvider: Setting up dependency listeners');
    _userProvider.addListener(_checkDependenciesReady);
  }

  void _checkDependenciesReady() {
    if (_userProvider.user != null && 
        !_isInitialized && 
        !_isInitializing) {
      debugPrint('🎉 TaskProvider: Dependencies ready, starting initialization');
      _userProvider.removeListener(_checkDependenciesReady);
      _initializeProvider();
    }
  }

  /// Load tasks with comprehensive error handling and fallbacks
  Future<Result<void>> _loadTasks() async {
    try {
      debugPrint('📖 TaskProvider: Loading tasks from storage...');
      
      final tasksResult = await _storage.taskRepository.getTasks();
      if (tasksResult.isSuccess) {
        _tasks = tasksResult.data!;
        _updateTasksByCategory();
        
        debugPrint('✅ TaskProvider: Loaded ${_tasks.length} tasks successfully');
        return Result.success(null);
        
      } else {
        debugPrint('⚠️ TaskProvider: Failed to load tasks, using empty list');
        _tasks = [];
        _updateTasksByCategory();
        
        return Result.failure(tasksResult.error!);
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ TaskProvider: Unexpected error loading tasks: $e');
      final error = AppException('Unexpected error loading tasks', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      
      // Ensure we have a valid state even if loading fails
      _tasks = [];
      _updateTasksByCategory();
      
      return Result.failure(error);
    }
  }

  /// Create task with full validation and error handling
  Future<Result<Task>> createTask(BuildContext context, Task task) async {
    try {
      debugPrint('📝 TaskProvider: Creating new task: ${task.title}');
      
      // Validate task data
      final validationResult = _validateTask(task);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }
      
      _operationState = TaskOperationState.saving;
      notifyListeners();
      
      // Handle recurring tasks
      List<Task> tasksToAdd = [];
      if (task.recurrencePattern != null) {
        debugPrint('🔄 TaskProvider: Generating recurring task instances');
        tasksToAdd = Task.generateRecurringInstances(template: task, daysAhead: 30);
      } else {
        // Create single task with proper XP calculation
        final xpReward = task.xpReward == 50 ? Task.calculateXPReward(task.difficulty) : task.xpReward;
        final newTask = task.copyWith(
          id: _uuid.v4(),
          xpReward: xpReward,
        );
        tasksToAdd = [newTask];
      }
      
      // Add to local state first (optimistic update)
      final originalTasks = List<Task>.from(_tasks);
      _tasks.addAll(tasksToAdd);
      _updateTasksByCategory();
      notifyListeners();
      
      // Save to storage
      final saveResult = await _storage.taskRepository.saveTasks(_tasks);
      if (saveResult.isSuccess) {
        debugPrint('✅ TaskProvider: Task created successfully');
        _lastError = null;
        for (final newTask in tasksToAdd) {
          TaskNotificationService.instance.scheduleTaskReminder(context, newTask);
        }
        return Result.success(tasksToAdd.first);
      } else {
        debugPrint('❌ TaskProvider: Failed to save task, reverting changes');
        // Revert optimistic update
        _tasks = originalTasks;
        _updateTasksByCategory();
        notifyListeners();
        
        return Result.failure(saveResult.error!);
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ TaskProvider: Unexpected error creating task: $e');
      final error = AppException('Failed to create task', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
      
    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Update task with optimistic updates and rollback capability
  Future<Result<void>> updateTask(BuildContext context, Task updatedTask) async {
    try {
      debugPrint('🔄 TaskProvider: Updating task: ${updatedTask.title}');
      
      // Validate updated task
      final validationResult = _validateTask(updatedTask);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }
      
      // Find the task to update
      final taskIndex = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (taskIndex == -1) {
        return Result.failure(ValidationException('Task not found'));
      }
      
      _operationState = TaskOperationState.saving;
      notifyListeners();
      
      // Store original task for potential rollback
      final originalTask = _tasks[taskIndex];
      
      // Apply optimistic update
      _tasks[taskIndex] = updatedTask;
      _updateTasksByCategory();
      notifyListeners();
      
      // Save to storage
      final saveResult = await _storage.taskRepository.updateTask(updatedTask);
      if (saveResult.isSuccess) {
        debugPrint('✅ TaskProvider: Task updated successfully');
        _lastError = null;
        await TaskNotificationService.instance.cancelTaskNotification(updatedTask.id);
        await TaskNotificationService.instance.scheduleTaskReminder(context, updatedTask);
        return Result.success(null);
      } else {
        debugPrint('❌ TaskProvider: Failed to save updated task, reverting');
        // Rollback optimistic update
        _tasks[taskIndex] = originalTask;
        _updateTasksByCategory();
        notifyListeners();
        
        return Result.failure(saveResult.error!);
      }
      
    } catch (e, stackTrace) {
      final appError = AppException(
        'Failed to update task',
        code: 'TASK_UPDATE_ERROR',
        originalError: e,
      );
      ErrorHandlingService().logError(appError, stackTrace: stackTrace);
      return Result.failure(appError);
      
    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Update recurring task based on the edit scope
  Future<Result<void>> updateRecurringTask(
    BuildContext context, 
    Task updatedTask, 
    EditScope editScope
  ) async {
    try {
      debugPrint('🔄 TaskProvider: Updating recurring task: ${updatedTask.title}, scope: $editScope');
      
      // Validate updated task
      final validationResult = _validateTask(updatedTask);
      if (!validationResult.isSuccess) {
        return Result.failure(validationResult.error!);
      }
      
      _operationState = TaskOperationState.saving;
      notifyListeners();

      switch (editScope) {
        case EditScope.thisTaskOnly:
          // Edit only this specific occurrence
          await _updateSingleOccurrence(context, updatedTask);
          break;
          
        case EditScope.allFutureTasks:
          // Edit this and all future occurrences
          await _updateFutureOccurrences(context, updatedTask);
          break;
      }

      _updateTasksByCategory();
      notifyListeners();
      
      debugPrint('✅ TaskProvider: Recurring task updated successfully');
      _lastError = null;
      return Result.success(null);
      
    } catch (e, stackTrace) {
      final appError = AppException(
        'Failed to update recurring task',
        code: 'RECURRING_TASK_UPDATE_ERROR',
        originalError: e,
      );
      ErrorHandlingService().logError(appError, stackTrace: stackTrace);
      return Result.failure(appError);
      
    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Update only the specific occurrence of a recurring task
  Future<void> _updateSingleOccurrence(BuildContext context, Task updatedTask) async {
    // If this task is part of a recurring series, break it away from the series
    final modifiedTask = updatedTask.copyWith(
      parentTaskId: null, // Break connection to recurring series
      recurrencePattern: null, // Make it a one-time task
      weeklyDays: null,
      repeatInterval: null,
      endDate: null,
    );

    // Find and update the specific task
    final taskIndex = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (taskIndex != -1) {
      _tasks[taskIndex] = modifiedTask;
      
      // Save to storage
      await _storage.taskRepository.updateTask(modifiedTask);
      
      // Update notifications
      await TaskNotificationService.instance.cancelTaskNotification(modifiedTask.id);
      await TaskNotificationService.instance.scheduleTaskReminder(context, modifiedTask);
    }
  }

  /// Update this and all future occurrences of a recurring task
  Future<void> _updateFutureOccurrences(BuildContext context, Task updatedTask) async {
    final now = DateTime.now();
    
    // Find the original recurring task (parent) or use this task if it's the parent
    String parentId = updatedTask.parentTaskId ?? updatedTask.id;
    
    // Update all future tasks in the series (including this one)
    final tasksToUpdate = _tasks.where((task) {
      return (task.id == parentId || task.parentTaskId == parentId) &&
             !task.isCompleted &&
             (task.dueDate == null || !task.dueDate!.isBefore(now));
    }).toList();

    for (final task in tasksToUpdate) {
      final modifiedTask = task.copyWith(
        title: updatedTask.title,
        description: updatedTask.description,
        category: updatedTask.category,
        difficulty: updatedTask.difficulty,
        xpReward: updatedTask.xpReward,
        scheduledTime: updatedTask.scheduledTime,
        recurrencePattern: updatedTask.recurrencePattern,
        weeklyDays: updatedTask.weeklyDays,
        repeatInterval: updatedTask.repeatInterval,
        endDate: updatedTask.endDate,
        timeCostMinutes: updatedTask.timeCostMinutes,
      );

      // Update in memory
      final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = modifiedTask;
        
        // Save to storage
        await _storage.taskRepository.updateTask(modifiedTask);
        
        // Update notifications
        await TaskNotificationService.instance.cancelTaskNotification(modifiedTask.id);
        await TaskNotificationService.instance.scheduleTaskReminder(context, modifiedTask);
      }
    }
  }

  Future<Result<TaskCompletionResult>> completeTask(
      BuildContext context, Task task,
      {bool isEnhanced = false}) async {
    _operationState = TaskOperationState.completing;
    notifyListeners();

    try {
      final completionService = TaskCompletionService(
        userProvider: _userProvider,
        xpEngine: _xpEngine,
        context: context,
      );

      final result = await completionService.completeTask(task, isEnhanced: isEnhanced);

      if (result.isSuccess) {
        final completionData = result.data!;
        final updatedTask = completionData.updatedTask!;

        await TaskNotificationService.instance.cancelTaskNotification(updatedTask.id);

        // Optimistically update the task in the UI
        final taskIndex = _tasks.indexWhere((t) => t.id == updatedTask.id);
        if (taskIndex != -1) {
          _tasks[taskIndex] = updatedTask;
          _updateTasksByCategory();
          notifyListeners();
        }

        // Save the updated task to persistent storage
        final saveResult = await _storage.taskRepository.updateTask(updatedTask);
        if (!saveResult.isSuccess) {
          ErrorHandlingService().logError(saveResult.error!);
          return Result.failure(saveResult.error!);
        }

        // Epic progress and celebration handled inside CompletionPipeline

        // Notify UI via orchestrated sequence to avoid conflicts
        if (context.mounted) {
          await CompletionPipeline.playUiSequence(
            context: context,
            task: task,
            completion: completionData,
          );
        }
        return Result.success(completionData);
      } else {
        _lastError = result.error;
        ErrorHandlingService().logError(result.error!);
        return result;
      }
    } catch (e, stackTrace) {
      final error = AppException('Failed to complete task', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Delete task with optimistic updates and rollback
  Future<Result<void>> deleteTask(String taskId) async {
    try {
      debugPrint('🗑️ TaskProvider: Deleting task: $taskId');
      
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) {
        return Result.failure(ValidationException('Task not found'));
      }

      _operationState = TaskOperationState.deleting;
      notifyListeners();

      // Store the task for potential undo
      final deletedTask = _tasks[taskIndex];
      
      // Remove from local state (optimistic update)
      _tasks.removeAt(taskIndex);
      _updateTasksByCategory();
      notifyListeners();

      // Save to storage
      final deleteResult = await _storage.taskRepository.deleteTask(taskId);
      if (deleteResult.isSuccess) {
        debugPrint('✅ TaskProvider: Task deleted successfully');
        _lastError = null;
        await TaskNotificationService.instance.cancelTaskNotification(taskId);
        return Result.success(deletedTask);
      } else {
        debugPrint('❌ TaskProvider: Failed to delete task, restoring');
        // Restore the task
        _tasks.insert(taskIndex, deletedTask);
        _updateTasksByCategory();
        notifyListeners();
        
        return Result.failure(deleteResult.error!);
      }

    } catch (e, stackTrace) {
      debugPrint('❌ TaskProvider: Unexpected error deleting task: $e');
      final error = AppException('Failed to delete task', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
      
    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Undo task deletion (restore from recent deletion)
  Future<Result<void>> undoTaskDeletion(BuildContext context, Task task) async {
    debugPrint('↶ TaskProvider: Undoing task deletion: ${task.title}');
    return await createTask(context, task);
  }

  /// Validate task data before operations
  Result<void> _validateTask(Task task) {
    if (task.id.isEmpty) {
      return Result.failure(ValidationException('Task must have an ID'));
    }
    
    if (task.title.trim().isEmpty) {
      return Result.failure(ValidationException('Task must have a title'));
    }
    
    if (task.xpReward < 0) {
      return Result.failure(ValidationException('XP reward cannot be negative'));
    }
    
    if (task.timeCostMinutes < 1) {
      return Result.failure(ValidationException('Time cost must be at least 1 minute'));
    }
    
    return Result.success(null);
  }

  /// Update the tasks by category mapping
  void _updateTasksByCategory() {
    _tasksByCategory.clear();
    for (var task in _tasks) {
      _tasksByCategory.putIfAbsent(task.category, () => []).add(task);
    }
  }

  // Public methods for getting filtered tasks (these are safe and don't need error handling)
  List<Task> get activeTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  /// Get task by ID
  Task? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }
  
  List<Task> getFilteredActiveTasks(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _tasks.where((task) {
      if (task.isCompleted) return false;
      
      if (task.recurrencePattern != null) {
        if (task.dueDate == null) return true;
        
        final dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        
        return !dueDate.isBefore(today);
      }
      
      if (task.dueDate != null) {
        final dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        return !dueDate.isBefore(today);
      }
      
      return true;
    }).toList();
  }

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
    
    completedToday.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return completedToday;
  }

  /// Clear last error (for UI error dismissal)
  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  /// Show error to user with context
  void showErrorToUser(BuildContext context, AppException error) {
    ErrorHandlingService().showError(context, error);
  }

  /// Handle epic theme reward unlocking
  Future<void> _handleEpicThemeReward(BuildContext context, epic) async {
    if (epic.reward.type.name != 'theme') return;
    
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ThemeType? themeToUnlock;
      
      // Map epic reward IDs to theme types
      switch (epic.reward.id) {
        case 'ocean_theme':
          themeToUnlock = ThemeType.oceanDepths;
          break;
        case 'forest_theme':
          themeToUnlock = ThemeType.forestCanopy;
          break;
        case 'sunset_theme':
          themeToUnlock = ThemeType.sunsetGlow;
          break;
      }
      
      if (themeToUnlock != null) {
        await themeProvider.unlockPremiumTheme(themeToUnlock);
        debugPrint('🎨 Unlocked epic theme: ${themeToUnlock.name}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to unlock epic theme: $e');
    }
  }

  /// Show epic completion celebration dialog
  void _showEpicCompletionCelebration(BuildContext context, epic) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Epic Completed!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have completed "${epic.title}"!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Reward Unlocked:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    epic.reward.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    epic.reward.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userProvider.removeListener(_checkDependenciesReady);
    super.dispose();
  }
}
