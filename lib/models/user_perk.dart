class UserPerk {
  final String id;
  final String name;
  final String description;
  final int requiredLevel;
  final bool isUnlocked;
  final bool isActive;
  final DateTime? unlockedAt;

  const UserPerk({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredLevel,
    this.isUnlocked = false,
    this.isActive = false,
    this.unlockedAt,
  });

  UserPerk copyWith({
    bool? isUnlocked,
    bool? isActive,
    DateTime? unlockedAt,
  }) {
    return UserPerk(
      id: id,
      name: name,
      description: description,
      requiredLevel: requiredLevel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isActive: isActive ?? this.isActive,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

class UserPerks {
  static const smartSuggestions = UserPerk(
    id: 'smart_suggestions',
    name: 'Smart Task Suggestions',
    description: 'Get AI-powered task recommendations based on your patterns',
    requiredLevel: 3,
  );

  static List<UserPerk> get allPerks => [smartSuggestions];
} 