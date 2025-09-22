import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dailyxp/models/task.dart';
import 'package:dailyxp/models/task_results.dart';
import 'package:dailyxp/widgets/xp_reward_snackbar.dart';
import 'package:dailyxp/widgets/xp_breakdown_dialog.dart';
import 'package:dailyxp/core/animation/animation_orchestrator.dart';
import 'package:dailyxp/services/streak_service.dart';
import 'package:dailyxp/services/task_notification_service.dart';
import 'package:dailyxp/providers/settings_provider.dart';
import 'package:dailyxp/providers/epic_provider.dart';

/// UI-only completion sequence for presentation layer.
/// Sequences safe UI actions post-completion via AnimationOrchestrator.
class CompletionUiSequence {
  static Future<void> playUiSequence({
    required BuildContext context,
    required Task task,
    required TaskCompletionResult completion,
  }) async {
    final orchestrator = AnimationOrchestrator.instance;
    final key = 'task:${task.id}';

    // Wire reduced motion from settings if available
    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      orchestrator.setReducedMotion(settings.reducedMotion);
    } catch (_) {}

    final List<Future<void> Function()> steps = [];

    // Streak update and immediate notification before visual UI
    steps.add(() async {
      await StreakService.updateStreak(task, DateTime.now());
      if (!context.mounted) return;
      bool allowCompletionNotifs = false;
      try {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        allowCompletionNotifs = settings.enableCompletionCelebrations;
      } catch (_) {}

      if (allowCompletionNotifs) {
        final perkBonus = completion.enhancedBreakdown?.perkBonusXP ?? 0;
        final totalXp = completion.xpGained;
        await TaskNotificationService.instance.showImmediateNotification(
          title: 'Task Completed! 🎉',
          body: perkBonus > 0
              ? '${task.title} completed! +$totalXp XP (+$perkBonus perk bonus!)'
              : '${task.title} completed! +$totalXp XP',
          payload: 'completion_${task.id}',
        );
      }
    });

    // XP snackbar next
    steps.add(() async {
      if (!context.mounted) return;
      XPRewardSnackbar.show(
        context,
        completion.xpGained,
        completion.streakBonus,
      );
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
        if (!context.mounted) return;
        bool allowCelebrations = false;
        try {
          final settings =
              Provider.of<SettingsProvider>(context, listen: false);
          allowCelebrations = settings.enableCompletionCelebrations;
        } catch (_) {}

        if (allowCelebrations) {
          await showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Epic Completed!'),
                content: Text(updatedEpic.title),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Nice!'),
                  ),
                ],
              );
            },
          );
        }
      }
    });

    await orchestrator.runSequence(key, steps);
  }
}
