import '../../../models/task.dart';

/// Context about when and how a task was completed
/// This gives the XP engine the information it needs to calculate bonuses
class CompletionContext {
  final DateTime completionTime;
  final int currentStreak; // Days in a row this task was completed
  final int perfectWeeksThisMonth; // Weeks where all instances were completed
  final bool isPartOfChallenge; // Whether user is in a specific challenge
  final Map<String, dynamic> additionalContext; // For future extensibility

  CompletionContext({
    required this.completionTime,
    this.currentStreak = 0,
    this.perfectWeeksThisMonth = 0,
    this.isPartOfChallenge = false,
    this.additionalContext = const {},
  });

  /// Factory constructor for creating default context for previews
  factory CompletionContext.defaultContext() {
    return CompletionContext(
      completionTime: DateTime.now(),
      currentStreak: 1,
      perfectWeeksThisMonth: 0,
      isPartOfChallenge: false,
    );
  }

  /// Factory constructor for real task completion
  factory CompletionContext.forTaskCompletion({
    required DateTime completionTime,
    int currentStreak = 0,
    int perfectWeeksThisMonth = 0,
    bool isPartOfChallenge = false,
    Map<String, dynamic> additionalContext = const {},
  }) {
    return CompletionContext(
      completionTime: completionTime,
      currentStreak: currentStreak,
      perfectWeeksThisMonth: perfectWeeksThisMonth,
      isPartOfChallenge: isPartOfChallenge,
      additionalContext: additionalContext,
    );
  }
}

/// Enhanced task completion result that includes XP breakdown
/// This helps users understand exactly why they earned their XP
class EnhancedTaskCompletion {
  final Task completedTask;
  final int baseXP;
  final int bonusXP;
  final int totalXP;
  final Map<String, int> xpBreakdown; // Shows where each XP point came from

  EnhancedTaskCompletion({
    required this.completedTask,
    required this.baseXP,
    required this.bonusXP,
    required this.xpBreakdown,
  }) : totalXP = baseXP + bonusXP;

  /// Create human-readable explanation of XP earned
  String getXPExplanation() {
    List<String> explanations = [];

    explanations.add('Base XP: $baseXP');

    if (xpBreakdown['streak_bonus'] != null &&
        xpBreakdown['streak_bonus']! > 0) {
      explanations.add('Streak bonus: +${xpBreakdown['streak_bonus']}');
    }

    if (xpBreakdown['morning_bonus'] != null &&
        xpBreakdown['morning_bonus']! > 0) {
      explanations.add('Morning completion: +${xpBreakdown['morning_bonus']}');
    }

    if (xpBreakdown['perfect_week_bonus'] != null &&
        xpBreakdown['perfect_week_bonus']! > 0) {
      explanations
          .add('Perfect week bonus: +${xpBreakdown['perfect_week_bonus']}');
    }

    return explanations.join(', ');
  }
}
