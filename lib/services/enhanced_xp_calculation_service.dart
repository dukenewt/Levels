import '../models/task.dart';
import '../models/user.dart';
import '../features/character_progression/application/intelligent_xp_engine.dart'
    as xp;
import '../features/character_progression/domain/completion_context.dart';
import 'pure_effect_engine.dart' as pe;
import '../models/effect.dart';
import 'perk_effect_engine.dart' show PerkEffectResult;

/// Enhanced XP calculation breakdown that includes perk effects
class EnhancedXPCalculationBreakdown {
  final xp.XPCalculationBreakdown originalBreakdown;
  final PerkEffectResult perkEffects;
  final int perkBonusXP;
  final int finalTotalXP;
  final List<String> activePerkNames;
  final Map<String, String> perkDescriptions;

  EnhancedXPCalculationBreakdown({
    required this.originalBreakdown,
    required this.perkEffects,
    required this.perkBonusXP,
    required this.finalTotalXP,
    required this.activePerkNames,
    required this.perkDescriptions,
  });

  /// Get a user-friendly breakdown of all XP sources
  Map<String, dynamic> getDetailedBreakdown() {
    return {
      'baseXP': originalBreakdown.finalBaseXP,
      'categoryMultiplier': originalBreakdown.categoryMultiplier,
      'difficultyMultiplier': originalBreakdown.difficultyMultiplier,
      'streakBonus': originalBreakdown.streakBonus,
      'perfectWeekBonus': originalBreakdown.perfectWeekBonus,
      'morningBonus': originalBreakdown.morningBonus,
      'lootBoxBonus': originalBreakdown.lootBoxResult.bonusXP,
      'perkBonus': perkBonusXP,
      'originalTotal': originalBreakdown.totalXP,
      'finalTotal': finalTotalXP,
      'activePerks': activePerkNames,
      'perkEffects': perkDescriptions,
    };
  }

  /// Get breakdown for UI display
  List<String> getBreakdownForUI() {
    List<String> breakdown = [
      'Base XP: ${originalBreakdown.finalBaseXP}',
    ];

    if (originalBreakdown.streakBonus > 0) {
      breakdown.add('Streak Bonus: +${originalBreakdown.streakBonus}');
    }

    if (originalBreakdown.perfectWeekBonus > 0) {
      breakdown.add('Perfect Week: +${originalBreakdown.perfectWeekBonus}');
    }

    if (originalBreakdown.morningBonus > 0) {
      breakdown.add('Morning Bonus: +${originalBreakdown.morningBonus}');
    }

    if (originalBreakdown.lootBoxResult.wasTriggered) {
      breakdown.add(
          '${originalBreakdown.lootBoxResult.description}: +${originalBreakdown.lootBoxResult.bonusXP}');
    }

    if (perkBonusXP > 0) {
      breakdown.add('Perk Bonus: +${perkBonusXP}');

      // Add individual perk descriptions
      for (final description in perkDescriptions.values) {
        if (description.isNotEmpty) {
          breakdown.add('  • $description');
        }
      }
    }

    breakdown.add('Total XP: ${finalTotalXP}');

    return breakdown;
  }
}

/// Service that calculates XP with perk effects integrated
class EnhancedXPCalculationService {
  final xp.IntelligentXPEngine _xpEngine = xp.IntelligentXPEngine();

  /// Calculate XP with all bonuses including perks
  EnhancedXPCalculationBreakdown calculateEnhancedXP(
    User user,
    Task task,
    CompletionContext context,
  ) {
    // Get the original XP calculation
    final originalBreakdown = _xpEngine.calculateDetailedXP(task, context);

    // Evaluate effects using the pure engine
    final effectContext = CompletionContext(
      completionTime: context.completionTime,
      currentStreak: context.currentStreak,
      perfectWeeksThisMonth: context.perfectWeeksThisMonth,
      isPartOfChallenge: context.isPartOfChallenge,
      additionalContext: context.additionalContext,
    );

    final normalizedContext = {
      'category': task.category,
      'difficulty': task.difficulty.name,
      'streak': effectContext.currentStreak,
      'completion_time': effectContext.completionTime.toIso8601String(),
      'perfect_weeks': effectContext.perfectWeeksThisMonth,
      'is_challenge': effectContext.isPartOfChallenge,
    };

    final effects = pe.PureEffectEngine.evaluateEffects(
      user: user,
      context: normalizedContext,
    );

    // Compute perk bonus XP using normalized effects
    double categoryBonusFraction = 0.0;
    double globalXpBonusFraction = 0.0;

    for (final e in effects.appliedEffects) {
      if (e.targetProperty == 'xp') {
        if (e.scope == EffectScope.category) {
          // Category-specific: ensure this effect targets the task's category
          final matchesCategory = e.conditions.any(
            (c) => c.type == 'category' && c.value == task.category,
          );
          if (matchesCategory) {
            categoryBonusFraction += e.value;
          }
        } else if (e.scope == EffectScope.global) {
          globalXpBonusFraction += e.value;
        }
      }
    }

    int perkBonusXP = 0;
    if (categoryBonusFraction > 0) {
      perkBonusXP +=
          (originalBreakdown.finalBaseXP * categoryBonusFraction).round();
    }
    if (globalXpBonusFraction > 0) {
      perkBonusXP +=
          (originalBreakdown.totalXP * globalXpBonusFraction).round();
    }

    final finalTotalXP = originalBreakdown.totalXP + perkBonusXP;

    return EnhancedXPCalculationBreakdown(
      originalBreakdown: originalBreakdown,
      perkEffects: PerkEffectResult(
        categoryBonusMultiplier: categoryBonusFraction,
        xpBonusMultiplier: globalXpBonusFraction,
        lootBoxChanceBonus: effects.getMultiplier('loot_box_chance') - 1.0,
        hasStreakFreeze:
            (effects.getConditionalValue<double>('streak_freeze') ?? 0) > 0,
        appliedPerkNames:
            effects.appliedEffects.map((e) => e.name).toSet().toList(),
        effectDescriptions: effects.effectDescriptions,
      ),
      perkBonusXP: perkBonusXP,
      finalTotalXP: finalTotalXP,
      activePerkNames:
          effects.appliedEffects.map((e) => e.name).toSet().toList(),
      perkDescriptions: effects.effectDescriptions,
    );
  }

  /// Get preview of XP calculation for task creation UI
  Map<String, dynamic> getXPPreview(
    User user,
    Task task,
  ) {
    final context = CompletionContext.defaultContext();
    final enhancedBreakdown = calculateEnhancedXP(user, task, context);

    return {
      'baseXP': enhancedBreakdown.originalBreakdown.finalBaseXP,
      'totalXP': enhancedBreakdown.finalTotalXP,
      'perkBonus': enhancedBreakdown.perkBonusXP,
      'activePerks': enhancedBreakdown.activePerkNames,
      'hasPerks': enhancedBreakdown.perkBonusXP > 0,
      'breakdown': enhancedBreakdown.getBreakdownForUI(),
    };
  }

  /// Check if user can create Epic difficulty tasks (requires Project Management talent)
  bool canCreateEpicTasks(User user) {
    return user.hasProjectManagementTalent();
  }

  /// Get available difficulties for user based on talents
  List<TaskDifficulty> getAvailableDifficulties(User user) {
    final difficulties = [
      TaskDifficulty.easy,
      TaskDifficulty.medium,
      TaskDifficulty.hard,
    ];

    // Add Epic if user has Project Management talent
    if (canCreateEpicTasks(user)) {
      difficulties.add(TaskDifficulty.epic);
    }

    return difficulties;
  }

  /// Apply streak freeze if user has the perk and task is overdue
  bool tryApplyStreakFreeze(User user, Task overdueTask) {
    return pe.PureEffectEngine.hasStreakProtection(
      user: user,
      overdueTask: overdueTask,
    );
  }

  /// Get effects that will be applied to a task based on category
  List<String> getPerkEffectsForCategory(User user, String category) {
    return pe.PureEffectEngine.getEffectPreview(user: user, category: category);
  }

  // Note: Loot box logic is handled by IntelligentXPEngine within the
  // original breakdown to avoid drift and duplication.
}
