import 'package:flutter_test/flutter_test.dart';

import 'package:dailyxp/models/task.dart';
import 'package:dailyxp/models/user.dart' as app_user;
import 'package:dailyxp/features/character_progression/domain/completion_context.dart';
import 'package:dailyxp/services/enhanced_xp_calculation_service.dart';
import 'package:dailyxp/services/pure_effect_engine.dart' as pe;
import 'package:dailyxp/models/effect.dart';

void main() {
  group('EnhancedXPCalculationService (using PureEffectEngine)', () {
    test('computes perkBonusXP from normalized effects (category bonus)', () {
      final user = app_user.User(
        id: 'u1',
        email: 'u1@example.com',
        displayName: 'Test',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        level: 20,
        currentXp: 0,
        // Only category XP perk to make the assertion simple
        perks: const ['health_expert'],
      );

      final task = Task(
        id: 't1',
        title: 'Morning Run',
        description: '',
        category: 'Health',
        difficulty: TaskDifficulty.medium,
        timeCostMinutes: 20,
      );

      final ctx = CompletionContext.defaultContext();
      final svc = EnhancedXPCalculationService();

      final result = svc.calculateEnhancedXP(user, task, ctx);

      // Compute expected perk bonus directly from normalized effects to avoid drift
      final effects = pe.PureEffectEngine.evaluateEffects(
        user: user,
        context: {
          'category': task.category,
          'difficulty': task.difficulty.name,
          'streak': ctx.currentStreak,
          'completion_time': ctx.completionTime.toIso8601String(),
          'perfect_weeks': ctx.perfectWeeksThisMonth,
          'is_challenge': ctx.isPartOfChallenge,
        },
      );
      double categoryBonusFraction = 0.0;
      double globalBonusFraction = 0.0;
      for (final e in effects.appliedEffects) {
        if (e.targetProperty == 'xp' && e.scope == EffectScope.category) {
          final matchesCategory =
              e.conditions.any((c) => c.type == 'category' && c.value == task.category);
          if (matchesCategory) categoryBonusFraction += e.value;
        } else if (e.targetProperty == 'xp' && e.scope == EffectScope.global) {
          globalBonusFraction += e.value;
        }
      }
      final expectedPerkBonus =
          (result.originalBreakdown.finalBaseXP * categoryBonusFraction).round() +
          (result.originalBreakdown.totalXP * globalBonusFraction).round();
      expect(result.perkBonusXP, expectedPerkBonus);

      // final total = original total + perk bonus
      expect(result.finalTotalXP,
          result.originalBreakdown.totalXP + result.perkBonusXP);

      // Active perk names should include the perk's name, and descriptions present
      expect(result.activePerkNames.isNotEmpty, isTrue);
      expect(result.perkDescriptions.isNotEmpty, isTrue);
    });
  });
}
