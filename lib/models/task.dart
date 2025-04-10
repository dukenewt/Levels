import 'package:flutter/foundation.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final int xpReward;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final DateTime createdAt;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly', or null for no recurrence
  final DateTime? nextOccurrence;
  final String? parentTaskId; // ID of the original recurring task
  final String? skillId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
    this.recurrencePattern,
    this.nextOccurrence,
    this.parentTaskId,
    this.skillId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? xpReward,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    String? recurrencePattern,
    DateTime? nextOccurrence,
    String? parentTaskId,
    String? skillId,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      skillId: skillId ?? this.skillId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'xpReward': xpReward,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'recurrencePattern': recurrencePattern,
      'parentTaskId': parentTaskId,
      'skillId': skillId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      xpReward: json['xpReward'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      recurrencePattern: json['recurrencePattern'] as String?,
      parentTaskId: json['parentTaskId'] as String?,
      skillId: json['skillId'] as String?,
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
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
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
    }
    return nextDate;
  }
} 