import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/task.dart';
import '../../../models/task_results.dart';
import '../../../core/error_handling.dart';
import '../../../providers/user_provider.dart';
import '../../../services/smooth_xp_animation_service.dart';
// Notifications are handled by the CompletionPipeline to avoid UI timing races
import '../../../services/enhanced_xp_calculation_service.dart';
import '../../character_progression/application/intelligent_xp_engine.dart';
import '../../character_progression/domain/completion_context.dart';
import '../../../services/streak_service.dart';

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

  Future<Result<TaskCompletionResult>> completeTask(Task task,
      {bool isEnhanced = false}) async {
    if (task.isCompleted) {
      return Result.failure(ValidationException('Task already completed'));
    }

    final completionTime = DateTime.now();
    final streak = await StreakService.getStreak(task);
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
    final enhancedBreakdown =
        _enhancedXpService.calculateEnhancedXP(user, task, context);
    final totalXp = enhancedBreakdown.finalTotalXP;
    final perkBonusXp = enhancedBreakdown.perkBonusXP;

    final updatedTask = task.complete();

    // Use smooth XP animation service for better visual feedback
    await SmoothXPAnimationService.instance.addXPWithAnimation(
      userProvider: _userProvider,
      xpAmount: totalXp,
    );

    // Streak update and notifications deferred to CompletionPipeline

    return Result.success(
      TaskCompletionResult(
        isSuccess: true,
        updatedTask: updatedTask,
        xpGained: totalXp,
        leveledUp: false, // Level up detection handled by animation service
        newLevel: null,
        streakBonus: enhancedBreakdown.originalBreakdown.totalBonusXP,
        breakdown: enhancedBreakdown
            .originalBreakdown, // Keep original for compatibility
        enhancedBreakdown: enhancedBreakdown, // Add enhanced breakdown
      ),
    );
  }
}
