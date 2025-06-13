import 'task.dart';

/// Represents the result of a task completion operation
/// This gives us explicit, testable outcomes for every operation
class TaskCompletionResult {
  final bool isSuccess;
  final Task? updatedTask;
  final String? errorMessage;
  final TaskCompletionError? errorType;
  final dynamic originalError;
  final int xpGained;
  final bool leveledUp;
  final int? newLevel;
  final int streakBonus;

  TaskCompletionResult({
    required this.isSuccess,
    this.updatedTask,
    this.errorMessage,
    this.errorType,
    this.originalError,
    this.xpGained = 0,
    this.leveledUp = false,
    this.newLevel,
    this.streakBonus = 0,
  });

  /// Creates a successful completion result
  factory TaskCompletionResult.success(Task completedTask) {
    return TaskCompletionResult(
      isSuccess: true,
      updatedTask: completedTask,
    );
  }

  /// Creates a failure result with detailed error information
  factory TaskCompletionResult.failure(
    String errorMessage,
    TaskCompletionError errorType, {
    dynamic originalError,
  }) {
    return TaskCompletionResult(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
      originalError: originalError,
    );
  }

  /// Creates a result for when task was already completed
  factory TaskCompletionResult.alreadyCompleted(Task task) {
    return TaskCompletionResult(
      isSuccess: true,
      updatedTask: task,
      errorMessage: 'Task was already completed',
    );
  }
}

/// Specific error types for task completion
/// This helps us handle different types of failures appropriately
enum TaskCompletionError {
  invalidInput,
  taskNotFound,
  storageFailure,
  networkFailure,
  permissionDenied,
}