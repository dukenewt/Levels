import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/task.dart';
import '../../../models/task_results.dart';
import '../../../core/error_handling.dart';
import '../../../providers/user_provider.dart';
import '../../../services/smooth_xp_animation_service.dart';
import '../../../services/task_notification_service.dart';
import '../../../services/enhanced_xp_calculation_service.dart';
import '../../character_progression/application/intelligent_xp_engine.dart';
import '../../character_progression/domain/completion_context.dart';

/// Enhanced task completion service that integrates intelligent XP calculation
/// This bridges your existing task completion with the new XP engine
class TaskCompletionService {
  final UserProvider _userProvider;
  final IntelligentXPEngine _xpEngine;
  final EnhancedXPCalculationService _enhancedXpService;
  final BuildContext? _context;

  TaskCompletionService({
    required UserProvider userProvider,
    required IntelligentXPEngine xpEngine,
    BuildContext? context,
  })  : _userProvider = userProvider,
        _xpEngine = xpEngine,
        _enhancedXpService = EnhancedXPCalculationService(),
        _context = context;

  static const String _streakKey = 'task_streaks';

  Future<Result<TaskCompletionResult>> completeTask(Task task, {bool isEnhanced = false}) async {
    if (task.isCompleted) {
      return Result.failure(ValidationException('Task already completed'));
    }

    final completionTime = DateTime.now();
    final streak = await _getStreak(task);
    final user = _userProvider.user;

    if (user == null) {
      return Result.failure(ValidationException('User not logged in'));
    }

    final context = CompletionContext(
      completionTime: completionTime,
      currentStreak: streak,
      perfectWeeksThisMonth: 0, // TODO: Implement perfect week tracking
    );

    // Use enhanced XP calculation that includes perk effects
    final enhancedBreakdown = _enhancedXpService.calculateEnhancedXP(user, task, context);
    final totalXp = enhancedBreakdown.finalTotalXP;
    final perkBonusXp = enhancedBreakdown.perkBonusXP;

    final updatedTask = task.complete();

    // Use smooth XP animation service for better visual feedback
    await SmoothXPAnimationService.instance.addXPWithAnimation(
      userProvider: _userProvider,
      xpAmount: totalXp,
    );

    await _updateStreak(task, completionTime);

    // Trigger completion notification if context is available
    if (_context != null) {
      await TaskNotificationService.instance.cancelTaskNotification(task.id);
      
      // Enhanced notification with perk bonus info
      String notificationBody = '${task.title} completed! +$totalXp XP';
      if (perkBonusXp > 0) {
        notificationBody += ' (+$perkBonusXp perk bonus!)';
      }
      
      await TaskNotificationService.instance.showImmediateNotification(
        title: 'Task Completed! 🎉',
        body: notificationBody,
        payload: 'completion_${task.id}',
      );
    }

    return Result.success(
      TaskCompletionResult(
        isSuccess: true,
        updatedTask: updatedTask,
        xpGained: totalXp,
        leveledUp: false, // Level up detection handled by animation service
        newLevel: null,
        streakBonus: enhancedBreakdown.originalBreakdown.totalBonusXP,
        breakdown: enhancedBreakdown.originalBreakdown, // Keep original for compatibility
        enhancedBreakdown: enhancedBreakdown, // Add enhanced breakdown
      ),
    );
  }

  Future<int> _getStreak(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final streakData = prefs.getString(_streakKey);
    if (streakData == null) return 0;

    Map<String, dynamic> streaks = {};
    try {
      streaks = json.decode(streakData);
    } catch (e) {
      return 0;
    }

    final taskKey = _getTaskStreakKey(task);
    final existingStreak = streaks[taskKey];

    if (existingStreak == null) return 0;

    final lastCompletion = DateTime.parse(existingStreak['lastCompletion']);
    if (_isStreakValid(task, lastCompletion)) {
      return existingStreak['count'] as int;
    }

    return 0;
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
} 