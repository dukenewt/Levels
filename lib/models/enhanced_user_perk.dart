enum PerkEffect {
  xpBonus,
  lootBoxBonus,
  streakFreeze,
  categoryBonus,
  conditionalBonus;

  String get id {
    switch (this) {
      case PerkEffect.xpBonus:
        return 'xp_bonus';
      case PerkEffect.lootBoxBonus:
        return 'loot_box_bonus';
      case PerkEffect.streakFreeze:
        return 'streak_freeze';
      case PerkEffect.categoryBonus:
        return 'category_bonus';
      case PerkEffect.conditionalBonus:
        return 'conditional_bonus';
    }
  }

  String get displayName {
    switch (this) {
      case PerkEffect.xpBonus:
        return 'XP Boost';
      case PerkEffect.lootBoxBonus:
        return 'Lucky Loot';
      case PerkEffect.streakFreeze:
        return 'Streak Shield';
      case PerkEffect.categoryBonus:
        return 'Category Expert';
      case PerkEffect.conditionalBonus:
        return 'Conditional Boost';
    }
  }
}

class PerkEffectData {
  final PerkEffect effect;
  final double value; // Percentage bonus (e.g., 0.1 for 10%)
  final String? category; // For category-specific bonuses
  final Map<String, dynamic>? metadata; // Additional effect data

  const PerkEffectData({
    required this.effect,
    required this.value,
    this.category,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'effect': effect.id,
      'value': value,
      'category': category,
      'metadata': metadata,
    };
  }

  factory PerkEffectData.fromJson(Map<String, dynamic> json) {
    return PerkEffectData(
      effect: PerkEffect.values.firstWhere(
        (e) => e.id == json['effect'],
        orElse: () => PerkEffect.xpBonus,
      ),
      value: (json['value'] as num).toDouble(),
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class EnhancedUserPerk {
  final String id;
  final String name;
  final String description;
  final int requiredLevel;
  final bool isUnlocked;
  final bool isActive;
  final DateTime? unlockedAt;
  final List<PerkEffectData> effects;

  const EnhancedUserPerk({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredLevel,
    this.isUnlocked = false,
    this.isActive = false,
    this.unlockedAt,
    this.effects = const [],
  });

  EnhancedUserPerk copyWith({
    bool? isUnlocked,
    bool? isActive,
    DateTime? unlockedAt,
  }) {
    return EnhancedUserPerk(
      id: id,
      name: name,
      description: description,
      requiredLevel: requiredLevel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isActive: isActive ?? this.isActive,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      effects: effects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requiredLevel': requiredLevel,
      'isUnlocked': isUnlocked,
      'isActive': isActive,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'effects': effects.map((e) => e.toJson()).toList(),
    };
  }

  factory EnhancedUserPerk.fromJson(Map<String, dynamic> json) {
    return EnhancedUserPerk(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      requiredLevel: json['requiredLevel'] as int,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      effects: (json['effects'] as List<dynamic>?)
              ?.map((e) => PerkEffectData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get unlocked perks for a given level
  static List<EnhancedUserPerk> getUnlockedPerks(int level) {
    return EnhancedUserPerks.getAvailablePerksForLevel(level);
  }
}

class EnhancedUserPerks {
  // Level 1: First perk - recurring task motivation
  static const routineMaster = EnhancedUserPerk(
    id: 'routine_master',
    name: 'Routine Master',
    description: '+20% XP for easy recurring tasks',
    requiredLevel: 1,
    effects: [
      PerkEffectData(
        effect: PerkEffect.conditionalBonus,
        value: 0.20,
        metadata: {
          'conditions': ['difficulty:easy', 'recurring:true']
        },
      ),
    ],
  );

  // Level 3: Early game momentum perk
  static const taskStarter = EnhancedUserPerk(
    id: 'task_starter',
    name: 'Task Starter',
    description: '+10% XP for all tasks (early game boost)',
    requiredLevel: 3,
    effects: [
      PerkEffectData(
        effect: PerkEffect.xpBonus,
        value: 0.10,
      ),
    ],
  );

  // Level 5: First major perk choice
  static const healthExpert = EnhancedUserPerk(
    id: 'health_expert',
    name: 'Health Expert',
    description: '+15% XP for Health category tasks',
    requiredLevel: 5,
    effects: [
      PerkEffectData(
        effect: PerkEffect.categoryBonus,
        value: 0.15,
        category: 'Health',
      ),
    ],
  );

  // Level 7: Morning motivation
  static const morningMotivation = EnhancedUserPerk(
    id: 'morning_motivation',
    name: 'Morning Motivation',
    description: '+15% XP for tasks completed before noon',
    requiredLevel: 7,
    effects: [
      PerkEffectData(
        effect: PerkEffect.conditionalBonus,
        value: 0.15,
        metadata: {
          'conditions': ['is_morning:true']
        },
      ),
    ],
  );

  // Level 8: Loot box bonus
  static const luckyCharm = EnhancedUserPerk(
    id: 'lucky_charm',
    name: 'Lucky Charm',
    description: '+25% chance for loot box bonuses',
    requiredLevel: 8,
    effects: [
      PerkEffectData(
        effect: PerkEffect.lootBoxBonus,
        value: 0.25,
      ),
    ],
  );

  // Level 9: Difficulty dabbler
  static const difficultyDabbler = EnhancedUserPerk(
    id: 'difficulty_dabbler',
    name: 'Difficulty Dabbler',
    description: '+15% XP for medium difficulty tasks',
    requiredLevel: 9,
    effects: [
      PerkEffectData(
        effect: PerkEffect.conditionalBonus,
        value: 0.15,
        metadata: {
          'conditions': ['difficulty:medium']
        },
      ),
    ],
  );

  // Level 11: Category explorer
  static const categoryExplorer = EnhancedUserPerk(
    id: 'category_explorer',
    name: 'Category Explorer',
    description:
        '+10% XP when completing tasks from 3+ different categories in a day',
    requiredLevel: 11,
    effects: [
      PerkEffectData(
        effect: PerkEffect.conditionalBonus,
        value: 0.10,
        metadata: {
          'conditions': ['daily_categories_count:>=3']
        },
      ),
    ],
  );

  // Level 12: Streak protection
  static const streakGuardian = EnhancedUserPerk(
    id: 'streak_guardian',
    name: 'Streak Guardian',
    description: 'One free streak freeze when task becomes overdue',
    requiredLevel: 12,
    effects: [
      PerkEffectData(
        effect: PerkEffect.streakFreeze,
        value: 1.0, // One use
      ),
    ],
  );

  // Level 13: Consistency champion (replacing old Task Starter)
  static const consistencyChampion = EnhancedUserPerk(
    id: 'consistency_champion',
    name: 'Consistency Champion',
    description: '+10% XP for all tasks (building momentum)',
    requiredLevel: 13,
    effects: [
      PerkEffectData(
        effect: PerkEffect.xpBonus,
        value: 0.10,
      ),
    ],
  );

  // Level 15: Learning bonus
  static const learningMaster = EnhancedUserPerk(
    id: 'learning_master',
    name: 'Learning Master',
    description: '+20% XP for Learning category tasks',
    requiredLevel: 15,
    effects: [
      PerkEffectData(
        effect: PerkEffect.categoryBonus,
        value: 0.20,
        category: 'Learning',
      ),
    ],
  );

  // Level 18: General XP boost
  static const xpVeteran = EnhancedUserPerk(
    id: 'xp_veteran',
    name: 'XP Veteran',
    description: '+10% XP for all completed tasks',
    requiredLevel: 18,
    effects: [
      PerkEffectData(
        effect: PerkEffect.xpBonus,
        value: 0.10,
      ),
    ],
  );

  // Level 22: Work efficiency
  static const workEfficiency = EnhancedUserPerk(
    id: 'work_efficiency',
    name: 'Work Efficiency',
    description: '+25% XP for Work category tasks',
    requiredLevel: 22,
    effects: [
      PerkEffectData(
        effect: PerkEffect.categoryBonus,
        value: 0.25,
        category: 'Work',
      ),
    ],
  );

  // Level 25: Master perk
  static const grandMaster = EnhancedUserPerk(
    id: 'grand_master',
    name: 'Grand Master',
    description: '+15% XP for all tasks and +50% loot box chance',
    requiredLevel: 25,
    effects: [
      PerkEffectData(
        effect: PerkEffect.xpBonus,
        value: 0.15,
      ),
      PerkEffectData(
        effect: PerkEffect.lootBoxBonus,
        value: 0.50,
      ),
    ],
  );

  static List<EnhancedUserPerk> get allPerks => [
        routineMaster,
        taskStarter,
        healthExpert,
        morningMotivation,
        luckyCharm,
        difficultyDabbler,
        categoryExplorer,
        streakGuardian,
        consistencyChampion,
        learningMaster,
        xpVeteran,
        workEfficiency,
        grandMaster,
      ];

  static List<EnhancedUserPerk> getAvailablePerksForLevel(int level) {
    return allPerks.where((perk) => perk.requiredLevel <= level).toList();
  }

  static EnhancedUserPerk? getPerkById(String id) {
    try {
      return allPerks.firstWhere((perk) => perk.id == id);
    } catch (e) {
      return null;
    }
  }
}
