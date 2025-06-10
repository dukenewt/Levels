import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'secure_user_provider.dart';
import 'package:collection/collection.dart';

import 'settings_provider.dart';
import '../widgets/level_up_overlay.dart';
import 'package:uuid/uuid.dart';
import '../services/secure_storage_service.dart';
import '../core/error_handling.dart';
import '../models/task_results.dart';
import '../services/enhanced_task_completion_service.dart';
import '../widgets/xp_reward_snackbar.dart';

/// States for async operations to provide proper loading indicators
enum TaskOperationState {
  idle,
  loading,
  saving,
  deleting,
  completing,
}

class SecureTaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final Map<String, List<Task>> _tasksByCategory = {};
  final SecureStorageService _storage;
  final SecureUserProvider _userProvider;
  
  // State management
  TaskOperationState _operationState = TaskOperationState.idle;
  AppException? _lastError;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  final _uuid = const Uuid();

  SecureTaskProvider({
    required SecureStorageService storage,
    required SecureUserProvider userProvider,
  }) : _storage = storage,
       _userProvider = userProvider {
    // Only initialize if dependencies are ready
    if (userProvider.isInitialized) {
      _initializeProvider();
    } else {
      _setupDependencyListeners();
    }
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
    if (_userProvider.isInitialized && 
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
  Future<Result<Task>> createTask(Task task) async {
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
  Future<Result<void>> updateTask(Task updatedTask) async {
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
      debugPrint('❌ TaskProvider: Unexpected error updating task: $e');
      final error = AppException('Failed to update task', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
      
    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Completes a task and calculates XP reward dynamically, showing UI feedback.
  Future<TaskCompletionResult> completeTaskWithIntelligentXP(BuildContext context, String taskId) async {
    _operationState = TaskOperationState.completing;
    notifyListeners();

    try {
      // Call the service statically, passing the required providers
      final result = await EnhancedTaskCompletionService.completeTaskWithIntelligentXP(
        taskId: taskId,
        taskProvider: this,
        userProvider: _userProvider,
        additionalContext: {'completionTime': DateTime.now()},
      );

      if (result.isSuccess) {
        // The service now handles all the logic, including saving and updating the user
        // We just need to reflect the successful state.
        final completedTask = result.enhancedCompletion!.completedTask;

        // Manually update the local task list since the service doesn't have direct access
        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex] = completedTask;
          _updateTasksByCategory();
        }
        
        // Show snackbar feedback
        if (context.mounted) {
          XPRewardSnackbar.show(context, result.enhancedCompletion!);
        }

        return TaskCompletionResult.success(completedTask);
      } else {
        // If the static service method fails, return its failure result
        return TaskCompletionResult.failure(
          result.errorMessage ?? 'Failed in enhanced completion',
          result.errorType ?? TaskCompletionError.storageFailure,
          originalError: result.originalError,
        );
      }
    } catch (e, stackTrace) {
      final error = AppException("Failed to complete task with intelligent XP", originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return TaskCompletionResult.failure(
        'An unexpected error occurred during intelligent completion.',
        TaskCompletionError.storageFailure,
        originalError: e,
      );
    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Complete task with XP rewards and comprehensive error handling
  Future<TaskCompletionResult> completeTask(String taskId) async {
    try {
      debugPrint('✅ TaskProvider: Completing task: $taskId');
      
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) {
        return TaskCompletionResult.failure(
          'Task not found',
          TaskCompletionError.taskNotFound,
          originalError: null,
        );
      }

      final task = _tasks[taskIndex];
      if (task.isCompleted) {
        debugPrint('⚠️ TaskProvider: Task already completed');
        return TaskCompletionResult.alreadyCompleted(task);
      }

      _operationState = TaskOperationState.completing;
      notifyListeners();

      // Store task data for XP operations
      final xpReward = task.xpReward;

      try {
        // Update task completion status (optimistic update)
        _tasks[taskIndex] = task.complete();
        _updateTasksByCategory();
        notifyListeners();

        // Save the completed task first
        final saveResult = await _storage.taskRepository.updateTask(_tasks[taskIndex]);
        if (!saveResult.isSuccess) {
          // Rollback the completion if save failed
          _tasks[taskIndex] = task;
          _updateTasksByCategory();
          notifyListeners();
          return TaskCompletionResult.failure(
            saveResult.error?.toString() ?? 'Failed to save task completion. Please try again.',
            TaskCompletionError.storageFailure,
            originalError: saveResult.error,
          );
        }

        // Handle XP rewards in separate try-catch to prevent rollback for XP failures
        try {
          // Add XP to user's overall XP
          await _userProvider.addXp(xpReward);
          
          debugPrint('✅ TaskProvider: Task completed with XP rewards');
          
        } catch (xpError) {
          debugPrint('⚠️ TaskProvider: Task completed but XP addition failed: $xpError');
          // Don't rollback task completion if only XP fails
          _lastError = AppException('Task completed but XP reward failed', originalError: xpError);
          // Still return success, but with a warning message
          return TaskCompletionResult.success(_tasks[taskIndex]);
        }
        return TaskCompletionResult.success(_tasks[taskIndex]);

      } catch (e, stackTrace) {
        debugPrint('❌ TaskProvider: Failed to complete task, reverting: $e');
        // Rollback completion
        _tasks[taskIndex] = task;
        _updateTasksByCategory();
        notifyListeners();
        
        final error = AppException('Failed to complete task', originalError: e);
        ErrorHandlingService().logError(error, stackTrace: stackTrace);
        return TaskCompletionResult.failure(
          'Failed to complete task',
          TaskCompletionError.storageFailure,
          originalError: e,
        );
      }

    } finally {
      _operationState = TaskOperationState.idle;
      notifyListeners();
    }
  }

  /// Delete task with confirmation and undo capability
  Future<Result<Task>> deleteTask(String taskId) async {
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
  Future<Result<void>> undoTaskDeletion(Task task) async {
    debugPrint('↶ TaskProvider: Undoing task deletion: ${task.title}');
    return await createTask(task);
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

  @override
  void dispose() {
    _userProvider.removeListener(_checkDependenciesReady);
    super.dispose();
  }
} 