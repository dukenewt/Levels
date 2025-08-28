/// State change objects for TaskBound
/// These represent atomic changes to application state

/// Represents a change to user data
class UserStateDelta {
  final int? xpChange;
  final int? levelChange;
  final List<String>? newPerks;
  final List<String>? newTalents;
  final Map<String, dynamic>? additionalChanges;

  const UserStateDelta({
    this.xpChange,
    this.levelChange,
    this.newPerks,
    this.newTalents,
    this.additionalChanges,
  });

  bool get hasChanges =>
      xpChange != null ||
      levelChange != null ||
      (newPerks?.isNotEmpty ?? false) ||
      (newTalents?.isNotEmpty ?? false) ||
      (additionalChanges?.isNotEmpty ?? false);

  UserStateDelta copyWith({
    int? xpChange,
    int? levelChange,
    List<String>? newPerks,
    List<String>? newTalents,
    Map<String, dynamic>? additionalChanges,
  }) {
    return UserStateDelta(
      xpChange: xpChange ?? this.xpChange,
      levelChange: levelChange ?? this.levelChange,
      newPerks: newPerks ?? this.newPerks,
      newTalents: newTalents ?? this.newTalents,
      additionalChanges: additionalChanges ?? this.additionalChanges,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xpChange': xpChange,
      'levelChange': levelChange,
      'newPerks': newPerks,
      'newTalents': newTalents,
      'additionalChanges': additionalChanges,
    };
  }
}

/// Represents a change to task data
class TaskStateDelta {
  final String taskId;
  final bool? completed;
  final DateTime? completedAt;
  final int? xpAwarded;
  final List<String>? epicProgressUpdates;
  final Map<String, dynamic>? additionalChanges;

  const TaskStateDelta({
    required this.taskId,
    this.completed,
    this.completedAt,
    this.xpAwarded,
    this.epicProgressUpdates,
    this.additionalChanges,
  });

  bool get hasChanges =>
      completed != null ||
      completedAt != null ||
      xpAwarded != null ||
      (epicProgressUpdates?.isNotEmpty ?? false) ||
      (additionalChanges?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'xpAwarded': xpAwarded,
      'epicProgressUpdates': epicProgressUpdates,
      'additionalChanges': additionalChanges,
    };
  }
}

/// Represents a change to epic project data
class EpicStateDelta {
  final String? epicId;
  final int? progressChange;
  final bool? completed;
  final List<String>? rewardsUnlocked;
  final Map<String, dynamic>? additionalChanges;

  const EpicStateDelta({
    this.epicId,
    this.progressChange,
    this.completed,
    this.rewardsUnlocked,
    this.additionalChanges,
  });

  bool get hasChanges =>
      epicId != null ||
      progressChange != null ||
      completed != null ||
      (rewardsUnlocked?.isNotEmpty ?? false) ||
      (additionalChanges?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() {
    return {
      'epicId': epicId,
      'progressChange': progressChange,
      'completed': completed,
      'rewardsUnlocked': rewardsUnlocked,
      'additionalChanges': additionalChanges,
    };
  }
}

/// Represents notification changes
class NotificationStateDelta {
  final List<String>? scheduledNotifications;
  final List<String>? cancelledNotifications;
  final Map<String, dynamic>? notificationData;

  const NotificationStateDelta({
    this.scheduledNotifications,
    this.cancelledNotifications,
    this.notificationData,
  });

  bool get hasChanges =>
      (scheduledNotifications?.isNotEmpty ?? false) ||
      (cancelledNotifications?.isNotEmpty ?? false) ||
      (notificationData?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() {
    return {
      'scheduledNotifications': scheduledNotifications,
      'cancelledNotifications': cancelledNotifications,
      'notificationData': notificationData,
    };
  }
}

/// Consolidated state delta representing all changes from an operation
class StateDelta {
  final UserStateDelta? user;
  final List<TaskStateDelta>? tasks;
  final List<EpicStateDelta>? epics;
  final NotificationStateDelta? notifications;
  final DateTime timestamp;
  final String operation; // What caused these changes
  final Map<String, dynamic>? metadata;

  const StateDelta({
    this.user,
    this.tasks,
    this.epics,
    this.notifications,
    required this.timestamp,
    required this.operation,
    this.metadata,
  });

  factory StateDelta.empty(String operation) {
    return StateDelta(
      timestamp: DateTime.now(),
      operation: operation,
    );
  }

  factory StateDelta.taskCompletion({
    required String taskId,
    required int xpAwarded,
    int? xpChange,
    int? levelChange,
    List<String>? newPerks,
    List<String>? epicProgressUpdates,
    List<String>? rewardsUnlocked,
    Map<String, dynamic>? metadata,
  }) {
    return StateDelta(
      user: UserStateDelta(
        xpChange: xpChange,
        levelChange: levelChange,
        newPerks: newPerks,
      ),
      tasks: [
        TaskStateDelta(
          taskId: taskId,
          completed: true,
          completedAt: DateTime.now(),
          xpAwarded: xpAwarded,
          epicProgressUpdates: epicProgressUpdates,
        )
      ],
      epics: rewardsUnlocked?.isNotEmpty == true
          ? [
              EpicStateDelta(
                rewardsUnlocked: rewardsUnlocked,
              )
            ]
          : null,
      timestamp: DateTime.now(),
      operation: 'task_completion',
      metadata: metadata,
    );
  }

  bool get hasChanges =>
      (user?.hasChanges ?? false) ||
      (tasks?.any((t) => t.hasChanges) ?? false) ||
      (epics?.any((e) => e.hasChanges) ?? false) ||
      (notifications?.hasChanges ?? false);

  /// Merge multiple deltas into one
  static StateDelta merge(List<StateDelta> deltas, String operation) {
    if (deltas.isEmpty) return StateDelta.empty(operation);
    if (deltas.length == 1) return deltas.first;

    // Merge user changes
    UserStateDelta? mergedUser;
    int totalXpChange = 0;
    int totalLevelChange = 0;
    List<String> allNewPerks = [];
    List<String> allNewTalents = [];
    Map<String, dynamic> allUserChanges = {};

    for (final delta in deltas) {
      if (delta.user != null) {
        totalXpChange += delta.user!.xpChange ?? 0;
        totalLevelChange += delta.user!.levelChange ?? 0;
        if (delta.user!.newPerks != null) {
          allNewPerks.addAll(delta.user!.newPerks!);
        }
        if (delta.user!.newTalents != null) {
          allNewTalents.addAll(delta.user!.newTalents!);
        }
        if (delta.user!.additionalChanges != null) {
          allUserChanges.addAll(delta.user!.additionalChanges!);
        }
      }
    }

    if (totalXpChange != 0 ||
        totalLevelChange != 0 ||
        allNewPerks.isNotEmpty ||
        allNewTalents.isNotEmpty ||
        allUserChanges.isNotEmpty) {
      mergedUser = UserStateDelta(
        xpChange: totalXpChange != 0 ? totalXpChange : null,
        levelChange: totalLevelChange != 0 ? totalLevelChange : null,
        newPerks: allNewPerks.isNotEmpty ? allNewPerks : null,
        newTalents: allNewTalents.isNotEmpty ? allNewTalents : null,
        additionalChanges: allUserChanges.isNotEmpty ? allUserChanges : null,
      );
    }

    // Merge task changes
    List<TaskStateDelta> allTasks = [];
    for (final delta in deltas) {
      if (delta.tasks != null) {
        allTasks.addAll(delta.tasks!);
      }
    }

    // Merge epic changes
    List<EpicStateDelta> allEpics = [];
    for (final delta in deltas) {
      if (delta.epics != null) {
        allEpics.addAll(delta.epics!);
      }
    }

    // Merge notification changes
    NotificationStateDelta? mergedNotifications;
    List<String> allScheduled = [];
    List<String> allCancelled = [];
    Map<String, dynamic> allNotificationData = {};

    for (final delta in deltas) {
      if (delta.notifications != null) {
        if (delta.notifications!.scheduledNotifications != null) {
          allScheduled.addAll(delta.notifications!.scheduledNotifications!);
        }
        if (delta.notifications!.cancelledNotifications != null) {
          allCancelled.addAll(delta.notifications!.cancelledNotifications!);
        }
        if (delta.notifications!.notificationData != null) {
          allNotificationData.addAll(delta.notifications!.notificationData!);
        }
      }
    }

    if (allScheduled.isNotEmpty ||
        allCancelled.isNotEmpty ||
        allNotificationData.isNotEmpty) {
      mergedNotifications = NotificationStateDelta(
        scheduledNotifications: allScheduled.isNotEmpty ? allScheduled : null,
        cancelledNotifications: allCancelled.isNotEmpty ? allCancelled : null,
        notificationData:
            allNotificationData.isNotEmpty ? allNotificationData : null,
      );
    }

    return StateDelta(
      user: mergedUser,
      tasks: allTasks.isNotEmpty ? allTasks : null,
      epics: allEpics.isNotEmpty ? allEpics : null,
      notifications: mergedNotifications,
      timestamp: DateTime.now(),
      operation: operation,
      metadata: {
        'merged_from': deltas.map((d) => d.operation).toList(),
        'merged_count': deltas.length,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'tasks': tasks?.map((t) => t.toJson()).toList(),
      'epics': epics?.map((e) => e.toJson()).toList(),
      'notifications': notifications?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'operation': operation,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'StateDelta(operation: $operation, hasChanges: $hasChanges, timestamp: $timestamp)';
  }
}
