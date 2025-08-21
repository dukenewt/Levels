import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StreakService {
  static const String _streakKey = 'task_streaks';

  static Future<int> getStreak(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final streakData = prefs.getString(_streakKey);
    if (streakData == null) return 0;

    Map<String, dynamic> streaks = {};
    try {
      streaks = json.decode(streakData);
    } catch (_) {
      return 0;
    }

    final taskKey = _getTaskStreakKey(task);
    final existing = streaks[taskKey];
    if (existing == null) return 0;

    final lastCompletion = DateTime.parse(existing['lastCompletion']);
    return _isStreakValid(task, lastCompletion) ? (existing['count'] as int) : 0;
  }

  static Future<void> updateStreak(Task task, DateTime completionTime) async {
    final prefs = await SharedPreferences.getInstance();
    final streakData = prefs.getString(_streakKey);

    Map<String, dynamic> streaks = {};
    if (streakData != null) {
      try {
        streaks = json.decode(streakData);
      } catch (_) {
        streaks = {};
      }
    }

    final taskKey = _getTaskStreakKey(task);
    final existing = streaks[taskKey];

    if (existing == null) {
      streaks[taskKey] = {
        'count': 1,
        'lastCompletion': completionTime.toIso8601String(),
      };
    } else {
      final lastCompletion = DateTime.parse(existing['lastCompletion']);
      final currentCount = existing['count'] as int;
      if (_isStreakValid(task, lastCompletion)) {
        streaks[taskKey] = {
          'count': currentCount + 1,
          'lastCompletion': completionTime.toIso8601String(),
        };
      } else {
        streaks[taskKey] = {
          'count': 1,
          'lastCompletion': completionTime.toIso8601String(),
        };
      }
    }

    await prefs.setString(_streakKey, json.encode(streaks));
  }

  static String _getTaskStreakKey(Task task) {
    if (task.recurrencePattern != null) {
      return '${task.parentTaskId ?? task.id}_${task.recurrencePattern}';
    }
    return '${task.category}_${task.title.toLowerCase().replaceAll(' ', '_')}';
  }

  static bool _isStreakValid(Task task, DateTime lastCompletion) {
    final now = DateTime.now();
    final daysSince = now.difference(lastCompletion).inDays;
    if (task.recurrencePattern != null) {
      switch (task.recurrencePattern) {
        case 'daily':
          return daysSince <= 1;
        case 'weekly':
          return daysSince <= 7;
        case 'workdays':
          return daysSince <= 3; // Allow weekend gap
        default:
          return daysSince <= 1;
      }
    }
    // Non-recurring tasks: tight streak for health/fitness, otherwise lenient
    if (task.category.toLowerCase().contains('health') ||
        task.category.toLowerCase().contains('fitness')) {
      return daysSince <= 1;
    }
    return daysSince <= 2;
  }
}
