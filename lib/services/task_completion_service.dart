import '../models/task.dart';
import '../models/task_results.dart';
import '../core/error_handling.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../providers/secure_task_provider.dart';
import '../providers/secure_user_provider.dart';
import 'smooth_xp_animation_service.dart';

/// Enhanced task completion service that integrates intelligent XP calculation
/// This bridges your existing task completion with the new XP engine
class TaskCompletionService {
  final SecureUserProvider _userProvider;
  final SecureTaskProvider _taskProvider;

  TaskCompletionService(this._userProvider, this._taskProvider);

  static const String _streakKey = 'task_streaks';
  static const String _perfectWeeksKey = 'perfect_weeks';
  static const String _dailyCompletionsKey = 'daily_completions';

  Future<Result<TaskCompletionResult>> completeTask(Task task, {bool isEnhanced = false}) async {
    if (task.isCompleted) {
      return Result.failure(ValidationException('Task already completed'));
    }

    final updatedTask = task.complete();
    final xpGained = task.xpReward;

    // Use smooth XP animation service for better visual feedback
    await SmoothXPAnimationService.instance.addXPWithAnimation(
      userProvider: _userProvider,
      xpAmount: xpGained,
    );

    // The smooth animation service already adds the XP, so we don't need to add it again
    // For now, we'll check level-up in the user provider's callback system

    await _updateCompletionTracking(task, DateTime.now());

    return Result.success(
      TaskCompletionResult(
        isSuccess: true,
        updatedTask: updatedTask,
        xpGained: xpGained,
        leveledUp: false, // Level up detection handled by animation service
        newLevel: null,
      ),
    );
  }

  /// Update completion tracking for future XP calculations
  Future<void> _updateCompletionTracking(Task task, DateTime completionTime) async {
    await Future.wait([
      _updateStreak(task, completionTime),
      _updateDailyCompletions(task, completionTime),
      _updatePerfectWeeks(task, completionTime),
    ]);
  }

  /// Update streak tracking
  Future<void> _updateStreak(Task task, DateTime completionTime) async {
    final prefs = await SharedPreferences.getInstance();
    final streakData = prefs.getString(_streakKey);
    
    Map<String, dynamic> streaks = {};
    if (streakData != null) {
      try {
        streaks = json.decode(streakData);
      } catch (e) {
        // Reset if corrupted
        streaks = {};
      }
    }
    
    final taskKey = _getTaskStreakKey(task);
    final existingStreak = streaks[taskKey];
    
    if (existingStreak == null) {
      // First completion
      streaks[taskKey] = {
        'count': 1,
        'lastCompletion': completionTime.toIso8601String(),
      };
    } else {
      final lastCompletion = DateTime.parse(existingStreak['lastCompletion']);
      final currentCount = existingStreak['count'] as int;
      
      if (_isStreakValid(task, lastCompletion)) {
        // Continue streak
        streaks[taskKey] = {
          'count': currentCount + 1,
          'lastCompletion': completionTime.toIso8601String(),
        };
      } else {
        // Reset streak
        streaks[taskKey] = {
          'count': 1,
          'lastCompletion': completionTime.toIso8601String(),
        };
      }
    }
    
    await prefs.setString(_streakKey, json.encode(streaks));
  }

  /// Update daily completion tracking
  Future<void> _updateDailyCompletions(Task task, DateTime completionTime) async {
    final prefs = await SharedPreferences.getInstance();
    final dailyData = prefs.getString(_dailyCompletionsKey);
    
    Map<String, dynamic> dailyCompletions = {};
    if (dailyData != null) {
      try {
        dailyCompletions = json.decode(dailyData);
      } catch (e) {
        dailyCompletions = {};
      }
    }
    
    final dateKey = '${completionTime.year}-${completionTime.month}-${completionTime.day}';
    final categoryKey = task.category;
    
    if (dailyCompletions[dateKey] == null) {
      dailyCompletions[dateKey] = {};
    }
    
    dailyCompletions[dateKey][categoryKey] = (dailyCompletions[dateKey][categoryKey] ?? 0) + 1;
    
    await prefs.setString(_dailyCompletionsKey, json.encode(dailyCompletions));
  }

  /// Update perfect weeks tracking
  Future<void> _updatePerfectWeeks(Task task, DateTime completionTime) async {
    // This is a simplified version - you might want to implement more sophisticated
    // perfect week detection based on your specific requirements
    final prefs = await SharedPreferences.getInstance();
    final perfectWeeksData = prefs.getString(_perfectWeeksKey);
    
    Map<String, dynamic> perfectWeeks = {};
    if (perfectWeeksData != null) {
      try {
        perfectWeeks = json.decode(perfectWeeksData);
      } catch (e) {
        perfectWeeks = {};
      }
    }
    
    // For now, just increment monthly perfect weeks when certain conditions are met
    final categoryKey = '${task.category}_${completionTime.year}_${completionTime.month}';
    
    // You can add logic here to detect actual perfect weeks
    // For now, we'll use a simple heuristic
    if (await _isPerfectWeekCandidate(task.category, completionTime)) {
      perfectWeeks[categoryKey] = (perfectWeeks[categoryKey] ?? 0) + 1;
      await prefs.setString(_perfectWeeksKey, json.encode(perfectWeeks));
    }
  }

  /// Generate task streak key based on task type
  String _getTaskStreakKey(Task task) {
    // For recurring tasks, use the parent task ID or recurrence pattern
    if (task.recurrencePattern != null) {
      return '${task.parentTaskId ?? task.id}_${task.recurrencePattern}';
    }
    
    // For regular tasks, use category + title (similar tasks)
    return '${task.category}_${task.title.toLowerCase().replaceAll(' ', '_')}';
  }

  /// Check if streak is still valid based on task recurrence
  bool _isStreakValid(Task task, DateTime lastCompletion) {
    final now = DateTime.now();
    final daysSinceLastCompletion = now.difference(lastCompletion).inDays;
    
    // For recurring tasks, check based on recurrence pattern
    if (task.recurrencePattern != null) {
      switch (task.recurrencePattern) {
        case 'daily':
          return daysSinceLastCompletion <= 1;
        case 'weekly':
          return daysSinceLastCompletion <= 7;
        case 'workdays':
          // More complex logic for workdays - simplified here
          return daysSinceLastCompletion <= 3; // Allow weekend gap
        default:
          return daysSinceLastCompletion <= 1;
      }
    }
    
    // For non-recurring tasks, assume daily habits if they're health/fitness
    if (task.category.toLowerCase().contains('health') || 
        task.category.toLowerCase().contains('fitness')) {
      return daysSinceLastCompletion <= 1;
    }
    
    // Default: allow up to 2 days gap
    return daysSinceLastCompletion <= 2;
  }

  /// Simple heuristic for perfect week detection
  Future<bool> _isPerfectWeekCandidate(String category, DateTime completionTime) async {
    // This is a placeholder - implement your own logic for what constitutes a "perfect week"
    // For example, completing all health tasks every day for a week
    return false; // Implement based on your requirements
  }

  /// Generate user-friendly streak description
  String _getStreakDescription(int streak, String? recurrencePattern) {
    if (streak == 0) return 'Start your streak!';
    if (streak == 1) return 'Great start! 🌟';
    if (streak < 7) return '$streak-day streak 🔥';
    if (streak < 30) return 'Over a week! Keep it up!';
    return 'Over a month! You\'re a legend! 🏆';
  }
} 