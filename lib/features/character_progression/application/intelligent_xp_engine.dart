import 'dart:math';
import '../../../models/task.dart';
import '../domain/completion_context.dart';
import '../../../gameplay/game_balance.dart';

/// Loot box result for random XP bonuses
class LootBoxResult {
  final bool wasTriggered;
  final double multiplier;
  final int bonusXP;
  final String description;

  LootBoxResult({
    required this.wasTriggered,
    required this.multiplier,
    required this.bonusXP,
    required this.description,
  });

  static LootBoxResult none() => LootBoxResult(
        wasTriggered: false,
        multiplier: 1.0,
        bonusXP: 0,
        description: '',
      );
}

/// Detailed breakdown of XP calculation components
class XPCalculationBreakdown {
  final int baseTimeXP;
  final double categoryMultiplier;
  final String categoryReason;
  final double difficultyMultiplier;
  final String difficultyReason;
  final int finalBaseXP;
  final int streakBonus;
  final int perfectWeekBonus;
  final int morningBonus;
  final LootBoxResult lootBoxResult;
  final int totalBonusXP;
  final int totalXP;
  final bool isMorningHabit;
  final bool completedInMorning;
  final int currentStreak;

  XPCalculationBreakdown({
    required this.baseTimeXP,
    required this.categoryMultiplier,
    required this.categoryReason,
    required this.difficultyMultiplier,
    required this.difficultyReason,
    required this.finalBaseXP,
    required this.streakBonus,
    required this.perfectWeekBonus,
    required this.morningBonus,
    required this.lootBoxResult,
    required this.totalBonusXP,
    required this.totalXP,
    required this.isMorningHabit,
    required this.completedInMorning,
    required this.currentStreak,
  });
}

/// The Intelligent XP Engine calculates task rewards based on real-world factors
/// Think of this as your app's "productivity economist" - it understands the true
/// value of different activities and rewards users accordingly
class IntelligentXPEngine {
  static final Random _random = Random();

  /// Calculate comprehensive XP breakdown with all factors
  XPCalculationBreakdown calculateDetailedXP(
      Task task, CompletionContext context) {
    // Start with time-based XP (foundation of effort measurement)
    int baseTimeXP = _calculateTimeBasedXP(task.timeCostMinutes);

    // Apply category multipliers (some activities have higher life impact)
    double categoryMultiplier = _getCategoryMultiplier(task.category);
    String categoryReason = _getCategoryReason(task.category);

    // Apply difficulty scaling (harder tasks deserve more recognition)
    double difficultyMultiplier = _getDifficultyMultiplier(task.difficulty);
    String difficultyReason = _getDifficultyReason(task.difficulty);

    // Calculate final base XP
    int finalBaseXP =
        (baseTimeXP * categoryMultiplier * difficultyMultiplier).round();
    // Ensure minimum viable XP
    finalBaseXP = finalBaseXP < GameBalance.instance.minBaseXPFloor
        ? GameBalance.instance.minBaseXPFloor
        : finalBaseXP;

    // Calculate all bonuses
    int streakBonus = context.currentStreak > 1
        ? calculateStreakBonus(task, context.currentStreak)
        : 0;
    int perfectWeekBonus = context.perfectWeeksThisMonth > 0
        ? calculatePerfectWeekBonus(task, context.perfectWeeksThisMonth)
        : 0;

    bool isMorningHabit = this.isMorningHabit(task);
    bool completedInMorning = isCompletedInMorning(context.completionTime);
    int morningBonus = (isMorningHabit && completedInMorning)
        ? (finalBaseXP * GameBalance.instance.morningBonusPct).round()
        : 0;

    // Calculate loot box bonus (chance for XP multiplier)
    LootBoxResult lootBoxResult = _calculateLootBoxBonus(
        task, finalBaseXP + streakBonus + perfectWeekBonus + morningBonus);

    int totalBonusXP =
        streakBonus + perfectWeekBonus + morningBonus + lootBoxResult.bonusXP;
    int totalXP = finalBaseXP + totalBonusXP;

    return XPCalculationBreakdown(
      baseTimeXP: baseTimeXP,
      categoryMultiplier: categoryMultiplier,
      categoryReason: categoryReason,
      difficultyMultiplier: difficultyMultiplier,
      difficultyReason: difficultyReason,
      finalBaseXP: finalBaseXP,
      streakBonus: streakBonus,
      perfectWeekBonus: perfectWeekBonus,
      morningBonus: morningBonus,
      lootBoxResult: lootBoxResult,
      totalBonusXP: totalBonusXP,
      totalXP: totalXP,
      isMorningHabit: isMorningHabit,
      completedInMorning: completedInMorning,
      currentStreak: context.currentStreak,
    );
  }

  /// Calculate base XP for a task based on multiple factors
  /// This is like having a smart assistant that understands both effort and impact
  int calculateBaseXP(Task task) {
    // Start with time-based XP (foundation of effort measurement)
    int baseXP = _calculateTimeBasedXP(task.timeCostMinutes);

    // Apply category multipliers (some activities have higher life impact)
    double categoryMultiplier = _getCategoryMultiplier(task.category);

    // Apply difficulty scaling (harder tasks deserve more recognition)
    double difficultyMultiplier = _getDifficultyMultiplier(task.difficulty);

    // Calculate final base XP
    int finalXP = (baseXP * categoryMultiplier * difficultyMultiplier).round();

    // Ensure minimum viable XP (even small tasks deserve recognition)
    return finalXP < GameBalance.instance.minBaseXPFloor
        ? GameBalance.instance.minBaseXPFloor
        : finalXP;
  }

  /// Calculate bonus XP based on completion patterns and streaks
  /// This is where consistency gets rewarded - like compound interest for habits
  int calculateBonusXP(Task task, CompletionContext context) {
    int bonusXP = 0;

    // Streak bonuses - reward consistency
    if (context.currentStreak > 1) {
      bonusXP += calculateStreakBonus(task, context.currentStreak);
    }

    // Perfect week bonuses - reward weekly consistency
    if (context.perfectWeeksThisMonth > 0) {
      bonusXP += calculatePerfectWeekBonus(task, context.perfectWeeksThisMonth);
    }

    // Time of day bonuses - morning habits get extra recognition
    if (isMorningHabit(task) && isCompletedInMorning(context.completionTime)) {
      bonusXP += (task.xpReward * GameBalance.instance.morningBonusPct).round();
    }

    return bonusXP;
  }

  /// Time is the universal currency of effort - more time = more XP
  /// Uses square root curve for natural diminishing returns
  int _calculateTimeBasedXP(int minutes) {
    // Ensure minimum time for calculation
    int effectiveMinutes = max(1, minutes);

    // Base formula: 10 * sqrt(minutes) + 5
    // This gives: 1min=15xp, 5min=27xp, 15min=44xp, 30min=60xp, 60min=82xp, 120min=115xp
    double rawXP =
        GameBalance.instance.baseA * sqrt(effectiveMinutes.toDouble()) +
            GameBalance.instance.baseB;

    return rawXP.round();
  }

  /// Different life areas have different impact multipliers
  /// Health and learning compound over time, so they get higher rewards
  double _getCategoryMultiplier(String category) {
    return GameBalance.instance.categoryMultiplierFor(category);
  }

  /// Get explanation for category multiplier
  String _getCategoryReason(String category) {
    switch (category.toLowerCase()) {
      case 'health':
      case 'fitness':
      case 'wellness':
        return 'Health activities compound over time and create lasting well-being benefits';

      case 'learning':
      case 'education':
      case 'skill':
        return 'Learning creates permanent knowledge and skill improvements';

      case 'work':
      case 'career':
        return 'Career activities are important for professional growth';

      case 'social':
      case 'relationships':
        return 'Relationships are fundamental to happiness and life satisfaction';

      case 'creativity':
      case 'art':
        return 'Creative activities enrich life and develop self-expression';

      case 'maintenance':
      case 'chores':
        return 'Maintenance tasks are necessary but don\'t create new growth';

      default:
        return 'Standard reward rate for general activities';
    }
  }

  /// Difficulty reflects both effort and skill development
  /// Harder tasks should provide more growth and recognition
  double _getDifficultyMultiplier(TaskDifficulty difficulty) {
    return GameBalance.instance.difficultyMultiplierFor(difficulty);
  }

  /// Get explanation for difficulty multiplier
  String _getDifficultyReason(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Easy tasks build momentum but require less effort and growth';
      case TaskDifficulty.medium:
        return 'Medium tasks provide balanced effort and standard growth';
      case TaskDifficulty.hard:
        return 'Hard tasks require significant effort and develop real skills';
      case TaskDifficulty.epic:
        return 'Epic challenges demand maximum effort and create breakthrough growth';
    }
  }

  /// Streak bonuses create powerful motivation for consistency
  /// The formula grows but not exponentially to prevent XP inflation
  int calculateStreakBonus(Task task, int streak) {
    // Bonus grows with square root to provide steady motivation without explosion
    int baseBonus =
        (task.xpReward * GameBalance.instance.streakBasePct).round();
    double streakMultiplier = _calculateStreakMultiplier(streak);

    return (baseBonus * streakMultiplier).round();
  }

  /// Streak multiplier that rewards consistency without going crazy
  /// Week 1: 1x, Week 2: 1.4x, Month 1: 2x, etc.
  double _calculateStreakMultiplier(int streak) {
    if (streak < 7) return streak * GameBalance.instance.streakDailyIncrement;
    if (streak < 30) {
      return GameBalance.instance.streakBaseAt7 +
          (streak - 7) * GameBalance.instance.streakWeeklyIncrement;
    }
    return GameBalance.instance.streakBaseAt30 +
        (streak - 30) * GameBalance.instance.streakMonthlyIncrement;
  }

  /// Perfect week bonuses reward weekly consistency patterns
  int calculatePerfectWeekBonus(Task task, int perfectWeeks) {
    return (task.xpReward * 0.15 * perfectWeeks)
        .round(); // 15% per perfect week
  }

  /// Morning habits deserve extra recognition - they set the tone for the day
  bool isMorningHabit(Task task) {
    final morningHabits = [
      'brush teeth',
      'exercise',
      'meditation',
      'journal',
      'read',
      'workout',
      'yoga',
      'walk',
      'stretch'
    ];

    return morningHabits.any((habit) =>
        task.title.toLowerCase().contains(habit) ||
        task.description.toLowerCase().contains(habit));
  }

  /// Check if task was completed in morning hours (5 AM - 11 AM)
  bool isCompletedInMorning(DateTime completionTime) {
    return completionTime.hour >= 5 && completionTime.hour < 11;
  }

  /// Calculate loot box bonus with difficulty-based probability
  /// Easy tasks have higher chances for excitement and momentum building
  LootBoxResult _calculateLootBoxBonus(Task task, int baseXPBeforeLootBox) {
    double lootBoxChance = _getLootBoxChance(task.difficulty);
    double roll = _random.nextDouble();

    if (roll < lootBoxChance) {
      // Loot box triggered! Calculate multiplier and bonus XP
      double multiplier = _getLootBoxMultiplier();
      int bonusXP = (baseXPBeforeLootBox * (multiplier - 1.0)).round();
      String description = _getLootBoxDescription(multiplier);

      return LootBoxResult(
        wasTriggered: true,
        multiplier: multiplier,
        bonusXP: bonusXP,
        description: description,
      );
    }

    return LootBoxResult.none();
  }

  /// Get loot box chance based on task difficulty
  /// Philosophy: Easy tasks need more excitement, hard tasks are already rewarding
  double _getLootBoxChance(TaskDifficulty difficulty) {
    return GameBalance.instance.lootChanceFor(difficulty);
  }

  /// Get random loot box multiplier when triggered
  /// Creates variety in loot box rewards
  double _getLootBoxMultiplier() {
    double roll = _random.nextDouble();

    if (roll < GameBalance.instance.lootT1) {
      return GameBalance.instance.lootM1;
    } else if (roll < GameBalance.instance.lootT2) {
      return GameBalance.instance.lootM2;
    } else if (roll < GameBalance.instance.lootT3) {
      return GameBalance.instance.lootM3;
    } else {
      return GameBalance.instance.lootM4;
    }
  }

  /// Get description for loot box result
  String _getLootBoxDescription(double multiplier) {
    if (multiplier >= 3.0) {
      return '🎁✨ ULTRA RARE! Triple XP Loot Box! ✨🎁';
    } else if (multiplier >= 2.5) {
      return '🎁⭐ EPIC! 2.5x XP Loot Box! ⭐🎁';
    } else if (multiplier >= 2.0) {
      return '🎁🔥 RARE! Double XP Loot Box! 🔥🎁';
    } else {
      return '🎁💫 Lucky! XP Bonus Loot Box! 💫🎁';
    }
  }
}
