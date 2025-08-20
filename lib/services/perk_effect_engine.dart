import '../models/enhanced_user_perk.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../features/character_progression/domain/completion_context.dart';

/// Result of applying perk effects to XP calculation
class PerkEffectResult {
  final double categoryBonusMultiplier;
  final double xpBonusMultiplier;
  final double lootBoxChanceBonus;
  final bool hasStreakFreeze;
  final List<String> appliedPerkNames;
  final Map<String, String> effectDescriptions;

  const PerkEffectResult({
    this.categoryBonusMultiplier = 0.0,
    this.xpBonusMultiplier = 0.0,
    this.lootBoxChanceBonus = 0.0,
    this.hasStreakFreeze = false,
    this.appliedPerkNames = const [],
    this.effectDescriptions = const {},
  });

  PerkEffectResult copyWith({
    double? categoryBonusMultiplier,
    double? xpBonusMultiplier,
    double? lootBoxChanceBonus,
    bool? hasStreakFreeze,
    List<String>? appliedPerkNames,
    Map<String, String>? effectDescriptions,
  }) {
    return PerkEffectResult(
      categoryBonusMultiplier: categoryBonusMultiplier ?? this.categoryBonusMultiplier,
      xpBonusMultiplier: xpBonusMultiplier ?? this.xpBonusMultiplier,
      lootBoxChanceBonus: lootBoxChanceBonus ?? this.lootBoxChanceBonus,
      hasStreakFreeze: hasStreakFreeze ?? this.hasStreakFreeze,
      appliedPerkNames: appliedPerkNames ?? this.appliedPerkNames,
      effectDescriptions: effectDescriptions ?? this.effectDescriptions,
    );
  }

  bool get hasAnyEffects => 
      categoryBonusMultiplier > 0 || 
      xpBonusMultiplier > 0 || 
      lootBoxChanceBonus > 0 || 
      hasStreakFreeze;
}

/// Engine that applies perk effects to game mechanics
class PerkEffectEngine {
  /// Apply all relevant perk effects for a task completion
  static PerkEffectResult applyPerksToTask(
    User user,
    Task task,
    CompletionContext context,
  ) {
    double categoryBonus = 0.0;
    double xpBonus = 0.0;
    double lootBoxBonus = 0.0;
    bool hasStreakFreeze = false;
    List<String> appliedPerks = [];
    Map<String, String> descriptions = {};

    // Get all unlocked perks for the user
    final unlockedPerks = _getUnlockedPerks(user);

    for (final perk in unlockedPerks) {
      for (final effect in perk.effects) {
        switch (effect.effect) {
          case PerkEffect.categoryBonus:
            if (effect.category != null && 
                effect.category!.toLowerCase() == task.category.toLowerCase()) {
              categoryBonus += effect.value;
              appliedPerks.add(perk.name);
              descriptions[perk.id] = '+${(effect.value * 100).toInt()}% ${effect.category} XP';
            }
            break;

          case PerkEffect.xpBonus:
            xpBonus += effect.value;
            appliedPerks.add(perk.name);
            descriptions[perk.id] = '+${(effect.value * 100).toInt()}% All XP';
            break;

          case PerkEffect.lootBoxBonus:
            lootBoxBonus += effect.value;
            appliedPerks.add(perk.name);
            descriptions[perk.id] = '+${(effect.value * 100).toInt()}% Loot Box Chance';
            break;

          case PerkEffect.streakFreeze:
            if (effect.value > 0) {
              hasStreakFreeze = true;
              appliedPerks.add(perk.name);
              descriptions[perk.id] = 'Streak Protection Available';
            }
            break;
        }
      }
    }

    return PerkEffectResult(
      categoryBonusMultiplier: categoryBonus,
      xpBonusMultiplier: xpBonus,
      lootBoxChanceBonus: lootBoxBonus,
      hasStreakFreeze: hasStreakFreeze,
      appliedPerkNames: appliedPerks.toSet().toList(), // Remove duplicates
      effectDescriptions: descriptions,
    );
  }

  /// Calculate final XP with perk bonuses applied
  static int applyPerkBonusesToXP(
    int baseXP,
    PerkEffectResult perkEffects,
    {bool isCategoryBonus = false}
  ) {
    double finalXP = baseXP.toDouble();

    // Apply category-specific bonus if applicable
    if (isCategoryBonus && perkEffects.categoryBonusMultiplier > 0) {
      finalXP += (baseXP * perkEffects.categoryBonusMultiplier);
    }

    // Apply general XP bonus
    if (perkEffects.xpBonusMultiplier > 0) {
      finalXP += (baseXP * perkEffects.xpBonusMultiplier);
    }

    return finalXP.round();
  }

  /// Calculate enhanced loot box chance with perk bonuses
  static double calculateLootBoxChance(
    double baseChance,
    PerkEffectResult perkEffects,
  ) {
    double enhancedChance = baseChance;
    
    if (perkEffects.lootBoxChanceBonus > 0) {
      enhancedChance += perkEffects.lootBoxChanceBonus;
    }

    // Cap at 95% chance
    return enhancedChance.clamp(0.0, 0.95);
  }

  /// Check if user should get streak protection from overdue task
  static bool shouldApplyStreakFreeze(
    User user,
    Task overdueTask,
  ) {
    final perkEffects = applyPerksToTask(
      user, 
      overdueTask, 
      CompletionContext.defaultContext(),
    );
    
    return perkEffects.hasStreakFreeze;
  }

  /// Get preview of perk effects for UI display
  static List<String> getPerkEffectPreview(User user, String taskCategory) {
    final dummyTask = Task(
      id: 'preview',
      title: 'Preview Task',
      description: '',
      category: taskCategory,
      difficulty: TaskDifficulty.medium,
      xpReward: 50,
      timeCostMinutes: 30,
    );

    final effects = applyPerksToTask(
      user,
      dummyTask,
      CompletionContext.defaultContext(),
    );

    List<String> preview = [];
    
    if (effects.categoryBonusMultiplier > 0) {
      preview.add('+${(effects.categoryBonusMultiplier * 100).toInt()}% ${taskCategory} XP');
    }
    
    if (effects.xpBonusMultiplier > 0) {
      preview.add('+${(effects.xpBonusMultiplier * 100).toInt()}% Base XP');
    }
    
    if (effects.lootBoxChanceBonus > 0) {
      preview.add('+${(effects.lootBoxChanceBonus * 100).toInt()}% Loot Box Chance');
    }
    
    if (effects.hasStreakFreeze) {
      preview.add('Streak Protection Active');
    }

    return preview;
  }

  /// Get all perks that affect a specific category
  static List<EnhancedUserPerk> getPerksForCategory(User user, String category) {
    final unlockedPerks = _getUnlockedPerks(user);
    
    return unlockedPerks.where((perk) {
      return perk.effects.any((effect) => 
        effect.effect == PerkEffect.categoryBonus && 
        effect.category?.toLowerCase() == category.toLowerCase()
      );
    }).toList();
  }

  /// Get all active perks for a user
  static List<EnhancedUserPerk> getActivePerks(User user) {
    return _getUnlockedPerks(user);
  }

  /// Helper method to get unlocked perks for a user
  static List<EnhancedUserPerk> _getUnlockedPerks(User user) {
    final availablePerks = EnhancedUserPerks.getAvailablePerksForLevel(user.level);
    
    return availablePerks.where((perk) {
      // Check if perk is unlocked (either automatically or explicitly)
      return user.perks.contains(perk.id) || perk.requiredLevel <= user.level;
    }).toList();
  }

  /// Check if user has any perks that affect epic difficulty
  static bool hasEpicPerks(User user) {
    final unlockedPerks = _getUnlockedPerks(user);
    
    return unlockedPerks.any((perk) => 
      perk.effects.any((effect) => 
        effect.metadata?['difficulty'] == 'epic'
      )
    );
  }

  /// Get summary of all active perk effects
  static Map<String, dynamic> getPerkSummary(User user) {
    final unlockedPerks = _getUnlockedPerks(user);
    
    Map<String, List<String>> effectsByCategory = {};
    List<String> generalEffects = [];
    List<String> specialEffects = [];

    for (final perk in unlockedPerks) {
      for (final effect in perk.effects) {
        String description = '';
        
        switch (effect.effect) {
          case PerkEffect.categoryBonus:
            description = '+${(effect.value * 100).toInt()}% XP';
            final category = effect.category ?? 'General';
            effectsByCategory[category] = effectsByCategory[category] ?? [];
            effectsByCategory[category]!.add(description);
            break;
            
          case PerkEffect.xpBonus:
            description = '+${(effect.value * 100).toInt()}% All XP';
            generalEffects.add(description);
            break;
            
          case PerkEffect.lootBoxBonus:
            description = '+${(effect.value * 100).toInt()}% Loot Box Chance';
            generalEffects.add(description);
            break;
            
          case PerkEffect.streakFreeze:
            description = 'Streak Protection';
            specialEffects.add(description);
            break;
        }
      }
    }

    return {
      'categoryEffects': effectsByCategory,
      'generalEffects': generalEffects,
      'specialEffects': specialEffects,
      'totalPerks': unlockedPerks.length,
    };
  }
}