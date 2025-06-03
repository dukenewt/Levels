import 'task.dart';

/// Represents the result of a task completion operation
/// This gives us explicit, testable outcomes for every operation
class TaskCompletionResult {
  final bool isSuccess;
  final Task? completedTask;
  final String? errorMessage;
  final TaskCompletionError? errorType;
  final dynamic originalError;

  TaskCompletionResult._({
    required this.isSuccess,
    this.completedTask,
    this.errorMessage,
    this.errorType,
    this.originalError,
  });

  /// Creates a successful completion result
  factory TaskCompletionResult.success(Task completedTask) {
    return TaskCompletionResult._(
      isSuccess: true,
      completedTask: completedTask,
    );
  }

  /// Creates a failure result with detailed error information
  factory TaskCompletionResult.failure(
    String errorMessage,
    TaskCompletionError errorType, {
    dynamic originalError,
  }) {
    return TaskCompletionResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
      originalError: originalError,
    );
  }

  /// Creates a result for when task was already completed
  factory TaskCompletionResult.alreadyCompleted(Task task) {
    return TaskCompletionResult._(
      isSuccess: true,
      completedTask: task,
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