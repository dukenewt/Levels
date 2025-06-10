import '../models/task.dart';

/// The Intelligent XP Engine calculates task rewards based on real-world factors
/// Think of this as your app's "productivity economist" - it understands the true
/// value of different activities and rewards users accordingly
class IntelligentXPEngine {
  
  /// Calculate base XP for a task based on multiple factors
  /// This is like having a smart assistant that understands both effort and impact
  static int calculateBaseXP(Task task) {
    // Start with time-based XP (foundation of effort measurement)
    int baseXP = _calculateTimeBasedXP(task.timeCostMinutes);
    
    // Apply category multipliers (some activities have higher life impact)
    double categoryMultiplier = _getCategoryMultiplier(task.category);
    
    // Apply difficulty scaling (harder tasks deserve more recognition)
    double difficultyMultiplier = _getDifficultyMultiplier(task.difficulty);
    
    // Calculate final base XP
    int finalXP = (baseXP * categoryMultiplier * difficultyMultiplier).round();
    
    // Ensure minimum viable XP (even small tasks deserve recognition)
    return finalXP < 5 ? 5 : finalXP;
  }
  
  /// Calculate bonus XP based on completion patterns and streaks
  /// This is where consistency gets rewarded - like compound interest for habits
  static int calculateBonusXP(Task task, CompletionContext context) {
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
      bonusXP += (task.xpReward * 0.1).round(); // 10% morning bonus
    }
    
    return bonusXP;
  }
  
  /// Time is the universal currency of effort - more time = more XP
  /// But with diminishing returns to avoid XP inflation
  static int _calculateTimeBasedXP(int minutes) {
    if (minutes <= 5) return 10;      // Quick tasks: 10 XP
    if (minutes <= 15) return 25;     // Short tasks: 25 XP  
    if (minutes <= 30) return 50;     // Medium tasks: 50 XP
    if (minutes <= 60) return 100;    // Long tasks: 100 XP
    if (minutes <= 120) return 175;   // Extended tasks: 175 XP
    return 250;                       // Epic tasks: 250 XP (2+ hours)
  }
  
  /// Different life areas have different impact multipliers
  /// Health and learning compound over time, so they get higher rewards
  static double _getCategoryMultiplier(String category) {
    switch (category.toLowerCase()) {
      case 'health':
      case 'fitness':
      case 'wellness':
        return 1.5; // Health has long-term compound benefits
        
      case 'learning':
      case 'education':
      case 'skill':
        return 1.4; // Learning creates lasting value
        
      case 'work':
      case 'career':
        return 1.2; // Work is important but more externally motivated
        
      case 'social':
      case 'relationships':
        return 1.3; // Relationships are crucial for wellbeing
        
      case 'creativity':
      case 'art':
        return 1.2; // Creative work enriches life
        
      case 'maintenance':
      case 'chores':
        return 0.9; // Necessary but not growth-focused
        
      default:
        return 1.0; // Standard multiplier for uncategorized tasks
    }
  }
  
  /// Difficulty reflects both effort and skill development
  /// Harder tasks should provide more growth and recognition
  static double _getDifficultyMultiplier(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return 0.8;    // Less challenging, less growth
      case 'medium': return 1.0;  // Standard baseline
      case 'hard': return 1.4;    // Requires significant effort
      case 'epic': return 2.0;    // Major challenges deserve major rewards
      default: return 1.0;
    }
  }
  
  /// Streak bonuses create powerful motivation for consistency
  /// The formula grows but not exponentially to prevent XP inflation
  static int calculateStreakBonus(Task task, int streak) {
    // Bonus grows with square root to provide steady motivation without explosion
    int baseBonus = (task.xpReward * 0.05).round(); // 5% of base XP
    double streakMultiplier = _calculateStreakMultiplier(streak);
    
    return (baseBonus * streakMultiplier).round();
  }
  
  /// Streak multiplier that rewards consistency without going crazy
  /// Week 1: 1x, Week 2: 1.4x, Month 1: 2x, etc.
  static double _calculateStreakMultiplier(int streak) {
    if (streak < 7) return streak * 0.2;        // Daily building: 0.2x per day
    if (streak < 30) return 1.4 + (streak - 7) * 0.03; // Weekly building: slower growth
    return 2.0 + (streak - 30) * 0.01;          // Monthly+: minimal additional growth
  }
  
  /// Perfect week bonuses reward weekly consistency patterns
  static int calculatePerfectWeekBonus(Task task, int perfectWeeks) {
    return (task.xpReward * 0.15 * perfectWeeks).round(); // 15% per perfect week
  }
  
  /// Morning habits deserve extra recognition - they set the tone for the day
  static bool isMorningHabit(Task task) {
    final morningHabits = [
      'brush teeth', 'exercise', 'meditation', 'journal', 
      'read', 'workout', 'yoga', 'walk', 'stretch'
    ];
    
    return morningHabits.any((habit) => 
      task.title.toLowerCase().contains(habit) ||
      task.description.toLowerCase().contains(habit)
    );
  }
  
  /// Check if task was completed in morning hours (5 AM - 11 AM)
  static bool isCompletedInMorning(DateTime completionTime) {
    return completionTime.hour >= 5 && completionTime.hour < 11;
  }
}

/// Context about when and how a task was completed
/// This gives the XP engine the information it needs to calculate bonuses
class CompletionContext {
  final DateTime completionTime;
  final int currentStreak;           // Days in a row this task was completed
  final int perfectWeeksThisMonth;   // Weeks where all instances were completed
  final bool isPartOfChallenge;      // Whether user is in a specific challenge
  final Map<String, dynamic> additionalContext; // For future extensibility
  
  CompletionContext({
    required this.completionTime,
    this.currentStreak = 0,
    this.perfectWeeksThisMonth = 0,
    this.isPartOfChallenge = false,
    this.additionalContext = const {},
  });
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
    
    if (xpBreakdown['streak_bonus'] != null && xpBreakdown['streak_bonus']! > 0) {
      explanations.add('Streak bonus: +${xpBreakdown['streak_bonus']}');
    }
    
    if (xpBreakdown['morning_bonus'] != null && xpBreakdown['morning_bonus']! > 0) {
      explanations.add('Morning completion: +${xpBreakdown['morning_bonus']}');
    }
    
    if (xpBreakdown['perfect_week_bonus'] != null && xpBreakdown['perfect_week_bonus']! > 0) {
      explanations.add('Perfect week bonus: +${xpBreakdown['perfect_week_bonus']}');
    }
    
    return explanations.join(', ');
  }
} 