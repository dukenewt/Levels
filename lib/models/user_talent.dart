enum TalentType {
  projectManagement,
  nlpCategorization;

  String get id {
    switch (this) {
      case TalentType.projectManagement:
        return 'project_management';
      case TalentType.nlpCategorization:
        return 'nlp_categorization';
    }
  }

  String get displayName {
    switch (this) {
      case TalentType.projectManagement:
        return 'Project Management';
      case TalentType.nlpCategorization:
        return 'Smart Categorization';
    }
  }

  String get description {
    switch (this) {
      case TalentType.projectManagement:
        return 'Unlock Epic difficulty tasks and create project-based task groups with unique rewards';
      case TalentType.nlpCategorization:
        return 'Automatically categorize your tasks using intelligent keyword analysis';
    }
  }
}

class UserTalent {
  final String id;
  final String name;
  final String description;
  final TalentType type;
  final int requiredLevel;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const UserTalent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.requiredLevel,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  UserTalent copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return UserTalent(
      id: id,
      name: name,
      description: description,
      type: type,
      requiredLevel: requiredLevel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.id,
      'requiredLevel': requiredLevel,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory UserTalent.fromJson(Map<String, dynamic> json) {
    return UserTalent(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: TalentType.values.firstWhere(
        (e) => e.id == json['type'],
        orElse: () => TalentType.projectManagement,
      ),
      requiredLevel: json['requiredLevel'] as int,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

class TalentChoice {
  final int level;
  final List<UserTalent> options;
  final UserTalent? selectedTalent;
  final bool isChoiceMade;

  const TalentChoice({
    required this.level,
    required this.options,
    this.selectedTalent,
    this.isChoiceMade = false,
  });

  TalentChoice copyWith({
    UserTalent? selectedTalent,
    bool? isChoiceMade,
  }) {
    return TalentChoice(
      level: level,
      options: options,
      selectedTalent: selectedTalent ?? this.selectedTalent,
      isChoiceMade: isChoiceMade ?? this.isChoiceMade,
    );
  }
}

class UserTalents {
  // Define all available talent choices
  static const _level5ProjectMgmt = UserTalent(
    id: 'project_mgmt_5',
    name: 'Epic Quest Master',
    description: 'Unlock Epic difficulty tasks and create multi-task projects',
    type: TalentType.projectManagement,
    requiredLevel: 5,
  );

  static const _level5NLP = UserTalent(
    id: 'nlp_categorization_5',
    name: 'Smart Assistant',
    description: 'Automatically categorize tasks using keyword analysis',
    type: TalentType.nlpCategorization,
    requiredLevel: 5,
  );

  static const _level10ProjectMgmt = UserTalent(
    id: 'project_mgmt_10',
    name: 'Epic Architect',
    description: 'Advanced project templates and milestone tracking',
    type: TalentType.projectManagement,
    requiredLevel: 10,
  );

  static const _level10NLP = UserTalent(
    id: 'nlp_advanced_10',
    name: 'Context Master',
    description: 'Enhanced categorization with context awareness',
    type: TalentType.nlpCategorization,
    requiredLevel: 10,
  );

  // Define talent choices for each level
  static TalentChoice getTalentChoice(int level) {
    switch (level) {
      case 5:
        return TalentChoice(
          level: 5,
          options: [_level5ProjectMgmt, _level5NLP],
        );
      case 10:
        return TalentChoice(
          level: 10,
          options: [_level10ProjectMgmt, _level10NLP],
        );
      case 15:
        // Future talent choices
        return TalentChoice(level: 15, options: []);
      case 20:
        return TalentChoice(level: 20, options: []);
      case 25:
        return TalentChoice(level: 25, options: []);
      default:
        return TalentChoice(level: level, options: []);
    }
  }

  static List<int> get talentLevels => [5, 10, 15, 20, 25];

  static bool isTalentLevel(int level) => talentLevels.contains(level);
}