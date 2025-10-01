// Pure effect evaluation engine for TaskBound
// Replaces PerkEffectEngine with a clean, testable design that uses the normalized Effect model

import '../models/effect.dart';
import '../models/state_delta.dart';
import '../models/ui_event.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/enhanced_user_perk.dart';
import '../features/character_progression/domain/completion_context.dart';

/// Result of evaluating all effects for a given context
class EffectEvaluationResult {
  final Map<String, double> propertyModifiers; // xp -> 1.25 (25% bonus)
  final Map<String, dynamic>
      conditionalValues; // streak_freeze -> 1 (has protection)
  final List<Effect> appliedEffects;
  final Map<String, String> effectDescriptions;
  final DateTime evaluatedAt;

  const EffectEvaluationResult({
    this.propertyModifiers = const {},
    this.conditionalValues = const {},
    this.appliedEffects = const [],
    this.effectDescriptions = const {},
    required this.evaluatedAt,
  });

  /// Get the final multiplier for a property (default 1.0 if not affected)
  double getMultiplier(String property) {
    return propertyModifiers[property] ?? 1.0;
  }

  /// Get a conditional value (e.g., streak freeze uses available)
  T? getConditionalValue<T>(String property) {
    return conditionalValues[property] as T?;
  }

  /// Check if any effects were applied
  bool get hasEffects => appliedEffects.isNotEmpty;

  /// Get human-readable summary of effects
  List<String> get effectSummary {
    return effectDescriptions.values.toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyModifiers': propertyModifiers,
      'conditionalValues': conditionalValues,
      'appliedEffects': appliedEffects.map((e) => e.id).toList(),
      'effectDescriptions': effectDescriptions,
      'evaluatedAt': evaluatedAt.toIso8601String(),
    };
  }
}

/// Breakdown of XP calculation with effects applied
class XPCalculationBreakdown {
  final int baseXP;
  final Map<String, int> categoryBonuses; // Health -> +15 XP
  final Map<String, int> globalBonuses; // All XP -> +10 XP
  final Map<String, int> contextBonuses; // Morning -> +5 XP
  final int totalXP;
  final List<String> explanations;
  final EffectEvaluationResult effectResults;

  const XPCalculationBreakdown({
    required this.baseXP,
    this.categoryBonuses = const {},
    this.globalBonuses = const {},
    this.contextBonuses = const {},
    required this.totalXP,
    this.explanations = const [],
    required this.effectResults,
  });

  factory XPCalculationBreakdown.fromEffects({
    required int baseXP,
    required EffectEvaluationResult effects,
    required String category,
    Map<String, dynamic> context = const {},
  }) {
    final categoryBonuses = <String, int>{};
    final globalBonuses = <String, int>{};
    final contextBonuses = <String, int>{};
    final explanations = <String>[];

    double totalMultiplier = 1.0;

    // Apply category-specific XP bonuses
    for (final effect in effects.appliedEffects) {
      if (effect.targetProperty == 'xp' &&
          effect.scope == EffectScope.category) {
        final bonus = (baseXP * effect.value).round();
        categoryBonuses[effect.name] = bonus;
        totalMultiplier += effect.value;
        explanations.add('+${(effect.value * 100).toInt()}% $category XP');
      }
    }

    // Apply global XP bonuses
    for (final effect in effects.appliedEffects) {
      if (effect.targetProperty == 'xp' && effect.scope == EffectScope.global) {
        final bonus = (baseXP * effect.value).round();
        globalBonuses[effect.name] = bonus;
        totalMultiplier += effect.value;
        explanations.add('+${(effect.value * 100).toInt()}% All XP');
      }
    }

    // Apply context-based bonuses (morning, streak, etc.)
    for (final effect in effects.appliedEffects) {
      if (effect.targetProperty == 'xp' &&
          effect.scope == EffectScope.context) {
        final bonus = (baseXP * effect.value).round();
        contextBonuses[effect.name] = bonus;
        totalMultiplier += effect.value;
        explanations.add(effect.description);
      }
    }

    final totalXP = (baseXP * totalMultiplier).round();

    return XPCalculationBreakdown(
      baseXP: baseXP,
      categoryBonuses: categoryBonuses,
      globalBonuses: globalBonuses,
      contextBonuses: contextBonuses,
      totalXP: totalXP,
      explanations: explanations,
      effectResults: effects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseXP': baseXP,
      'categoryBonuses': categoryBonuses,
      'globalBonuses': globalBonuses,
      'contextBonuses': contextBonuses,
      'totalXP': totalXP,
      'explanations': explanations,
      'effectResults': effectResults.toJson(),
    };
  }
}

/// Pure effect evaluation engine - no side effects, fully testable
class PureEffectEngine {
  /// Convert existing perks to normalized Effect objects
  static List<Effect> _convertPerksToEffects(List<EnhancedUserPerk> perks) {
    final effects = <Effect>[];

    for (final perk in perks) {
      for (final effectData in perk.effects) {
        final effect = _convertPerkEffectToEffect(perk, effectData);
        if (effect != null) {
          effects.add(effect);
        }
      }
    }

    return effects;
  }

  /// Convert a single perk effect to normalized Effect
  static Effect? _convertPerkEffectToEffect(
      EnhancedUserPerk perk, PerkEffectData effectData) {
    switch (effectData.effect) {
      case PerkEffect.xpBonus:
        return Effect.xpBonus(
          id: '${perk.id}_xp_bonus',
          name: perk.name,
          bonusPercentage: effectData.value,
          scope: EffectScope.global,
        );

      case PerkEffect.categoryBonus:
        if (effectData.category != null) {
          return Effect.xpBonus(
            id: '${perk.id}_${effectData.category!.toLowerCase()}_bonus',
            name: perk.name,
            bonusPercentage: effectData.value,
            scope: EffectScope.category,
            category: effectData.category!,
          );
        }
        break;

      case PerkEffect.lootBoxBonus:
        return Effect.lootBoxBonus(
          id: '${perk.id}_loot_bonus',
          name: perk.name,
          bonusPercentage: effectData.value,
        );

      case PerkEffect.streakFreeze:
        return Effect.streakFreeze(
          id: '${perk.id}_streak_freeze',
          name: perk.name,
          uses: effectData.value.round(),
        );

      case PerkEffect.conditionalBonus:
        // Handle conditional bonuses (like easy recurring tasks)
        final conditions = effectData.metadata?['conditions'] as List<String>?;
        if (conditions != null) {
          return Effect.conditionalXpBonus(
            id: '${perk.id}_conditional_bonus',
            name: perk.name,
            bonusPercentage: effectData.value,
            conditions: conditions,
          );
        }
        break;
    }

    return null;
  }

  /// Pure function: evaluate all effects for given context
  static EffectEvaluationResult evaluateEffects({
    required User user,
    required Map<String, dynamic> context,
  }) {
    // Get user's unlocked perks and convert to effects
    final unlockedPerks = _getUnlockedPerks(user);
    final effects = _convertPerksToEffects(unlockedPerks);

    final propertyModifiers = <String, double>{};
    final conditionalValues = <String, dynamic>{};
    final appliedEffects = <Effect>[];
    final effectDescriptions = <String, String>{};

    // Evaluate each effect
    for (final effect in effects) {
      if (effect.appliesTo(context)) {
        appliedEffects.add(effect);
        effectDescriptions[effect.id] = effect.description;

        if (effect.targetProperty != null) {
          final property = effect.targetProperty!;

          if (effect.modifier == EffectModifier.conditional) {
            // Store conditional values (like streak freeze availability)
            conditionalValues[property] = effect.value;
          } else {
            // Calculate property modifiers
            final currentModifier = propertyModifiers[property] ?? 1.0;

            switch (effect.stacking) {
              case EffectStacking.additive:
                if (effect.modifier == EffectModifier.multiplicative) {
                  propertyModifiers[property] = currentModifier + effect.value;
                } else {
                  propertyModifiers[property] = currentModifier + effect.value;
                }
                break;

              case EffectStacking.multiplicative:
                propertyModifiers[property] =
                    currentModifier * (1.0 + effect.value);
                break;

              case EffectStacking.highest:
                propertyModifiers[property] = [
                  currentModifier,
                  1.0 + effect.value
                ].reduce((a, b) => a > b ? a : b);
                break;

              case EffectStacking.latest:
              case EffectStacking.none:
                propertyModifiers[property] = 1.0 + effect.value;
                break;
            }
          }
        }
      }
    }

    return EffectEvaluationResult(
      propertyModifiers: propertyModifiers,
      conditionalValues: conditionalValues,
      appliedEffects: appliedEffects,
      effectDescriptions: effectDescriptions,
      evaluatedAt: DateTime.now(),
    );
  }

  /// Pure function: calculate XP with effects applied
  static XPCalculationBreakdown calculateXPWithEffects({
    required User user,
    required Task task,
    required CompletionContext context,
    required int baseXP,
  }) {
    // Build context for effect evaluation
    final effectContext = EffectContext.forTask(
      category: task.category,
      difficulty: task.difficulty.name,
      streak: context.currentStreak,
      completionTime: context.completionTime,
      additional: {
        'task_id': task.id,
        'user_level': user.level,
        'perfect_weeks': context.perfectWeeksThisMonth,
        'is_challenge': context.isPartOfChallenge,
        'recurring': task.recurrencePattern != null,
      },
    );

    // Evaluate effects
    final effects = evaluateEffects(user: user, context: effectContext);

    // Create breakdown
    return XPCalculationBreakdown.fromEffects(
      baseXP: baseXP,
      effects: effects,
      category: task.category,
      context: effectContext,
    );
  }

  /// Pure function: calculate loot box chance with effects
  static double calculateLootBoxChance({
    required User user,
    required Task task,
    required double baseChance,
    Map<String, dynamic>? additionalContext,
  }) {
    final effectContext = EffectContext.forTask(
      category: task.category,
      difficulty: task.difficulty.name,
      additional: {
        'task_id': task.id,
        'user_level': user.level,
        ...?additionalContext,
      },
    );

    final effects = evaluateEffects(user: user, context: effectContext);
    final lootModifier = effects.getMultiplier('loot_box_chance');

    // Apply bonus and cap at 95%
    return (baseChance * lootModifier).clamp(0.0, 0.95);
  }

  /// Pure function: check if streak protection is available
  static bool hasStreakProtection({
    required User user,
    required Task overdueTask,
  }) {
    final effectContext = EffectContext.forTask(
      category: overdueTask.category,
      difficulty: overdueTask.difficulty.name,
      additional: {
        'task_id': overdueTask.id,
        'user_level': user.level,
        'is_overdue': true,
      },
    );

    final effects = evaluateEffects(user: user, context: effectContext);
    final freezeUses = effects.getConditionalValue<double>('streak_freeze');

    return freezeUses != null && freezeUses > 0;
  }

  /// Pure function: get effect preview for UI
  static List<String> getEffectPreview({
    required User user,
    required String category,
    Map<String, dynamic>? additionalContext,
  }) {
    final effectContext = EffectContext.forPreview(
      category: category,
      additional: {
        'user_level': user.level,
        ...?additionalContext,
      },
    );

    final effects = evaluateEffects(user: user, context: effectContext);
    return effects.effectSummary;
  }

  /// Pure function: generate completion flow results
  static CompletionFlowResult processTaskCompletion({
    required User user,
    required Task task,
    required CompletionContext context,
    required int baseXP,
    bool hasLootBox = false,
  }) {
    // Calculate XP with effects
    final xpBreakdown = calculateXPWithEffects(
      user: user,
      task: task,
      context: context,
      baseXP: baseXP,
    );

    // Check for level up
    final newXP = user.currentXp + xpBreakdown.totalXP;
    final oldLevel = user.level;
    final newLevel = _calculateLevel(newXP);
    final leveledUp = newLevel > oldLevel;

    // Check for new perks
    final newPerks = <String>[];
    if (leveledUp) {
      final availablePerks =
          EnhancedUserPerks.getAvailablePerksForLevel(newLevel);
      for (final perk in availablePerks) {
        if (perk.requiredLevel == newLevel && !user.perks.contains(perk.id)) {
          newPerks.add(perk.id);
        }
      }
    }

    // Check if talent choice is needed
    final needsTalentChoice = leveledUp && _needsTalentChoice(newLevel);

    // Create state delta
    final stateDelta = StateDelta.taskCompletion(
      taskId: task.id,
      xpAwarded: xpBreakdown.totalXP,
      xpChange: xpBreakdown.totalXP,
      levelChange: leveledUp ? 1 : null,
      newPerks: newPerks.isNotEmpty ? newPerks : null,
      metadata: {
        'xp_breakdown': xpBreakdown.toJson(),
        'base_xp': baseXP,
        'has_loot_box': hasLootBox,
      },
    );

    // Create UI events
    final uiEvents = <UiEvent>[];

    // Task completion celebration
    uiEvents.add(CelebrationEvent.taskCompletion(
      taskTitle: task.title,
      xpGained: xpBreakdown.totalXP,
      perkBonuses: xpBreakdown.explanations,
      hasLootBox: hasLootBox,
    ));

    // Level up celebration if applicable
    if (leveledUp) {
      uiEvents.add(CelebrationEvent.levelUp(
        newLevel: newLevel,
        newPerks: newPerks,
        needsTalentChoice: needsTalentChoice,
      ));
    }

    // Talent choice dialog if needed
    if (needsTalentChoice) {
      uiEvents.add(DialogEvent.talentChoice(
        level: newLevel,
        talentOptions: _getTalentOptionsForLevel(newLevel),
      ));
    }

    // Perk unlock dialogs
    for (final perkId in newPerks) {
      final perk = EnhancedUserPerks.getPerkById(perkId);
      if (perk != null) {
        uiEvents.add(DialogEvent.perkUnlock(
          perkName: perk.name,
          perkDescription: perk.description,
        ));
      }
    }

    return CompletionFlowResult(
      stateDelta: stateDelta,
      uiEvents: UiEventBatch.sequential(events: uiEvents),
      xpBreakdown: xpBreakdown,
    );
  }

  /// Helper: get unlocked perks for user (same as original engine)
  static List<EnhancedUserPerk> _getUnlockedPerks(User user) {
    // Be strict: only include perks explicitly present on the user to avoid
    // inflating effects during tests and previews.
    return user.perks
        .map((id) => EnhancedUserPerks.getPerkById(id))
        .whereType<EnhancedUserPerk>()
        .toList();
  }

  /// Helper: calculate level from XP (simplified)
  static int _calculateLevel(int xp) {
    // Simplified level calculation - replace with actual formula
    return (xp / 1000).floor() + 1;
  }

  /// Helper: check if level requires talent choice
  static bool _needsTalentChoice(int level) {
    return [5, 10, 15, 20, 25].contains(level);
  }

  /// Helper: get talent options for level
  static List<Map<String, dynamic>> _getTalentOptionsForLevel(int level) {
    // Simplified - replace with actual talent system
    return [
      {'id': 'project_management', 'name': 'Project Management'},
      {'id': 'nlp_categorization', 'name': 'Smart Categorization'},
    ];
  }
}

/// Result of processing a complete task completion flow
class CompletionFlowResult {
  final StateDelta stateDelta;
  final UiEventBatch uiEvents;
  final XPCalculationBreakdown xpBreakdown;

  const CompletionFlowResult({
    required this.stateDelta,
    required this.uiEvents,
    required this.xpBreakdown,
  });

  Map<String, dynamic> toJson() {
    return {
      'stateDelta': stateDelta.toJson(),
      'uiEvents': uiEvents.toJson(),
      'xpBreakdown': xpBreakdown.toJson(),
    };
  }
}
