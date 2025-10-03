import 'package:flutter/material.dart';
import '../models/task.dart';

enum PrioritizationStrategy {
  easyFirst,
  hardFirst,
  dueDateFirst,
  categoryGrouped,
  timeEfficient;

  String get displayName {
    switch (this) {
      case PrioritizationStrategy.easyFirst:
        return 'Easy Wins First';
      case PrioritizationStrategy.hardFirst:
        return 'Tackle Hard Tasks';
      case PrioritizationStrategy.dueDateFirst:
        return 'Urgent First';
      case PrioritizationStrategy.categoryGrouped:
        return 'Group by Category';
      case PrioritizationStrategy.timeEfficient:
        return 'Quick Tasks First';
    }
  }

  String get description {
    switch (this) {
      case PrioritizationStrategy.easyFirst:
        return 'Build momentum by completing easier tasks first';
      case PrioritizationStrategy.hardFirst:
        return 'Tackle challenging tasks when you\'re fresh';
      case PrioritizationStrategy.dueDateFirst:
        return 'Focus on tasks with approaching deadlines';
      case PrioritizationStrategy.categoryGrouped:
        return 'Work through tasks grouped by category';
      case PrioritizationStrategy.timeEfficient:
        return 'Complete quick tasks to clear your list';
    }
  }
}

class TaskPrioritizationService {
  /// Sort tasks based on the selected strategy
  static List<Task> prioritizeTasks(
    List<Task> tasks,
    PrioritizationStrategy strategy,
  ) {
    final sortedTasks = List<Task>.from(tasks);

    switch (strategy) {
      case PrioritizationStrategy.easyFirst:
        return _sortByEasyFirst(sortedTasks);
      case PrioritizationStrategy.hardFirst:
        return _sortByHardFirst(sortedTasks);
      case PrioritizationStrategy.dueDateFirst:
        return _sortByDueDate(sortedTasks);
      case PrioritizationStrategy.categoryGrouped:
        return _sortByCategory(sortedTasks);
      case PrioritizationStrategy.timeEfficient:
        return _sortByTimeEfficient(sortedTasks);
    }
  }

  /// Get tasks with due dates/times for prominence display
  static List<Task> getUrgentTasks(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      if (task.dueDate == null) return false;

      // Consider tasks due within 24 hours as urgent
      final dueDateTime = _getTaskDueDateTime(task);
      final hoursUntilDue = dueDateTime.difference(now).inHours;
      return hoursUntilDue >= 0 && hoursUntilDue <= 24;
    }).toList()
      ..sort((a, b) {
        final aTime = _getTaskDueDateTime(a);
        final bTime = _getTaskDueDateTime(b);
        return aTime.compareTo(bTime);
      });
  }

  /// Get tasks that are overdue
  static List<Task> getOverdueTasks(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDateTime = _getTaskDueDateTime(task);
      return dueDateTime.isBefore(now);
    }).toList();
  }

  /// Get color for task based on difficulty (for prominence display)
  static Color getDifficultyColor(
      TaskDifficulty difficulty, ColorScheme colorScheme) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.epic:
        return Colors.purple;
    }
  }

  /// Get urgency level for a task (0-3, higher = more urgent)
  static int getUrgencyLevel(Task task) {
    if (task.dueDate == null) return 0;

    final now = DateTime.now();
    final dueDateTime = _getTaskDueDateTime(task);
    final hoursUntilDue = dueDateTime.difference(now).inHours;

    if (hoursUntilDue < 0) return 3; // Overdue
    if (hoursUntilDue <= 2) return 3; // Due within 2 hours
    if (hoursUntilDue <= 12) return 2; // Due within 12 hours
    if (hoursUntilDue <= 24) return 1; // Due within 24 hours
    return 0; // Not urgent
  }

  // Private sorting methods
  static List<Task> _sortByEasyFirst(List<Task> tasks) {
    tasks.sort((a, b) {
      // First priority: due date urgency
      final aUrgency = getUrgencyLevel(a);
      final bUrgency = getUrgencyLevel(b);
      if (aUrgency != bUrgency) return bUrgency.compareTo(aUrgency);

      // Second priority: difficulty (easy first)
      final aDiff = a.difficulty.index;
      final bDiff = b.difficulty.index;
      if (aDiff != bDiff) return aDiff.compareTo(bDiff);

      // Third priority: time cost (quick tasks first)
      return a.timeCostMinutes.compareTo(b.timeCostMinutes);
    });
    return tasks;
  }

  static List<Task> _sortByHardFirst(List<Task> tasks) {
    tasks.sort((a, b) {
      // First priority: due date urgency
      final aUrgency = getUrgencyLevel(a);
      final bUrgency = getUrgencyLevel(b);
      if (aUrgency != bUrgency) return bUrgency.compareTo(aUrgency);

      // Second priority: difficulty (hard first)
      final aDiff = a.difficulty.index;
      final bDiff = b.difficulty.index;
      if (aDiff != bDiff) return bDiff.compareTo(aDiff);

      // Third priority: created date (older first)
      return a.createdAt.compareTo(b.createdAt);
    });
    return tasks;
  }

  static List<Task> _sortByDueDate(List<Task> tasks) {
    tasks.sort((a, b) {
      // Tasks with due dates come first
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate == null) return -1;
      if (a.dueDate == null && b.dueDate == null) {
        // For tasks without due dates, sort by difficulty
        return a.difficulty.index.compareTo(b.difficulty.index);
      }

      // Compare due dates
      final aTime = _getTaskDueDateTime(a);
      final bTime = _getTaskDueDateTime(b);
      return aTime.compareTo(bTime);
    });
    return tasks;
  }

  static List<Task> _sortByCategory(List<Task> tasks) {
    tasks.sort((a, b) {
      // First priority: category
      final categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;

      // Within category: urgency
      final aUrgency = getUrgencyLevel(a);
      final bUrgency = getUrgencyLevel(b);
      if (aUrgency != bUrgency) return bUrgency.compareTo(aUrgency);

      // Within category and urgency: difficulty (easy first)
      return a.difficulty.index.compareTo(b.difficulty.index);
    });
    return tasks;
  }

  static List<Task> _sortByTimeEfficient(List<Task> tasks) {
    tasks.sort((a, b) {
      // First priority: due date urgency
      final aUrgency = getUrgencyLevel(a);
      final bUrgency = getUrgencyLevel(b);
      if (aUrgency != bUrgency) return bUrgency.compareTo(aUrgency);

      // Second priority: time cost (quick tasks first)
      return a.timeCostMinutes.compareTo(b.timeCostMinutes);
    });
    return tasks;
  }

  static DateTime _getTaskDueDateTime(Task task) {
    if (task.dueDate == null) return DateTime.now();

    if (task.scheduledTime != null) {
      return DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.scheduledTime!.hour,
        task.scheduledTime!.minute,
      );
    }

    // If no scheduled time, assume end of day
    return DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      23,
      59,
    );
  }

  /// Get a completion goal suggestion based on current tasks
  static String getCompletionGoalSuggestion(List<Task> tasks) {
    if (tasks.isEmpty) return 'No pending tasks. Great job!';

    final easyTasks =
        tasks.where((t) => t.difficulty == TaskDifficulty.easy).length;
    final urgentTasks = getUrgentTasks(tasks).length;
    final overdueTasks = getOverdueTasks(tasks).length;

    if (overdueTasks > 0) {
      return 'Focus: Complete $overdueTasks overdue ${overdueTasks == 1 ? 'task' : 'tasks'}';
    }

    if (urgentTasks > 0) {
      return 'Today\'s Goal: Complete $urgentTasks urgent ${urgentTasks == 1 ? 'task' : 'tasks'}';
    }

    if (easyTasks >= 3) {
      return 'Quick Wins: Complete 3 easy tasks to build momentum';
    }

    final totalTasks = tasks.length;
    final goalCount = (totalTasks * 0.3).ceil().clamp(1, 5);
    return 'Daily Goal: Complete $goalCount ${goalCount == 1 ? 'task' : 'tasks'} today';
  }
}
