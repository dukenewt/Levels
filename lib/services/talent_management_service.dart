import '../models/user.dart';
import '../models/user_talent.dart';
import '../models/epic_project.dart';
import '../models/task.dart';

/// Result of talent selection operation
class TalentSelectionResult {
  final bool success;
  final String? errorMessage;
  final UserTalent? selectedTalent;
  final User? updatedUser;

  const TalentSelectionResult({
    required this.success,
    this.errorMessage,
    this.selectedTalent,
    this.updatedUser,
  });

  factory TalentSelectionResult.success(UserTalent talent, User user) {
    return TalentSelectionResult(
      success: true,
      selectedTalent: talent,
      updatedUser: user,
    );
  }

  factory TalentSelectionResult.error(String message) {
    return TalentSelectionResult(
      success: false,
      errorMessage: message,
    );
  }
}

/// Service for managing talent system and epic projects
class TalentManagementService {
  /// Check if user needs to make a talent choice
  static bool needsTalentChoice(User user) {
    return user.needsTalentChoice();
  }

  /// Get the next talent choice that needs to be made
  static TalentChoice? getNextTalentChoice(User user) {
    final pendingLevels = user.getPendingTalentLevels();
    if (pendingLevels.isEmpty) return null;

    // Get the lowest level that needs a choice
    final nextLevel = pendingLevels.reduce((a, b) => a < b ? a : b);
    return UserTalents.getTalentChoice(nextLevel);
  }

  /// Select a talent for the user
  static TalentSelectionResult selectTalent(
    User user,
    String talentId,
    int level,
  ) {
    // Validate that this is a valid talent choice
    final talentChoice = UserTalents.getTalentChoice(level);
    if (talentChoice.options.isEmpty) {
      return TalentSelectionResult.error(
          'No talent choice available for level $level');
    }

    // Find the selected talent in the available options
    final selectedTalent = talentChoice.options
        .where((talent) => talent.id == talentId)
        .firstOrNull;

    if (selectedTalent == null) {
      return TalentSelectionResult.error('Invalid talent selection');
    }

    // Check if user is eligible for this choice
    if (user.level < level) {
      return TalentSelectionResult.error('User level too low for this talent');
    }

    if (user.talentChoices.containsKey(level)) {
      return TalentSelectionResult.error(
          'Talent already chosen for level $level');
    }

    // Update user with new talent
    final updatedTalentChoices = Map<int, String>.from(user.talentChoices);
    updatedTalentChoices[level] = talentId;

    final updatedTalents = List<String>.from(user.talents);
    if (!updatedTalents.contains(talentId)) {
      updatedTalents.add(talentId);
    }

    final updatedUser = user.copyWith(
      talents: updatedTalents,
      talentChoices: updatedTalentChoices,
    );

    return TalentSelectionResult.success(selectedTalent, updatedUser);
  }

  /// Get all talent choices made by user
  static List<UserTalent> getUserTalents(User user) {
    List<UserTalent> talents = [];

    for (final talentId in user.talents) {
      // Find talent in predefined talents
      final talent = _findTalentById(talentId);
      if (talent != null) {
        talents.add(talent.copyWith(isUnlocked: true));
      }
    }

    return talents;
  }

  /// Check if user can create epic projects
  static bool canCreateEpicProjects(User user) {
    return user.hasProjectManagementTalent();
  }

  /// Create a new epic project
  static EpicProject createEpicProject({
    required String title,
    required String description,
    required String userId,
    required List<String> taskIds,
    DateTime? dueDate,
  }) {
    // Generate a random reward for the epic
    final reward = EpicRewards.getRandomReward();

    return EpicProject(
      title: title,
      description: description,
      userId: userId,
      taskIds: taskIds,
      requiredTasks: taskIds.length,
      reward: reward,
      dueDate: dueDate,
    );
  }

  /// Update epic project progress when a task is completed
  static EpicProject? updateEpicProgress(
    EpicProject epic,
    String completedTaskId,
  ) {
    if (!epic.taskIds.contains(completedTaskId)) {
      return null; // Task not part of this epic
    }

    final newCompletedTasks = epic.completedTasks + 1;
    var newStatus = epic.status;

    // Check if epic is completed
    if (newCompletedTasks >= epic.requiredTasks &&
        epic.status == EpicStatus.active) {
      newStatus = EpicStatus.completed;
    }

    return epic.copyWith(
      completedTasks: newCompletedTasks,
      status: newStatus,
      completedAt: newStatus == EpicStatus.completed ? DateTime.now() : null,
    );
  }

  /// Start an epic project
  static EpicProject startEpic(EpicProject epic) {
    if (!epic.canStart) {
      return epic;
    }

    return epic.copyWith(
      status: EpicStatus.active,
      startedAt: DateTime.now(),
    );
  }

  /// Get talent tree visualization data
  static Map<String, dynamic> getTalentTreeData(User user) {
    Map<String, dynamic> treeData = {};

    for (final level in UserTalents.talentLevels) {
      final choice = UserTalents.getTalentChoice(level);
      final selectedTalentId = user.talentChoices[level];

      treeData['level_$level'] = {
        'level': level,
        'isUnlocked': user.level >= level,
        'hasChoice': choice.options.isNotEmpty,
        'options': choice.options
            .map((talent) => {
                  'id': talent.id,
                  'name': talent.name,
                  'description': talent.description,
                  'type': talent.type.displayName,
                  'isSelected': talent.id == selectedTalentId,
                })
            .toList(),
        'selectedTalent': selectedTalentId,
        'needsChoice': user.level >= level && selectedTalentId == null,
      };
    }

    return treeData;
  }

  /// Get talent path summary for a user
  static Map<String, dynamic> getTalentPathSummary(User user) {
    int projectManagementTalents = 0;
    int nlpTalents = 0;

    for (final talentId in user.talents) {
      if (talentId.startsWith('project_management') ||
          talentId.startsWith('project_mgmt')) {
        projectManagementTalents++;
      } else if (talentId.startsWith('nlp_categorization') ||
          talentId.startsWith('nlp_advanced') ||
          talentId.startsWith('nlp')) {
        nlpTalents++;
      }
    }

    return {
      'projectManagement': {
        'count': projectManagementTalents,
        'hasPath': projectManagementTalents > 0,
        'features': projectManagementTalents > 0
            ? [
                'Epic Difficulty Tasks',
                'Multi-Task Projects',
                'Unique Theme Rewards',
              ]
            : [],
      },
      'nlpCategorization': {
        'count': nlpTalents,
        'hasPath': nlpTalents > 0,
        'features': nlpTalents > 0
            ? [
                'Auto Task Categorization',
                'Keyword Analysis',
              ]
            : [],
      },
      'totalTalents': user.talents.length,
      'availableChoices': user.getPendingTalentLevels().length,
    };
  }

  /// Get requirements for next talent unlock
  static Map<String, dynamic>? getNextTalentRequirement(User user) {
    final nextTalentLevel = UserTalents.talentLevels
        .where((level) => level > user.level)
        .firstOrNull;

    if (nextTalentLevel == null) return null;

    final xpNeeded = (nextTalentLevel * 100) - user.currentXp;

    return {
      'level': nextTalentLevel,
      'xpNeeded': xpNeeded > 0 ? xpNeeded : 0,
      'isReady': user.level >= nextTalentLevel,
    };
  }

  /// Check if talent affects task creation options
  static Map<String, dynamic> getTalentEffectsForTask(User user, Task task) {
    Map<String, dynamic> effects = {
      'canUseEpicDifficulty': user.hasProjectManagementTalent(),
      'hasAutoCategoriztion': user.hasNLPTalent(),
      'availableDifficulties': [],
      'suggestedCategory': null,
    };

    // Add available difficulties
    effects['availableDifficulties'] = [
      'easy',
      'medium',
      'hard',
      if (user.hasProjectManagementTalent()) 'epic',
    ];

    return effects;
  }

  /// Helper method to find talent by ID
  static UserTalent? _findTalentById(String talentId) {
    // Check all predefined talents
    for (final level in UserTalents.talentLevels) {
      final choice = UserTalents.getTalentChoice(level);
      for (final talent in choice.options) {
        if (talent.id == talentId) {
          return talent;
        }
      }
    }
    return null;
  }

  /// Get epic projects for a user
  static List<EpicProject> getEpicProjectsForUser(
      String userId, List<EpicProject> allEpics) {
    return allEpics.where((epic) => epic.userId == userId).toList();
  }

  /// Check if task is part of any epic project
  static EpicProject? findEpicForTask(String taskId, List<EpicProject> epics) {
    return epics.where((epic) => epic.taskIds.contains(taskId)).firstOrNull;
  }

  /// Validate epic project creation
  static String? validateEpicCreation({
    required String title,
    required List<String> taskIds,
    required User user,
  }) {
    if (!user.hasProjectManagementTalent()) {
      return 'Project Management talent required to create Epic projects';
    }

    if (title.trim().isEmpty) {
      return 'Epic project title cannot be empty';
    }

    if (taskIds.isEmpty) {
      return 'Epic project must have at least one task';
    }

    // Recommended to have ≥3 tasks, but allow creation

    return null; // No validation errors
  }
}
