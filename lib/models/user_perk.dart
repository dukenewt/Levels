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
  // Smart Suggestions perk removed - no longer supported

  static List<UserPerk> get allPerks => [];
}
