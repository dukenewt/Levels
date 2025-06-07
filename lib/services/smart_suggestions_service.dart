import '../models/task.dart';

class SmartSuggestionsService {
  final List<Task> userTasks;

  SmartSuggestionsService({
    required this.userTasks,
  });

  List<TaskSuggestion> generateSuggestions() {
    final suggestions = <TaskSuggestion>[];
    final patterns = _analyzeUserPatterns(userTasks);
    suggestions.addAll(_generateCategorySuggestions(patterns));
    suggestions.addAll(_generateTimeSuggestions(patterns));
    return suggestions.take(3).toList();
  }

  UserPatterns _analyzeUserPatterns(List<Task> tasks) {
    final categoryFrequency = <String, int>{};
    final timePatterns = <int, int>{};
    for (final task in tasks.where((t) => t.isCompleted)) {
      categoryFrequency[task.category] = (categoryFrequency[task.category] ?? 0) + 1;
      if (task.completedAt != null) {
        final hour = task.completedAt!.hour;
        timePatterns[hour] = (timePatterns[hour] ?? 0) + 1;
      }
    }
    return UserPatterns(
      favoriteCategory: _getMostFrequent(categoryFrequency),
      activeHour: _getMostFrequent(timePatterns),
      totalCompleted: tasks.where((t) => t.isCompleted).length,
    );
  }

  List<TaskSuggestion> _generateCategorySuggestions(UserPatterns patterns) {
    final suggestions = <TaskSuggestion>[];
    if (patterns.favoriteCategory != null) {
      suggestions.add(TaskSuggestion(
        title: 'Do another ${patterns.favoriteCategory} task',
        category: patterns.favoriteCategory!,
        reason: 'Based on your frequent category: ${patterns.favoriteCategory}',
        xpReward: 10,
      ));
    }
    return suggestions;
  }

  List<TaskSuggestion> _generateTimeSuggestions(UserPatterns patterns) {
    final suggestions = <TaskSuggestion>[];
    if (patterns.activeHour != null) {
      suggestions.add(TaskSuggestion(
        title: 'Tackle a task at your peak hour (${patterns.activeHour}:00)',
        category: 'General',
        reason: 'You often complete tasks around this time',
        xpReward: 10,
      ));
    }
    return suggestions;
  }

  T? _getMostFrequent<T>(Map<T, int> map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class UserPatterns {
  final String? favoriteCategory;
  final int? activeHour;
  final int totalCompleted;

  UserPatterns({
    this.favoriteCategory,
    this.activeHour,
    required this.totalCompleted,
  });
}

class TaskSuggestion {
  final String title;
  final String category;
  final String reason;
  final int xpReward;

  const TaskSuggestion({
    required this.title,
    required this.category,
    required this.reason,
    required this.xpReward,
  });
} 