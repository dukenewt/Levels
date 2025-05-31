import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'skill.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty; // 'easy', 'medium', 'hard', 'epic'
  final int xpReward;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final DateTime createdAt;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly', 'workdays', or null for no recurrence
  final DateTime? nextOccurrence;
  final String? parentTaskId; // ID of the original recurring task
  final String? skillId; // Reference to the associated skill
  final TimeOfDay? scheduledTime; // New field for specific time of day
  final List<int>? weeklyDays; // 1-7 for days of week (1 = Monday)
  final int? repeatInterval; // For custom intervals (e.g., every 2 days)
  final DateTime? endDate; // Optional end date for recurring tasks

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.difficulty = 'medium',
    this.xpReward = 50,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
    this.recurrencePattern,
    this.nextOccurrence,
    this.parentTaskId,
    this.skillId,
    this.scheduledTime,
    this.weeklyDays,
    this.repeatInterval,
    this.endDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? xpReward,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    String? recurrencePattern,
    DateTime? nextOccurrence,
    String? parentTaskId,
    String? skillId,
    TimeOfDay? scheduledTime,
    List<int>? weeklyDays,
    int? repeatInterval,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      skillId: skillId ?? this.skillId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'recurrencePattern': recurrencePattern,
      'parentTaskId': parentTaskId,
      'skillId': skillId,
      'scheduledTime': scheduledTime != null ? '${scheduledTime!.hour}:${scheduledTime!.minute}' : null,
      'weeklyDays': weeklyDays,
      'repeatInterval': repeatInterval,
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTimeOfDay(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      xpReward: json['xpReward'] as int? ?? 50,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      recurrencePattern: json['recurrencePattern'] as String?,
      nextOccurrence: json['nextOccurrence'] != null 
          ? DateTime.parse(json['nextOccurrence'] as String)
          : null,
      parentTaskId: json['parentTaskId'] as String?,
      skillId: json['skillId'] as String?,
      scheduledTime: parseTimeOfDay(json['scheduledTime'] as String?),
      weeklyDays: (json['weeklyDays'] as List<dynamic>?)?.cast<int>(),
      repeatInterval: json['repeatInterval'] as int?,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  DateTime calculateNextOccurrence([DateTime? startDate]) {
    if (recurrencePattern == null || dueDate == null) {
      return dueDate!;
    }

    DateTime nextDate = dueDate!;
    final baseDate = startDate ?? DateTime.now();
    
    while (nextDate.isBefore(baseDate)) {
      switch (recurrencePattern) {
        case 'daily':
          nextDate = nextDate.add(Duration(days: repeatInterval ?? 1));
          break;
        case 'weekly':
          if (weeklyDays != null && weeklyDays!.isNotEmpty) {
            // Find next occurrence based on weeklyDays
            int currentDay = nextDate.weekday;
            int nextDay = weeklyDays!.firstWhere(
              (day) => day > currentDay,
              orElse: () => weeklyDays!.first,
            );
            int daysToAdd = nextDay > currentDay 
                ? nextDay - currentDay 
                : 7 - currentDay + nextDay;
            nextDate = nextDate.add(Duration(days: daysToAdd));
          } else {
            nextDate = nextDate.add(const Duration(days: 7));
          }
          break;
        case 'workdays':
          nextDate = nextDate.add(const Duration(days: 1));
          while (nextDate.weekday == DateTime.saturday || nextDate.weekday == DateTime.sunday) {
            nextDate = nextDate.add(const Duration(days: 1));
          }
          break;
        case 'monthly':
          nextDate = DateTime(
            nextDate.year + (nextDate.month == 12 ? 1 : 0),
            nextDate.month == 12 ? 1 : nextDate.month + 1,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
      }

      // Check if we've reached the end date
      if (endDate != null && nextDate.isAfter(endDate!)) {
        return endDate!;
      }
    }
    return nextDate;
  }

  bool isWorkday(DateTime date) {
    return date.weekday != DateTime.saturday && date.weekday != DateTime.sunday;
  }

  // Calculate XP reward based on difficulty
  static int calculateXPReward(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return XPTiers.easy['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.easy['max']! - XPTiers.easy['min']!));
      case 'medium':
        return XPTiers.medium['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.medium['max']! - XPTiers.medium['min']!));
      case 'hard':
        return XPTiers.hard['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.hard['max']! - XPTiers.hard['min']!));
      case 'epic':
        return XPTiers.epic['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.epic['max']! - XPTiers.epic['min']!));
      default:
        return XPTiers.easy['min']!;
    }
  }

  // Mark task as completed
  Task complete() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }
} 