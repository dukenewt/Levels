import 'package:flutter/foundation.dart';

/// Centralized gameplay tuning values with sensible defaults.
/// In debug builds, these can be adjusted via the Gameplay Debug Panel.
class GameBalance extends ChangeNotifier {
  GameBalance._();

  static final GameBalance instance = GameBalance._();

  // Base XP formula: A * sqrt(minutes) + B
  double baseA = 10.0;
  double baseB = 5.0;
  int minBaseXPFloor = 5;

  // Morning bonus percent (applied to finalBaseXP if task is a morning habit)
  double morningBonusPct = 0.10; // 10%

  // Streak bonus base percent (of base XP)
  double streakBasePct = 0.05; // 5%

  // Streak multiplier pieces
  double streakDailyIncrement = 0.2; // < 7 days, 0.2x per day
  double streakBaseAt7 = 1.4; // at day 7 baseline
  double streakWeeklyIncrement = 0.03; // days 7..29
  double streakBaseAt30 = 2.0; // at day 30 baseline
  double streakMonthlyIncrement = 0.01; // 30+

  // Difficulty multipliers
  double diffEasy = 0.8;
  double diffMedium = 1.0;
  double diffHard = 1.4;
  double diffEpic = 2.0;

  // Category multipliers (fallback to 1.0 if unknown)
  final Map<String, double> categoryMult = {
    'health': 1.5,
    'fitness': 1.5,
    'wellness': 1.5,
    'learning': 1.4,
    'education': 1.4,
    'skill': 1.4,
    'work': 1.2,
    'career': 1.2,
    'social': 1.3,
    'relationships': 1.3,
    'creativity': 1.2,
    'art': 1.2,
    'maintenance': 0.9,
    'chores': 0.9,
  };

  // Loot box chance per difficulty
  double lootEasy = 0.15;
  double lootMedium = 0.10;
  double lootHard = 0.06;
  double lootEpic = 0.03;

  // Loot multiplier distribution thresholds
  // If roll < t1 -> m1, else if < t2 -> m2, else if < t3 -> m3, else m4
  double lootT1 = 0.60;
  double lootT2 = 0.85;
  double lootT3 = 0.96;
  double lootM1 = 1.5;
  double lootM2 = 2.0;
  double lootM3 = 2.5;
  double lootM4 = 3.0;

  // Helpers
  double categoryMultiplierFor(String category) {
    return categoryMult[category.toLowerCase()] ?? 1.0;
  }

  double difficultyMultiplierFor(Object difficultyEnum) {
    final name = describeEnum(difficultyEnum as dynamic);
    switch (name) {
      case 'easy':
        return diffEasy;
      case 'medium':
        return diffMedium;
      case 'hard':
        return diffHard;
      case 'epic':
        return diffEpic;
      default:
        return 1.0;
    }
  }

  double lootChanceFor(Object difficultyEnum) {
    final name = describeEnum(difficultyEnum as dynamic);
    switch (name) {
      case 'easy':
        return lootEasy;
      case 'medium':
        return lootMedium;
      case 'hard':
        return lootHard;
      case 'epic':
        return lootEpic;
      default:
        return 0.0;
    }
  }

  void resetDefaults() {
    baseA = 10.0;
    baseB = 5.0;
    minBaseXPFloor = 5;
    morningBonusPct = 0.10;
    streakBasePct = 0.05;
    streakDailyIncrement = 0.2;
    streakBaseAt7 = 1.4;
    streakWeeklyIncrement = 0.03;
    streakBaseAt30 = 2.0;
    streakMonthlyIncrement = 0.01;
    diffEasy = 0.8;
    diffMedium = 1.0;
    diffHard = 1.4;
    diffEpic = 2.0;
    categoryMult
      ..clear()
      ..addAll({
        'health': 1.5,
        'fitness': 1.5,
        'wellness': 1.5,
        'learning': 1.4,
        'education': 1.4,
        'skill': 1.4,
        'work': 1.2,
        'career': 1.2,
        'social': 1.3,
        'relationships': 1.3,
        'creativity': 1.2,
        'art': 1.2,
        'maintenance': 0.9,
        'chores': 0.9,
      });
    lootEasy = 0.15;
    lootMedium = 0.10;
    lootHard = 0.06;
    lootEpic = 0.03;
    lootT1 = 0.60;
    lootT2 = 0.85;
    lootT3 = 0.96;
    lootM1 = 1.5;
    lootM2 = 2.0;
    lootM3 = 2.5;
    lootM4 = 3.0;
    notifyListeners();
  }

  /// Preset for faster early leveling during playtests
  void applyFastLevelingPreset() {
    baseA = 14.0;
    baseB = 8.0;
    minBaseXPFloor = 8;
    morningBonusPct = 0.15;
    diffEasy = 0.95;
    diffMedium = 1.15;
    diffHard = 1.6;
    diffEpic = 2.2;
    lootEasy = 0.22;
    lootMedium = 0.14;
    lootHard = 0.08;
    lootEpic = 0.05;
    notifyListeners();
  }
}
