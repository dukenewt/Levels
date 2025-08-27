import 'package:uuid/uuid.dart';

enum EpicStatus {
  planning,
  active,
  completed,
  abandoned;

  String get displayName {
    switch (this) {
      case EpicStatus.planning:
        return 'Planning';
      case EpicStatus.active:
        return 'Active';
      case EpicStatus.completed:
        return 'Completed';
      case EpicStatus.abandoned:
        return 'Abandoned';
    }
  }
}

enum EpicRewardType {
  theme,
  perk,
  xpBonus,
  cosmetic;

  String get displayName {
    switch (this) {
      case EpicRewardType.theme:
        return 'App Theme';
      case EpicRewardType.perk:
        return 'Special Perk';
      case EpicRewardType.xpBonus:
        return 'XP Bonus';
      case EpicRewardType.cosmetic:
        return 'Cosmetic Item';
    }
  }
}

class EpicReward {
  final String id;
  final String name;
  final String description;
  final EpicRewardType type;
  final Map<String, dynamic> data; // Theme colors, perk effects, etc.

  const EpicReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'data': data,
    };
  }

  factory EpicReward.fromJson(Map<String, dynamic> json) {
    return EpicReward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: EpicRewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EpicRewardType.cosmetic,
      ),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class EpicProject {
  final String id;
  final String title;
  final String description;
  final String userId;
  final List<String> taskIds;
  final int requiredTasks;
  final int completedTasks;
  final EpicStatus status;
  final EpicReward reward;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? dueDate;

  EpicProject({
    String? id,
    required this.title,
    required this.description,
    required this.userId,
    required this.taskIds,
    required this.requiredTasks,
    this.completedTasks = 0,
    this.status = EpicStatus.planning,
    required this.reward,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.dueDate,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get progressPercentage {
    if (requiredTasks == 0) return 0.0;
    return (completedTasks / requiredTasks).clamp(0.0, 1.0);
  }

  bool get isCompleted => status == EpicStatus.completed;
  bool get isActive => status == EpicStatus.active;
  bool get canStart => status == EpicStatus.planning && taskIds.isNotEmpty;

  EpicProject copyWith({
    String? title,
    String? description,
    List<String>? taskIds,
    int? requiredTasks,
    int? completedTasks,
    EpicStatus? status,
    EpicReward? reward,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? dueDate,
  }) {
    return EpicProject(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId,
      taskIds: taskIds ?? this.taskIds,
      requiredTasks: requiredTasks ?? this.requiredTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      status: status ?? this.status,
      reward: reward ?? this.reward,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'userId': userId,
      'taskIds': taskIds,
      'requiredTasks': requiredTasks,
      'completedTasks': completedTasks,
      'status': status.name,
      'reward': reward.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory EpicProject.fromJson(Map<String, dynamic> json) {
    return EpicProject(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      userId: json['userId'] as String,
      taskIds: List<String>.from(json['taskIds']),
      requiredTasks: json['requiredTasks'] as int,
      completedTasks: json['completedTasks'] as int? ?? 0,
      status: EpicStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EpicStatus.planning,
      ),
      reward: EpicReward.fromJson(json['reward'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
    );
  }
}

class EpicRewards {
  // Predefined epic rewards
  static const oceanTheme = EpicReward(
    id: 'ocean_theme',
    name: 'Ocean Depths',
    description: 'A calming blue theme inspired by ocean depths',
    type: EpicRewardType.theme,
    data: {
      'primaryColor': '#1565C0',
      'secondaryColor': '#0277BD',
      'accentColor': '#03DAC6',
    },
  );

  static const forestTheme = EpicReward(
    id: 'forest_theme',
    name: 'Forest Canopy',
    description: 'An earthy green theme inspired by forest canopies',
    type: EpicRewardType.theme,
    data: {
      'primaryColor': '#2E7D32',
      'secondaryColor': '#388E3C',
      'accentColor': '#8BC34A',
    },
  );

  static const sunsetTheme = EpicReward(
    id: 'sunset_theme',
    name: 'Sunset Glow',
    description: 'A warm orange theme inspired by golden sunsets',
    type: EpicRewardType.theme,
    data: {
      'primaryColor': '#F57C00',
      'secondaryColor': '#FF8F00',
      'accentColor': '#FFC107',
    },
  );

  static const epicMaster = EpicReward(
    id: 'epic_master_perk',
    name: 'Epic Master',
    description: 'Permanent +50% XP bonus for Epic difficulty tasks',
    type: EpicRewardType.perk,
    data: {
      'effect': 'epic_xp_bonus',
      'value': 0.5,
    },
  );

  static List<EpicReward> get allRewards => [
        oceanTheme,
        forestTheme,
        sunsetTheme,
        epicMaster,
      ];

  static EpicReward getRandomReward() {
    final rewards =
        allRewards.where((r) => r.type == EpicRewardType.theme).toList();
    rewards.shuffle();
    return rewards.first;
  }

  static EpicReward? getRewardById(String id) {
    try {
      return allRewards.firstWhere((reward) => reward.id == id);
    } catch (e) {
      return null;
    }
  }
}
