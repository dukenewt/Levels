class TaskAnalyzerService {
  // Keyword mappings for difficulty suggestion
  static const Map<String, String> difficultyKeywords = {
    // Easy Keywords (often quick, simple actions)
    'call': 'easy',
    'email': 'easy',
    'text': 'easy',
    'message': 'easy',
    'buy': 'easy',
    'purchase': 'easy',
    'schedule': 'easy',
    'plan': 'easy',
    'tidy': 'easy',
    'organize': 'easy',
    'water plants': 'easy',
    'check': 'easy',
    'review': 'easy',
    'quick': 'easy',

    // Medium Keywords (require more sustained effort or focus)
    'read': 'medium',
    'write': 'medium',
    'draft': 'medium',
    'laundry': 'medium',
    'dishes': 'medium',
    'cook': 'medium',
    'prepare': 'medium',
    'clean': 'medium',
    'practice': 'medium',
    'learn': 'medium',
    'research': 'medium',

    // Hard Keywords (often require significant physical or mental energy)
    'gym': 'hard',
    'workout': 'hard',
    'exercise': 'hard',
    'study': 'hard',
    'analyze': 'hard',
    'develop': 'hard',
    'create': 'hard',
    'design': 'hard',
    'presentation': 'hard',
    'report': 'hard',
    'deep': 'hard',

    // Epic Keywords (major, multi-hour commitments) - only available with Project Management talent
    'build': 'epic',
    'complete project': 'epic',
    'finish project': 'epic',
    'deep clean': 'epic',
    'renovate': 'epic',
    'overhaul': 'epic',
  };

  // Keyword mappings for category suggestion
  static const Map<String, String> categoryKeywords = {
    // Health keywords
    'workout': 'Health',
    'exercise': 'Health',
    'gym': 'Health',
    'run': 'Health',
    'jog': 'Health',
    'walk': 'Health',
    'stretch': 'Health',
    'yoga': 'Health',
    'meditation': 'Health',
    'doctor': 'Health',
    'appointment': 'Health',
    'medicine': 'Health',
    'vitamins': 'Health',
    'sleep': 'Health',
    'diet': 'Health',
    'healthy': 'Health',

    // Learning keywords
    'study': 'Learning',
    'read': 'Learning',
    'book': 'Learning',
    'learn': 'Learning',
    'course': 'Learning',
    'tutorial': 'Learning',
    'practice': 'Learning',
    'research': 'Learning',
    'homework': 'Learning',
    'exam': 'Learning',
    'review': 'Learning',
    'notes': 'Learning',

    // Work keywords
    'meeting': 'Work',
    'presentation': 'Work',
    'project': 'Work',
    'report': 'Work',
    'email': 'Work',
    'work call': 'Work',
    'deadline': 'Work',
    'client': 'Work',
    'office': 'Work',
    'analyze': 'Work',
    'develop': 'Work',
    'code': 'Work',
    'web design': 'Work',

    // Social keywords
    'friend': 'Social',
    'family': 'Social',
    'call': 'Social',
    'text': 'Social',
    'message': 'Social',
    'party': 'Social',
    'dinner': 'Social',
    'lunch': 'Social',
    'hangout': 'Social',
    'visit': 'Social',

    // Personal keywords
    'clean': 'Personal',
    'organize': 'Personal',
    'tidy': 'Personal',
    'laundry': 'Personal',
    'dishes': 'Personal',
    'cook': 'Personal',
    'grocery': 'Personal',
    'shopping': 'Personal',
    'buy': 'Personal',
    'pay': 'Personal',
    'bills': 'Personal',

    // Creative keywords
    'draw': 'Creative',
    'paint': 'Creative',
    'write': 'Creative',
    'music': 'Creative',
    'photo': 'Creative',
    'create': 'Creative',
    'design': 'Creative',
    'art': 'Creative',
  };

  /// Suggests difficulty based on task title using keyword analysis
  static String suggestDifficulty(String taskTitle,
      {bool hasProjectManagementTalent = false}) {
    final title = taskTitle.toLowerCase();

    // Check for epic keywords only if user has Project Management talent
    if (hasProjectManagementTalent) {
      for (var entry in difficultyKeywords.entries) {
        if (entry.value == 'epic' && title.contains(entry.key)) {
          return 'epic';
        }
      }
    }

    // Check other difficulties (prioritize longer phrases first)
    final sortedEntries = difficultyKeywords.entries
        .where((entry) => entry.value != 'epic')
        .toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (var entry in sortedEntries) {
      if (title.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default to medium if no keywords are found
    return 'medium';
  }

  /// Suggests category based on task title using keyword analysis
  static String? suggestCategory(String taskTitle,
      {bool hasNLPTalent = false}) {
    if (!hasNLPTalent) return null;

    final title = taskTitle.toLowerCase();

    // Prioritize longer, more specific phrases first
    final sortedEntries = categoryKeywords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (var entry in sortedEntries) {
      if (title.contains(entry.key)) {
        return entry.value;
      }
    }

    return null; // No category suggestion
  }

  /// Comprehensive task analysis that returns both difficulty and category suggestions
  static TaskAnalysis analyzeTask(
    String taskTitle, {
    bool hasProjectManagementTalent = false,
    bool hasNLPTalent = false,
  }) {
    return TaskAnalysis(
      suggestedDifficulty: suggestDifficulty(
        taskTitle,
        hasProjectManagementTalent: hasProjectManagementTalent,
      ),
      suggestedCategory: suggestCategory(
        taskTitle,
        hasNLPTalent: hasNLPTalent,
      ),
      confidence: _calculateConfidence(taskTitle),
    );
  }

  /// Calculate confidence score based on keyword matches
  static double _calculateConfidence(String taskTitle) {
    final title = taskTitle.toLowerCase();
    int matches = 0;
    int totalKeywords = difficultyKeywords.length + categoryKeywords.length;

    // Count keyword matches
    for (var keyword in difficultyKeywords.keys) {
      if (title.contains(keyword)) matches++;
    }
    for (var keyword in categoryKeywords.keys) {
      if (title.contains(keyword)) matches++;
    }

    // Return confidence as a percentage (0.0 to 1.0)
    return matches > 0 ? (matches / totalKeywords).clamp(0.0, 1.0) : 0.0;
  }

  /// Get all available categories
  static List<String> get availableCategories => [
        'Health',
        'Learning',
        'Work',
        'Social',
        'Personal',
        'Creative',
      ];

  /// Check if a keyword exists for a specific category
  static bool hasKeywordForCategory(String taskTitle, String category) {
    final title = taskTitle.toLowerCase();
    return categoryKeywords.entries
        .where((entry) => entry.value == category)
        .any((entry) => title.contains(entry.key));
  }
}

class TaskAnalysis {
  final String suggestedDifficulty;
  final String? suggestedCategory;
  final double confidence;

  const TaskAnalysis({
    required this.suggestedDifficulty,
    this.suggestedCategory,
    required this.confidence,
  });

  bool get hasCategorySuggestion => suggestedCategory != null;
  bool get isHighConfidence => confidence > 0.3;

  @override
  String toString() {
    return 'TaskAnalysis(difficulty: $suggestedDifficulty, category: $suggestedCategory, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
