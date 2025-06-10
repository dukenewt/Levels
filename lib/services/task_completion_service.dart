import '../models/task.dart';
import '../models/task_results.dart';
import 'intelligent_xp_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Enhanced task completion service that integrates intelligent XP calculation
/// This bridges your existing task completion with the new XP engine
class TaskCompletionService {
  static const String _streakKey = 'task_streaks';
  static const String _perfectWeeksKey = 'perfect_weeks';
  static const String _dailyCompletionsKey = 'daily_completions';

  /// Complete a task with intelligent XP calculation
  static Future<EnhancedTaskCompletion> completeTaskWithIntelligentXP(
    Task task,
    {Map<String, dynamic>? additionalContext}
  ) async {
    final completionTime = DateTime.now();
    
    // Build completion context for XP calculation
    final context = await buildCompletionContext(
      task,
      completionTime,
      additionalContext ?? {},
    );

    // Calculate intelligent XP rewards
    final baseXP = IntelligentXPEngine.calculateBaseXP(task);
    final bonusXP = IntelligentXPEngine.calculateBonusXP(task, context);
    
    // Create XP breakdown for user transparency
    final xpBreakdown = await _createXPBreakdown(task, context, baseXP, bonusXP);
    
    // Update completion tracking for future calculations
    await _updateCompletionTracking(task, completionTime);
    
    // Create enhanced completion result
    return EnhancedTaskCompletion(
      completedTask: task.copyWith(
        isCompleted: true,
        completedAt: completionTime,
        xpReward: baseXP + bonusXP, // Override with intelligent XP
      ),
      baseXP: baseXP,
      bonusXP: bonusXP,
      xpBreakdown: xpBreakdown,
    );
  }

  /// Build context for XP calculation based on completion patterns
  static Future<CompletionContext> buildCompletionContext(
    Task task,
    DateTime completionTime,
    Map<String, dynamic> additionalContext,
  ) async {
    final streak = await _calculateCurrentStreak(task);
    final perfectWeeks = await _calculatePerfectWeeksThisMonth(task);
    
    return CompletionContext(
      completionTime: completionTime,
      currentStreak: streak,
      perfectWeeksThisMonth: perfectWeeks,
      isPartOfChallenge: additionalContext['isPartOfChallenge'] ?? false,
      additionalContext: additionalContext,
    );
  }

  /// Create detailed XP breakdown for user understanding
  static Future<Map<String, int>> _createXPBreakdown(
    Task task,
    CompletionContext context,
    int baseXP,
    int bonusXP,
  ) async {
    final breakdown = <String, int>{'base_xp': baseXP};
    
    // Calculate individual bonus components
    if (context.currentStreak > 1) {
      final streakBonus = IntelligentXPEngine.calculateStreakBonus(task, context.currentStreak);
      if (streakBonus > 0) breakdown['streak_bonus'] = streakBonus;
    }
    
    if (context.perfectWeeksThisMonth > 0) {
      final perfectWeekBonus = IntelligentXPEngine.calculatePerfectWeekBonus(task, context.perfectWeeksThisMonth);
      if (perfectWeekBonus > 0) breakdown['perfect_week_bonus'] = perfectWeekBonus;
    }
    
    if (IntelligentXPEngine.isMorningHabit(task) && 
        IntelligentXPEngine.isCompletedInMorning(context.completionTime)) {
      final morningBonus = (task.xpReward * 0.1).round();
      if (morningBonus > 0) breakdown['morning_bonus'] = morningBonus;
    }
    
    return breakdown;
  }

  /// Calculate current streak for a specific task pattern
  static Future<int> _calculateCurrentStreak(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final streakData = prefs.getString(_streakKey);
    
    if (streakData == null) return 0;
    
    try {
      final Map<String, dynamic> streaks = json.decode(streakData);
      final taskKey = _getTaskStreakKey(task);
      final taskStreak = streaks[taskKey];
      
      if (taskStreak == null) return 0;
      
      final lastCompletion = DateTime.parse(taskStreak['lastCompletion']);
      final streak = taskStreak['count'] as int;
      
      // Check if streak is still valid (completed within expected interval)
      if (_isStreakValid(task, lastCompletion)) {
        return streak;
      }
      
      return 0; // Streak broken
    } catch (e) {
      return 0;
    }
  }

  /// Calculate perfect weeks this month for task category
  static Future<int> _calculatePerfectWeeksThisMonth(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final perfectWeeksData = prefs.getString(_perfectWeeksKey);
    
    if (perfectWeeksData == null) return 0;
    
    try {
      final Map<String, dynamic> perfectWeeks = json.decode(perfectWeeksData);
      final categoryKey = '${task.category}_${DateTime.now().year}_${DateTime.now().month}';
      return perfectWeeks[categoryKey] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Update completion tracking for future XP calculations
  static Future<void> _updateCompletionTracking(Task task, DateTime completionTime) async {
    await Future.wait([
      _updateStreak(task, completionTime),
      _updateDailyCompletions(task, completionTime),
      _updatePerfectWeeks(task, completionTime),
    ]);
  }

  /// Update streak tracking
  static Future<void> _updateStreak(Task task, DateTime completionTime) async {
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
  static Future<void> _updateDailyCompletions(Task task, DateTime completionTime) async {
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
  static Future<void> _updatePerfectWeeks(Task task, DateTime completionTime) async {
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
  static String _getTaskStreakKey(Task task) {
    // For recurring tasks, use the parent task ID or recurrence pattern
    if (task.recurrencePattern != null) {
      return '${task.parentTaskId ?? task.id}_${task.recurrencePattern}';
    }
    
    // For regular tasks, use category + title (similar tasks)
    return '${task.category}_${task.title.toLowerCase().replaceAll(' ', '_')}';
  }

  /// Check if streak is still valid based on task recurrence
  static bool _isStreakValid(Task task, DateTime lastCompletion) {
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
  static Future<bool> _isPerfectWeekCandidate(String category, DateTime completionTime) async {
    // This is a placeholder - implement your own logic for what constitutes a "perfect week"
    // For example, completing all health tasks every day for a week
    return false; // Implement based on your requirements
  }

  /// Get user-friendly streak information
  static Future<Map<String, dynamic>> getStreakInfo(Task task) async {
    final streak = await _calculateCurrentStreak(task);
    final perfectWeeks = await _calculatePerfectWeeksThisMonth(task);
    
    return {
      'currentStreak': streak,
      'perfectWeeksThisMonth': perfectWeeks,
      'streakDescription': _getStreakDescription(streak, task.recurrencePattern),
    };
  }

  /// Generate user-friendly streak description
  static String _getStreakDescription(int streak, String? recurrencePattern) {
    if (streak == 0) return 'Start your streak!';
    if (streak == 1) return 'Great start! 🌟';
    
    final unit = recurrencePattern == 'weekly' ? 'week' : 'day';
    final plural = streak > 1 ? '${unit}s' : unit;
    
    if (streak < 7) return '$streak $plural in a row! 🔥';
    if (streak < 30) return '$streak $plural streak! Amazing! 🚀';
    return '$streak $plural streak! You\'re unstoppable! 💪';
  }
} 