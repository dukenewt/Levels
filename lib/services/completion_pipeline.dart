/// Completion Pipeline Service
/// Orchestrates the full task completion flow: analyze → compute → persist → emit events

import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/state_delta.dart';
import '../models/ui_event.dart';
import '../models/effect.dart';
import '../features/character_progression/domain/completion_context.dart';
import '../services/pure_effect_engine.dart';
import '../providers/user_provider_refactored.dart';
import '../controllers/talent_perk_controller.dart';
import '../features/character_progression/application/intelligent_xp_engine.dart'
    as xp;

/// Result of the completion pipeline execution
class PipelineExecutionResult {
  final bool success;
  final StateDelta? stateDelta;
  final UiEventBatch? uiEvents;
  final XPCalculationBreakdown? xpBreakdown;
  final String? error;
  final Duration executionTime;
  final Map<String, dynamic>? debugInfo;

  const PipelineExecutionResult({
    required this.success,
    this.stateDelta,
    this.uiEvents,
    this.xpBreakdown,
    this.error,
    required this.executionTime,
    this.debugInfo,
  });

  factory PipelineExecutionResult.success({
    required StateDelta stateDelta,
    required UiEventBatch uiEvents,
    required XPCalculationBreakdown xpBreakdown,
    required Duration executionTime,
    Map<String, dynamic>? debugInfo,
  }) {
    return PipelineExecutionResult(
      success: true,
      stateDelta: stateDelta,
      uiEvents: uiEvents,
      xpBreakdown: xpBreakdown,
      executionTime: executionTime,
      debugInfo: debugInfo,
    );
  }

  factory PipelineExecutionResult.failure({
    required String error,
    required Duration executionTime,
    Map<String, dynamic>? debugInfo,
  }) {
    return PipelineExecutionResult(
      success: false,
      error: error,
      executionTime: executionTime,
      debugInfo: debugInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'stateDelta': stateDelta?.toJson(),
      'uiEvents': uiEvents?.toJson(),
      'xpBreakdown': xpBreakdown?.toJson(),
      'error': error,
      'executionTime': executionTime.inMilliseconds,
      'debugInfo': debugInfo,
    };
  }
}

/// Settings for pipeline execution
class PipelineSettings {
  final bool enableAnimations;
  final bool enableNotifications;
  final bool enableHapticFeedback;
  final bool reducedMotion;
  final bool debugMode;
  final Duration maxExecutionTime;

  const PipelineSettings({
    this.enableAnimations = true,
    this.enableNotifications = true,
    this.enableHapticFeedback = true,
    this.reducedMotion = false,
    this.debugMode = false,
    this.maxExecutionTime = const Duration(seconds: 5),
  });

  factory PipelineSettings.fromUserPreferences(
      Map<String, dynamic> preferences) {
    return PipelineSettings(
      enableAnimations: preferences['enableAnimations'] as bool? ?? true,
      enableNotifications: preferences['enableNotifications'] as bool? ?? true,
      enableHapticFeedback:
          preferences['enableHapticFeedback'] as bool? ?? true,
      reducedMotion: preferences['reducedMotion'] as bool? ?? false,
      debugMode: preferences['debugMode'] as bool? ?? false,
    );
  }
}

/// Orchestrates the complete task completion flow
class CompletionPipeline {
  final UserProvider _userProvider;
  final TalentPerkController _talentPerkController;
  final xp.IntelligentXPEngine _xpEngine;

  // Event handlers
  final Function(UiEventBatch)? onUiEvents;
  final Function(String)? onError;
  final Function(Map<String, dynamic>)? onDebugLog;

  CompletionPipeline({
    required UserProvider userProvider,
    required TalentPerkController talentPerkController,
    required xp.IntelligentXPEngine xpEngine,
    this.onUiEvents,
    this.onError,
    this.onDebugLog,
  })  : _userProvider = userProvider,
        _talentPerkController = talentPerkController,
        _xpEngine = xpEngine;

  /// Execute the complete task completion pipeline
  Future<PipelineExecutionResult> executeTaskCompletion({
    required Task task,
    required CompletionContext context,
    PipelineSettings? settings,
  }) async {
    final stopwatch = Stopwatch()..start();
    final pipelineSettings = settings ?? const PipelineSettings();
    final debugInfo = <String, dynamic>{};

    try {
      _debugLog('Starting task completion pipeline', {
        'task_id': task.id,
        'task_title': task.title,
        'category': task.category,
        'difficulty': task.difficulty.name,
      });

      // PHASE 1: ANALYZE
      final analysisResult = await _analyzeCompletion(task, context, debugInfo);
      if (!analysisResult.success) {
        return PipelineExecutionResult.failure(
          error: analysisResult.error!,
          executionTime: stopwatch.elapsed,
          debugInfo: debugInfo,
        );
      }

      // PHASE 2: COMPUTE
      final computationResult = await _computeEffects(
        task,
        context,
        analysisResult.baseXP!,
        analysisResult.hasLootBox!,
        debugInfo,
      );
      if (!computationResult.success) {
        return PipelineExecutionResult.failure(
          error: computationResult.error!,
          executionTime: stopwatch.elapsed,
          debugInfo: debugInfo,
        );
      }

      // PHASE 3: PERSIST
      final persistenceResult = await _persistChanges(
        computationResult.stateDelta!,
        debugInfo,
      );
      if (!persistenceResult.success) {
        return PipelineExecutionResult.failure(
          error: persistenceResult.error!,
          executionTime: stopwatch.elapsed,
          debugInfo: debugInfo,
        );
      }

      // PHASE 4: EMIT EVENTS
      var uiEvents = computationResult.uiEvents!;
      if (pipelineSettings.reducedMotion) {
        uiEvents = uiEvents.filterForReducedMotion(true);
      }

      final emissionResult = await _emitEvents(
        uiEvents,
        pipelineSettings,
        debugInfo,
      );
      if (!emissionResult.success) {
        return PipelineExecutionResult.failure(
          error: emissionResult.error!,
          executionTime: stopwatch.elapsed,
          debugInfo: debugInfo,
        );
      }

      _debugLog('Pipeline execution completed successfully', {
        'execution_time': stopwatch.elapsed.inMilliseconds,
        'total_xp': computationResult.xpBreakdown!.totalXP,
        'ui_events': uiEvents.events.length,
      });

      return PipelineExecutionResult.success(
        stateDelta: computationResult.stateDelta!,
        uiEvents: uiEvents,
        xpBreakdown: computationResult.xpBreakdown!,
        executionTime: stopwatch.elapsed,
        debugInfo: debugInfo,
      );
    } catch (e, stackTrace) {
      final error = 'Pipeline execution failed: $e';
      _debugLog('Pipeline execution failed', {
        'error': e.toString(),
        'stack_trace': stackTrace.toString(),
      });

      onError?.call(error);

      return PipelineExecutionResult.failure(
        error: error,
        executionTime: stopwatch.elapsed,
        debugInfo: debugInfo,
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// PHASE 1: Analyze the completion context and determine base XP
  Future<_PhaseResult> _analyzeCompletion(
    Task task,
    CompletionContext context,
    Map<String, dynamic> debugInfo,
  ) async {
    try {
      _debugLog('Phase 1: Analyzing completion', {
        'task_difficulty': task.difficulty.name,
        'time_cost': task.timeCostMinutes,
        'streak': context.currentStreak,
      });

      // Calculate the detailed XP breakdown using the intelligent engine
      final detailedBreakdown = _xpEngine.calculateDetailedXP(task, context);
      final baseXP = detailedBreakdown.finalBaseXP;
      final hasLootBox = detailedBreakdown.lootBoxResult.wasTriggered;

      debugInfo['analysis'] = {
        'base_xp': baseXP,
        'has_loot_box': hasLootBox,
        'difficulty_multiplier': detailedBreakdown.difficultyMultiplier,
        'category_multiplier': detailedBreakdown.categoryMultiplier,
        'loot_box_multiplier': detailedBreakdown.lootBoxResult.multiplier,
        'time_minutes': task.timeCostMinutes,
      };
      debugInfo['analysis_breakdown'] = {
        'category_reason': detailedBreakdown.categoryReason,
        'difficulty_reason': detailedBreakdown.difficultyReason,
        'total_bonus_xp': detailedBreakdown.totalBonusXP,
      };

      return _PhaseResult.success(
        baseXP: baseXP,
        hasLootBox: hasLootBox,
      );
    } catch (e) {
      return _PhaseResult.failure('Analysis phase failed: $e');
    }
  }

  /// PHASE 2: Compute effects, state changes, and UI events
  Future<_PhaseResult> _computeEffects(
    Task task,
    CompletionContext context,
    int baseXP,
    bool hasLootBox,
    Map<String, dynamic> debugInfo,
  ) async {
    try {
      _debugLog('Phase 2: Computing effects', {
        'base_xp': baseXP,
        'has_loot_box': hasLootBox,
        'user_level': _userProvider.user?.level,
      });

      if (_userProvider.user == null) {
        return _PhaseResult.failure('No user available for computation');
      }

      // Use pure effect engine to compute all effects and results
      final completionResult = PureEffectEngine.processTaskCompletion(
        user: _userProvider.user!,
        task: task,
        context: context,
        baseXP: baseXP,
        hasLootBox: hasLootBox,
      );

      debugInfo['computation'] = {
        'final_xp': completionResult.xpBreakdown.totalXP,
        'effects_applied':
            completionResult.xpBreakdown.effectResults.appliedEffects.length,
        'ui_events_generated': completionResult.uiEvents.events.length,
        'level_change': completionResult.stateDelta.user?.levelChange,
        'new_perks': completionResult.stateDelta.user?.newPerks?.length ?? 0,
      };

      return _PhaseResult.success(
        stateDelta: completionResult.stateDelta,
        uiEvents: completionResult.uiEvents,
        xpBreakdown: completionResult.xpBreakdown,
      );
    } catch (e) {
      return _PhaseResult.failure('Computation phase failed: $e');
    }
  }

  /// PHASE 3: Persist state changes
  Future<_PhaseResult> _persistChanges(
    StateDelta stateDelta,
    Map<String, dynamic> debugInfo,
  ) async {
    try {
      _debugLog('Phase 3: Persisting changes', {
        'has_user_changes': stateDelta.user?.hasChanges ?? false,
        'task_count': stateDelta.tasks?.length ?? 0,
        'epic_count': stateDelta.epics?.length ?? 0,
      });

      // Apply state delta to user provider (pure persistence)
      final success = await _userProvider.applyStateDelta(stateDelta);

      if (!success) {
        return _PhaseResult.failure('Failed to persist user state changes');
      }

      debugInfo['persistence'] = {
        'success': true,
        'user_updated': stateDelta.user?.hasChanges ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return _PhaseResult.success();
    } catch (e) {
      return _PhaseResult.failure('Persistence phase failed: $e');
    }
  }

  /// PHASE 4: Emit UI events
  Future<_PhaseResult> _emitEvents(
    UiEventBatch uiEvents,
    PipelineSettings settings,
    Map<String, dynamic> debugInfo,
  ) async {
    try {
      _debugLog('Phase 4: Emitting UI events', {
        'event_count': uiEvents.events.length,
        'sequential': uiEvents.sequential,
        'reduced_motion': settings.reducedMotion,
      });

      // Filter events based on settings
      var filteredEvents = uiEvents;

      if (!settings.enableAnimations) {
        filteredEvents = UiEventBatch(
          events: uiEvents.events
              .where((e) => e.type != UiEventType.playAnimation)
              .toList(),
          batchId: uiEvents.batchId,
          timestamp: uiEvents.timestamp,
          sequential: uiEvents.sequential,
        );
      }

      if (!settings.enableNotifications) {
        filteredEvents = UiEventBatch(
          events: filteredEvents.events
              .where((e) =>
                  e.type != UiEventType.showSnackbar &&
                  e.type != UiEventType.showToast)
              .toList(),
          batchId: filteredEvents.batchId,
          timestamp: filteredEvents.timestamp,
          sequential: filteredEvents.sequential,
        );
      }

      // Sort by priority
      filteredEvents = filteredEvents.sortByPriority();

      // Emit events to handler
      if (onUiEvents != null && filteredEvents.events.isNotEmpty) {
        onUiEvents!(filteredEvents);
      }

      debugInfo['emission'] = {
        'original_count': uiEvents.events.length,
        'filtered_count': filteredEvents.events.length,
        'emitted': filteredEvents.events.isNotEmpty,
        'priorities':
            filteredEvents.events.map((e) => e.priority.name).toList(),
      };

      return _PhaseResult.success();
    } catch (e) {
      return _PhaseResult.failure('Emission phase failed: $e');
    }
  }

  /// Execute epic completion pipeline
  Future<PipelineExecutionResult> executeEpicCompletion({
    required String epicId,
    required String epicTitle,
    required List<String> rewardsUnlocked,
    PipelineSettings? settings,
  }) async {
    final stopwatch = Stopwatch()..start();
    final pipelineSettings = settings ?? const PipelineSettings();
    final debugInfo = <String, dynamic>{};

    try {
      _debugLog('Starting epic completion pipeline', {
        'epic_id': epicId,
        'epic_title': epicTitle,
        'rewards_count': rewardsUnlocked.length,
      });

      // Create state delta for epic completion
      final stateDelta = StateDelta(
        epics: [
          EpicStateDelta(
            epicId: epicId,
            completed: true,
            rewardsUnlocked: rewardsUnlocked,
          )
        ],
        timestamp: DateTime.now(),
        operation: 'epic_completion',
      );

      // Create UI events
      final uiEvents = UiEventBatch.sequential(events: [
        CelebrationEvent.epicCompletion(
          epicTitle: epicTitle,
          rewardsUnlocked: rewardsUnlocked,
        ),
      ]);

      // Persist changes (epic completion might unlock themes, etc.)
      final persistSuccess = await _userProvider.applyStateDelta(stateDelta);
      if (!persistSuccess) {
        return PipelineExecutionResult.failure(
          error: 'Failed to persist epic completion',
          executionTime: stopwatch.elapsed,
          debugInfo: debugInfo,
        );
      }

      // Emit events
      var filteredEvents = pipelineSettings.reducedMotion
          ? uiEvents.filterForReducedMotion(true)
          : uiEvents;

      if (onUiEvents != null && filteredEvents.events.isNotEmpty) {
        onUiEvents!(filteredEvents);
      }

      return PipelineExecutionResult.success(
        stateDelta: stateDelta,
        uiEvents: filteredEvents,
        xpBreakdown: XPCalculationBreakdown(
          baseXP: 0,
          totalXP: 0,
          effectResults: EffectEvaluationResult(evaluatedAt: DateTime.now()),
        ),
        executionTime: stopwatch.elapsed,
        debugInfo: debugInfo,
      );
    } catch (e) {
      return PipelineExecutionResult.failure(
        error: 'Epic completion pipeline failed: $e',
        executionTime: stopwatch.elapsed,
        debugInfo: debugInfo,
      );
    } finally {
      stopwatch.stop();
    }
  }

  /// Get pipeline health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'user_connected': _userProvider.user != null,
      'controller_ready': _talentPerkController.state.lastUpdated
          .isAfter(DateTime.now().subtract(const Duration(minutes: 5))),
      'xp_engine_ready': true, // Always ready
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  void _debugLog(String message, Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('CompletionPipeline: $message');
      debugPrint('Data: $data');
    }
    onDebugLog?.call({
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String()
    });
  }
}

/// Internal result class for pipeline phases
class _PhaseResult {
  final bool success;
  final String? error;
  final int? baseXP;
  final bool? hasLootBox;
  final StateDelta? stateDelta;
  final UiEventBatch? uiEvents;
  final XPCalculationBreakdown? xpBreakdown;

  const _PhaseResult({
    required this.success,
    this.error,
    this.baseXP,
    this.hasLootBox,
    this.stateDelta,
    this.uiEvents,
    this.xpBreakdown,
  });

  factory _PhaseResult.success({
    int? baseXP,
    bool? hasLootBox,
    StateDelta? stateDelta,
    UiEventBatch? uiEvents,
    XPCalculationBreakdown? xpBreakdown,
  }) {
    return _PhaseResult(
      success: true,
      baseXP: baseXP,
      hasLootBox: hasLootBox,
      stateDelta: stateDelta,
      uiEvents: uiEvents,
      xpBreakdown: xpBreakdown,
    );
  }

  factory _PhaseResult.failure(String error) {
    return _PhaseResult(success: false, error: error);
  }
}
