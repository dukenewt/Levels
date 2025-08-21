/// UI event objects for DailyXP
/// These represent UI actions that should be triggered in response to state changes

/// Types of UI events that can be triggered
enum UiEventType {
  // Celebration events
  taskCompletion,
  levelUp,
  perkUnlock,
  talentUnlock,
  epicCompletion,
  streakMilestone,
  lootBoxOpen,
  
  // Navigation events
  showTalentDialog,
  showPerkDialog,
  showEpicDialog,
  navigateToProfile,
  navigateToEpics,
  
  // Notification events
  showSnackbar,
  showToast,
  showBottomSheet,
  showDialog,
  
  // Animation events
  playAnimation,
  startSequence,
  
  // Feedback events
  hapticFeedback,
  soundEffect,
  
  // State refresh events
  refreshTasks,
  refreshProfile,
  refreshEpics;
  
  String get id => name;
}

/// Priority levels for UI events
enum UiEventPriority {
  low,      // Can be skipped if system is busy
  normal,   // Standard priority
  high,     // Should interrupt lower priority events
  critical; // Must be shown immediately
  
  String get id => name;
}

/// Base UI event class
abstract class UiEvent {
  final String id;
  final UiEventType type;
  final UiEventPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final Duration? delay;
  final bool reducedMotionFallback;
  
  const UiEvent({
    required this.id,
    required this.type,
    this.priority = UiEventPriority.normal,
    required this.timestamp,
    this.data = const {},
    this.delay,
    this.reducedMotionFallback = true,
  });
  
  /// Whether this event should be shown in reduced motion mode
  bool get showInReducedMotion => reducedMotionFallback;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.id,
      'priority': priority.id,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'delay': delay?.inMilliseconds,
      'reducedMotionFallback': reducedMotionFallback,
    };
  }
}

/// Celebration events for achievements and milestones
class CelebrationEvent extends UiEvent {
  final String title;
  final String message;
  final String? iconPath;
  final Duration duration;
  final List<String> animations;
  
  const CelebrationEvent({
    required super.id,
    required super.type,
    super.priority = UiEventPriority.high,
    required super.timestamp,
    required this.title,
    required this.message,
    this.iconPath,
    this.duration = const Duration(seconds: 3),
    this.animations = const [],
    super.data = const {},
    super.delay,
    super.reducedMotionFallback = true,
  });
  
  factory CelebrationEvent.taskCompletion({
    required String taskTitle,
    required int xpGained,
    List<String>? perkBonuses,
    bool hasLootBox = false,
  }) {
    final id = 'task_completion_${DateTime.now().millisecondsSinceEpoch}';
    final animations = hasLootBox 
        ? ['checkmark', 'xp_burst', 'loot_box_reveal']
        : ['checkmark', 'xp_burst'];
    
    return CelebrationEvent(
      id: id,
      type: UiEventType.taskCompletion,
      timestamp: DateTime.now(),
      title: 'Task Completed!',
      message: '$taskTitle\n+$xpGained XP' + 
               (perkBonuses?.isNotEmpty == true ? '\n${perkBonuses!.join(', ')}' : ''),
      animations: animations,
      data: {
        'task_title': taskTitle,
        'xp_gained': xpGained,
        'perk_bonuses': perkBonuses,
        'has_loot_box': hasLootBox,
      },
    );
  }
  
  factory CelebrationEvent.levelUp({
    required int newLevel,
    List<String>? newPerks,
    bool needsTalentChoice = false,
  }) {
    final id = 'level_up_${newLevel}_${DateTime.now().millisecondsSinceEpoch}';
    
    return CelebrationEvent(
      id: id,
      type: UiEventType.levelUp,
      priority: UiEventPriority.critical,
      timestamp: DateTime.now(),
      title: 'Level Up!',
      message: 'Congratulations! You reached level $newLevel',
      iconPath: 'assets/icons/level_up.png',
      animations: ['level_up_burst', 'confetti'],
      data: {
        'new_level': newLevel,
        'new_perks': newPerks,
        'needs_talent_choice': needsTalentChoice,
      },
    );
  }
  
  factory CelebrationEvent.epicCompletion({
    required String epicTitle,
    List<String>? rewardsUnlocked,
  }) {
    final id = 'epic_completion_${DateTime.now().millisecondsSinceEpoch}';
    
    return CelebrationEvent(
      id: id,
      type: UiEventType.epicCompletion,
      priority: UiEventPriority.critical,
      timestamp: DateTime.now(),
      title: 'Epic Completed!',
      message: '$epicTitle\n${rewardsUnlocked?.join(', ') ?? 'Great work!'}',
      iconPath: 'assets/icons/epic_complete.png',
      animations: ['epic_burst', 'reward_reveal', 'confetti'],
      duration: const Duration(seconds: 5),
      data: {
        'epic_title': epicTitle,
        'rewards_unlocked': rewardsUnlocked,
      },
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'title': title,
      'message': message,
      'iconPath': iconPath,
      'duration': duration.inMilliseconds,
      'animations': animations,
    });
    return json;
  }
}

/// Dialog events for user interaction
class DialogEvent extends UiEvent {
  final String title;
  final String? message;
  final List<DialogAction> actions;
  final bool dismissible;
  final String? contentWidget;
  
  const DialogEvent({
    required super.id,
    required super.type,
    super.priority = UiEventPriority.normal,
    required super.timestamp,
    required this.title,
    this.message,
    this.actions = const [],
    this.dismissible = true,
    this.contentWidget,
    super.data = const {},
    super.delay,
    super.reducedMotionFallback = true,
  });
  
  factory DialogEvent.talentChoice({
    required int level,
    required List<Map<String, dynamic>> talentOptions,
  }) {
    final id = 'talent_choice_${level}_${DateTime.now().millisecondsSinceEpoch}';
    
    return DialogEvent(
      id: id,
      type: UiEventType.showTalentDialog,
      priority: UiEventPriority.critical,
      timestamp: DateTime.now(),
      title: 'Choose Your Talent!',
      message: 'You\'ve reached level $level. Choose your specialization:',
      dismissible: false,
      contentWidget: 'TalentSelectionWidget',
      data: {
        'level': level,
        'talent_options': talentOptions,
      },
    );
  }
  
  factory DialogEvent.perkUnlock({
    required String perkName,
    required String perkDescription,
  }) {
    final id = 'perk_unlock_${DateTime.now().millisecondsSinceEpoch}';
    
    return DialogEvent(
      id: id,
      type: UiEventType.showPerkDialog,
      priority: UiEventPriority.high,
      timestamp: DateTime.now(),
      title: 'New Perk Unlocked!',
      message: '$perkName\n$perkDescription',
      actions: [DialogAction.ok()],
      contentWidget: 'PerkUnlockWidget',
      data: {
        'perk_name': perkName,
        'perk_description': perkDescription,
      },
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'title': title,
      'message': message,
      'actions': actions.map((a) => a.toJson()).toList(),
      'dismissible': dismissible,
      'contentWidget': contentWidget,
    });
    return json;
  }
}

/// Action buttons for dialogs
class DialogAction {
  final String id;
  final String text;
  final bool isPrimary;
  final bool isDestructive;
  final Map<String, dynamic> data;
  
  const DialogAction({
    required this.id,
    required this.text,
    this.isPrimary = false,
    this.isDestructive = false,
    this.data = const {},
  });
  
  factory DialogAction.ok() {
    return const DialogAction(id: 'ok', text: 'OK', isPrimary: true);
  }
  
  factory DialogAction.cancel() {
    return const DialogAction(id: 'cancel', text: 'Cancel');
  }
  
  factory DialogAction.confirm() {
    return const DialogAction(id: 'confirm', text: 'Confirm', isPrimary: true);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isPrimary': isPrimary,
      'isDestructive': isDestructive,
      'data': data,
    };
  }
}

/// Notification events for snackbars, toasts, etc.
class NotificationEvent extends UiEvent {
  final String message;
  final String? actionLabel;
  final String? actionId;
  final Duration duration;
  final String? iconPath;
  
  const NotificationEvent({
    required super.id,
    required super.type,
    super.priority = UiEventPriority.normal,
    required super.timestamp,
    required this.message,
    this.actionLabel,
    this.actionId,
    this.duration = const Duration(seconds: 4),
    this.iconPath,
    super.data = const {},
    super.delay,
    super.reducedMotionFallback = true,
  });
  
  factory NotificationEvent.snackbar({
    required String message,
    String? actionLabel,
    String? actionId,
    Duration duration = const Duration(seconds: 4),
  }) {
    final id = 'snackbar_${DateTime.now().millisecondsSinceEpoch}';
    
    return NotificationEvent(
      id: id,
      type: UiEventType.showSnackbar,
      timestamp: DateTime.now(),
      message: message,
      actionLabel: actionLabel,
      actionId: actionId,
      duration: duration,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'message': message,
      'actionLabel': actionLabel,
      'actionId': actionId,
      'duration': duration.inMilliseconds,
      'iconPath': iconPath,
    });
    return json;
  }
}

/// Animation events for triggering specific animations
class AnimationEvent extends UiEvent {
  final String animationName;
  final String? targetWidget;
  final Duration duration;
  final Map<String, dynamic> parameters;
  
  const AnimationEvent({
    required super.id,
    required super.type,
    super.priority = UiEventPriority.normal,
    required super.timestamp,
    required this.animationName,
    this.targetWidget,
    this.duration = const Duration(milliseconds: 500),
    this.parameters = const {},
    super.data = const {},
    super.delay,
    super.reducedMotionFallback = false,
  });
  
  factory AnimationEvent.playAnimation({
    required String animationName,
    String? targetWidget,
    Duration duration = const Duration(milliseconds: 500),
    Map<String, dynamic> parameters = const {},
  }) {
    final id = 'animation_${animationName}_${DateTime.now().millisecondsSinceEpoch}';
    
    return AnimationEvent(
      id: id,
      type: UiEventType.playAnimation,
      timestamp: DateTime.now(),
      animationName: animationName,
      targetWidget: targetWidget,
      duration: duration,
      parameters: parameters,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'animationName': animationName,
      'targetWidget': targetWidget,
      'duration': duration.inMilliseconds,
      'parameters': parameters,
    });
    return json;
  }
}

/// Collection of UI events to be processed
class UiEventBatch {
  final List<UiEvent> events;
  final String batchId;
  final DateTime timestamp;
  final bool sequential; // Whether events should be played sequentially or concurrently
  
  const UiEventBatch({
    required this.events,
    required this.batchId,
    required this.timestamp,
    this.sequential = false,
  });
  
  factory UiEventBatch.sequential({
    required List<UiEvent> events,
    String? batchId,
  }) {
    return UiEventBatch(
      events: events,
      batchId: batchId ?? 'batch_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      sequential: true,
    );
  }
  
  factory UiEventBatch.concurrent({
    required List<UiEvent> events,
    String? batchId,
  }) {
    return UiEventBatch(
      events: events,
      batchId: batchId ?? 'batch_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      sequential: false,
    );
  }
  
  /// Filter events based on reduced motion setting
  UiEventBatch filterForReducedMotion(bool reducedMotionEnabled) {
    if (!reducedMotionEnabled) return this;
    
    final filteredEvents = events
        .where((event) => event.showInReducedMotion)
        .toList();
    
    return UiEventBatch(
      events: filteredEvents,
      batchId: batchId,
      timestamp: timestamp,
      sequential: sequential,
    );
  }
  
  /// Sort events by priority
  UiEventBatch sortByPriority() {
    final sortedEvents = [...events];
    sortedEvents.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    
    return UiEventBatch(
      events: sortedEvents,
      batchId: batchId,
      timestamp: timestamp,
      sequential: sequential,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
      'batchId': batchId,
      'timestamp': timestamp.toIso8601String(),
      'sequential': sequential,
    };
  }
}

/// Result of processing UI events
class UiEventResult {
  final String eventId;
  final bool success;
  final String? error;
  final Map<String, dynamic>? resultData;
  final DateTime completedAt;
  
  const UiEventResult({
    required this.eventId,
    required this.success,
    this.error,
    this.resultData,
    required this.completedAt,
  });
  
  factory UiEventResult.success({
    required String eventId,
    Map<String, dynamic>? resultData,
  }) {
    return UiEventResult(
      eventId: eventId,
      success: true,
      resultData: resultData,
      completedAt: DateTime.now(),
    );
  }
  
  factory UiEventResult.failure({
    required String eventId,
    required String error,
  }) {
    return UiEventResult(
      eventId: eventId,
      success: false,
      error: error,
      completedAt: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'success': success,
      'error': error,
      'resultData': resultData,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}