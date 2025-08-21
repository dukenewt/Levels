import 'package:flutter/material.dart';

import '../../../models/task.dart';
import '../../../models/task_results.dart';
import '../../../widgets/xp_reward_snackbar.dart';
import '../../../widgets/xp_breakdown_dialog.dart';
import '../../../core/animation/animation_orchestrator.dart';
import '../../../services/streak_service.dart';
import '../../../services/task_notification_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/epic_provider.dart';
import '../../../models/epic_project.dart';

/// Lightweight pipeline facade to standardize the post-completion UI sequence.
/// This does not replace existing domain logic yet; it sequences UI safely.
class CompletionPipeline {
  /// Play a conflict-free UI sequence for task completion using AnimationOrchestrator.
  static Future<void> playUiSequence({
    required BuildContext context,
    required Task task,
    required TaskCompletionResult completion,
  }) async {
    final orchestrator = AnimationOrchestrator.instance;
    final key = 'task:${task.id}';

    // Wire reduced motion from settings
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      orchestrator.setReducedMotion(settings.reducedMotion);
    } catch (_) {
      // If settings provider is not in scope, keep existing orchestrator state.
    }

    final List<Future<void> Function()> steps = [];

    // Streak update and immediate notification before visual UI
    steps.add(() async {
      await StreakService.updateStreak(task, DateTime.now());
      if (!context.mounted) return;
      final perkBonus = completion.enhancedBreakdown?.perkBonusXP ?? 0;
      final totalXp = completion.xpGained;
      await TaskNotificationService.instance.showImmediateNotification(
        title: 'Task Completed! 🎉',
        body: perkBonus > 0
            ? '${task.title} completed! +$totalXp XP (+$perkBonus perk bonus!)'
            : '${task.title} completed! +$totalXp XP',
        payload: 'completion_${task.id}',
      );
    });

    // XP snackbar next
    steps.add(() async {
      if (!context.mounted) return;
      XPRewardSnackbar.show(
        context,
        completion.xpGained,
        completion.streakBonus,
      );
      // Small breathing room to avoid immediate overlap
      await Future.delayed(orchestrator.reducedMotion
          ? const Duration(milliseconds: 0)
          : const Duration(milliseconds: 300));
    });

    // Optional breakdown dialog
    if (completion.breakdown != null) {
      steps.add(() async {
        if (!context.mounted) return;
        XpBreakdownDialog.show(
          context,
          breakdown: completion.breakdown!,
          task: task,
        );
      });
    }

    // Epic progress + optional celebration (after XP UI)
    steps.add(() async {
      if (!context.mounted) return;
      final epicProvider = Provider.of<EpicProvider>(context, listen: false);
      final updatedEpic = await epicProvider.updateEpicProgress(task.id);
      if (updatedEpic != null && updatedEpic.isCompleted) {
        // For now, keep it simple: show a celebratory snackbar
        // This can be upgraded to a full-screen celebration widget orchestrated here.
        if (!context.mounted) return;
        final msg = 'Epic Completed: ${updatedEpic.title}! 🎉';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    });

    await orchestrator.runSequence(key, steps);
  }
}
