import '../models/task.dart';
import '../models/user.dart';
import '../features/character_progression/application/intelligent_xp_engine.dart';
import '../features/character_progression/domain/completion_context.dart';
import 'perk_effect_engine.dart';

/// Enhanced XP calculation breakdown that includes perk effects
class EnhancedXPCalculationBreakdown {
  final XPCalculationBreakdown originalBreakdown;
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
  final IntelligentXPEngine _xpEngine = IntelligentXPEngine();

  /// Calculate XP with all bonuses including perks
  EnhancedXPCalculationBreakdown calculateEnhancedXP(
    User user,
    Task task,
    CompletionContext context,
  ) {
    // Get the original XP calculation
    final originalBreakdown = _xpEngine.calculateDetailedXP(task, context);

    // Apply perk effects
    final perkEffects = PerkEffectEngine.applyPerksToTask(user, task, context);

    // Calculate perk bonus XP
    int perkBonusXP = 0;

    // Apply category-specific perk bonuses
    if (perkEffects.categoryBonusMultiplier > 0) {
      perkBonusXP +=
          (originalBreakdown.finalBaseXP * perkEffects.categoryBonusMultiplier)
              .round();
    }

    // Apply general XP perk bonuses to the total original XP
    if (perkEffects.xpBonusMultiplier > 0) {
      perkBonusXP +=
          (originalBreakdown.totalXP * perkEffects.xpBonusMultiplier).round();
    }

    // Calculate final total XP
    final finalTotalXP = originalBreakdown.totalXP + perkBonusXP;

    return EnhancedXPCalculationBreakdown(
      originalBreakdown: originalBreakdown,
      perkEffects: perkEffects,
      perkBonusXP: perkBonusXP,
      finalTotalXP: finalTotalXP,
      activePerkNames: perkEffects.appliedPerkNames,
      perkDescriptions: perkEffects.effectDescriptions,
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
    return PerkEffectEngine.shouldApplyStreakFreeze(user, overdueTask);
  }

  /// Get effects that will be applied to a task based on category
  List<String> getPerkEffectsForCategory(User user, String category) {
    return PerkEffectEngine.getPerkEffectPreview(user, category);
  }

  // Note: Loot box logic is handled by IntelligentXPEngine within the
  // original breakdown to avoid drift and duplication.
}
