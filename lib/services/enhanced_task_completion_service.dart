import '../models/task.dart';
import '../models/task_results.dart';
import '../providers/secure_task_provider.dart';
import '../providers/secure_user_provider.dart';
import 'intelligent_xp_engine.dart';
import 'task_completion_service.dart';

/// Enhanced task completion service that integrates intelligent XP with your existing workflow
/// Use this service to gradually migrate from static XP to intelligent XP calculation
class EnhancedTaskCompletionService {
  
  /// Complete a task with intelligent XP calculation
  /// This method integrates with your existing SecureTaskProvider workflow
  static Future<EnhancedTaskCompletionResult> completeTaskWithIntelligentXP({
    required String taskId,
    required SecureTaskProvider taskProvider,
    required SecureUserProvider userProvider,
    Map<String, dynamic>? additionalContext,
  }) async {
    // Get the task before completion
    final task = taskProvider.tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );

    // Calculate intelligent XP before completing the task
    final enhancedCompletion = await TaskCompletionService.completeTaskWithIntelligentXP(
      task,
      additionalContext: additionalContext,
    );

    // Update the task with the new XP value
    final taskWithIntelligentXP = enhancedCompletion.completedTask;

    // Complete the task using your existing provider logic
    // But override the XP with our intelligent calculation
    final originalResult = await taskProvider.completeTask(taskId);
    
    if (!originalResult.isSuccess) {
      return EnhancedTaskCompletionResult.failure(
        originalResult.errorMessage ?? 'Failed to complete task',
        originalResult.errorType ?? TaskCompletionError.storageFailure,
        originalError: originalResult.originalError,
      );
    }

    // Calculate XP difference to adjust user's total XP
    final originalXP = task.xpReward;
    final intelligentXP = enhancedCompletion.totalXP;
    final xpDifference = intelligentXP - originalXP;

    // Adjust user XP if there's a difference
    if (xpDifference != 0) {
      try {
        await userProvider.addXp(xpDifference);
      } catch (e) {
        // Log error but don't fail the entire operation
        print('Warning: Failed to adjust XP difference: $e');
      }
    }

    return EnhancedTaskCompletionResult.success(enhancedCompletion);
  }

  /// Get preview of XP rewards without completing the task
  /// Useful for showing users what they'll earn before completion
  static Future<XPPreview> getXPPreview(Task task) async {
    // Build a temporary completion context
    final completionTime = DateTime.now();
    final context = await TaskCompletionService.buildCompletionContext(
      task,
      completionTime,
      {},
    );

    final baseXP = IntelligentXPEngine.calculateBaseXP(task);
    final bonusXP = IntelligentXPEngine.calculateBonusXP(task, context);
    final streakInfo = await TaskCompletionService.getStreakInfo(task);

    return XPPreview(
      baseXP: baseXP,
      bonusXP: bonusXP,
      totalXP: baseXP + bonusXP,
      streakInfo: streakInfo,
      willReceiveMorningBonus: IntelligentXPEngine.isMorningHabit(task) && 
                              IntelligentXPEngine.isCompletedInMorning(completionTime),
    );
  }

  /// Calculate what XP would be for a task with different parameters
  /// Useful for task creation/editing to show estimated rewards
  static int calculateEstimatedXP({
    required int timeCostMinutes,
    required String category,
    required String difficulty,
  }) {
    // Create a temporary task for calculation
    final tempTask = Task(
      id: 'temp',
      title: 'Estimated Task',
      description: '',
      category: category,
      difficulty: difficulty,
      timeCostMinutes: timeCostMinutes,
    );

    return IntelligentXPEngine.calculateBaseXP(tempTask);
  }
}

/// Enhanced task completion result that includes intelligent XP information
class EnhancedTaskCompletionResult {
  final bool isSuccess;
  final EnhancedTaskCompletion? enhancedCompletion;
  final String? errorMessage;
  final TaskCompletionError? errorType;
  final dynamic originalError;

  EnhancedTaskCompletionResult._({
    required this.isSuccess,
    this.enhancedCompletion,
    this.errorMessage,
    this.errorType,
    this.originalError,
  });

  factory EnhancedTaskCompletionResult.success(EnhancedTaskCompletion completion) {
    return EnhancedTaskCompletionResult._(
      isSuccess: true,
      enhancedCompletion: completion,
    );
  }

  factory EnhancedTaskCompletionResult.failure(
    String errorMessage,
    TaskCompletionError errorType, {
    dynamic originalError,
  }) {
    return EnhancedTaskCompletionResult._(
      isSuccess: false,
      errorMessage: errorMessage,
      errorType: errorType,
      originalError: originalError,
    );
  }
}

/// Preview of XP rewards for a task
class XPPreview {
  final int baseXP;
  final int bonusXP;
  final int totalXP;
  final Map<String, dynamic> streakInfo;
  final bool willReceiveMorningBonus;

  XPPreview({
    required this.baseXP,
    required this.bonusXP,
    required this.totalXP,
    required this.streakInfo,
    required this.willReceiveMorningBonus,
  });

  /// Get a user-friendly description of the XP breakdown
  String getDescription() {
    final parts = <String>[];
    
    parts.add('$baseXP base XP');
    
    if (bonusXP > 0) {
      parts.add('$bonusXP bonus XP');
    }
    
    final streak = streakInfo['currentStreak'] as int;
    if (streak > 0) {
      final description = streakInfo['streakDescription'] as String;
      parts.add('Current streak: $description');
    }
    
    if (willReceiveMorningBonus) {
      parts.add('Morning bonus available! ☀️');
    }
    
    return parts.join(' • ');
  }
} 