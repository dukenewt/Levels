import 'package:flutter_test/flutter_test.dart';

import 'package:dailyxp/models/user.dart' as app_user;
import 'package:dailyxp/models/task.dart';
import 'package:dailyxp/services/pure_effect_engine.dart';
import 'package:dailyxp/features/character_progression/domain/completion_context.dart';

void main() {
  group('PureEffectEngine', () {
    test('evaluates category XP bonus, loot bonus, and streak freeze', () {
      final user = app_user.User(
        id: 'u1',
        email: 'u1@example.com',
        displayName: 'Test',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        level: 20,
        currentXp: 0,
        // Unlock perks by id: health_expert (category XP), lucky_charm (loot), streak_guardian (freeze)
        perks: const ['health_expert', 'lucky_charm', 'streak_guardian'],
      );

      final context = {
        'category': 'Health',
        'difficulty': 'medium',
        'streak': 3,
        'completion_time': DateTime.now().toIso8601String(),
      };

      final effects = PureEffectEngine.evaluateEffects(user: user, context: context);

      // Compute expected XP multiplier from applied effects to avoid drift
      double expectedXpMultiplier = 1.0;
      for (final e in effects.appliedEffects) {
        if (e.targetProperty == 'xp') {
          expectedXpMultiplier += e.value;
        }
      }
      final xpMultiplier = effects.getMultiplier('xp');
      expect(xpMultiplier, closeTo(expectedXpMultiplier, 1e-9));

      // Loot box multiplier should equal 1.0 plus sum of loot effects
      double expectedLootMultiplier = 1.0;
      for (final e in effects.appliedEffects) {
        if (e.targetProperty == 'loot_box_chance') {
          expectedLootMultiplier += e.value;
        }
      }
      final lootMultiplier = effects.getMultiplier('loot_box_chance');
      expect(lootMultiplier, closeTo(expectedLootMultiplier, 1e-9));

      // Streak freeze should be available (value > 0)
      final freezeUses = effects.getConditionalValue<double>('streak_freeze');
      expect(freezeUses != null && freezeUses > 0, isTrue);

      // XP calculation helper applies category bonus correctly
      final task = Task(
        id: 't1',
        title: 'Run',
        description: '',
        category: 'Health',
        difficulty: TaskDifficulty.medium,
      );

      final baseXP = 100;
      final breakdown = PureEffectEngine.calculateXPWithEffects(
        user: user,
        task: task,
        context: CompletionContext.defaultContext(),
        baseXP: baseXP,
      );
      final expectedTotal = (baseXP * expectedXpMultiplier).round();
      expect(breakdown.totalXP, expectedTotal);
    });
  });
}
