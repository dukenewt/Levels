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
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'recurrencePattern': recurrencePattern,
      'nextOccurrence': nextOccurrence?.toIso8601String(),
      'parentTaskId': parentTaskId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      xpReward: map['xpReward']?.toInt() ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      recurrencePattern: map['recurrencePattern'],
      nextOccurrence: map['nextOccurrence'] != null
          ? DateTime.parse(map['nextOccurrence'])
          : null,
      parentTaskId: map['parentTaskId'],
    );
  }
} 