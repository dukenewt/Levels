import 'package:flutter/material.dart';
import '../models/task.dart';

enum EditScope {
  thisTaskOnly,
  allFutureTasks,
}

class RecurringTaskEditDialog extends StatelessWidget {
  final Task task;
  final VoidCallback? onEditThisOnly;
  final VoidCallback? onEditAllFuture;

  const RecurringTaskEditDialog({
    Key? key,
    required this.task,
    this.onEditThisOnly,
    this.onEditAllFuture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecurring = task.recurrencePattern != null;
    final isParentTask = task.parentTaskId == null && isRecurring;
    final isChildTask = task.parentTaskId != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isRecurring
                          ? 'This is a recurring task.'
                          : 'This task does not repeat.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRecurring
                          ? 'How would you like to edit it?'
                          : 'You can edit this task normally.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isRecurring) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.repeat, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _describeRecurrence(task),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    if (isRecurring) ...[
                      _buildEditOption(
                        context,
                        theme,
                        icon: Icons.edit_outlined,
                        title: 'Edit this task only',
                        subtitle: 'Changes will only apply to this occurrence',
                        onTap: () {
                          Navigator.of(context).pop(EditScope.thisTaskOnly);
                          onEditThisOnly?.call();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEditOption(
                        context,
                        theme,
                        icon: Icons.edit_calendar,
                        title: 'Edit all future tasks',
                        subtitle:
                            'Changes will apply to this and all future occurrences',
                        onTap: () {
                          Navigator.of(context).pop(EditScope.allFutureTasks);
                          onEditAllFuture?.call();
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.repeat,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edit Recurring Task',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _describeRecurrence(Task t) {
    final pattern = (t.recurrencePattern ?? '').toLowerCase();
    switch (pattern) {
      case 'daily':
        if ((t.repeatInterval ?? 1) > 1) {
          return 'Repeats every ${t.repeatInterval} days';
        }
        return 'Repeats daily';
      case 'weekly':
        final days = t.weeklyDays ?? const [];
        if (days.isEmpty) return 'Repeats weekly';
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final labels = days
            .where((d) => d >= 1 && d <= 7)
            .map((d) => names[d - 1])
            .toList();
        final interval = (t.repeatInterval ?? 1);
        if (interval > 1) {
          return 'Every $interval weeks on ${labels.join(', ')}';
        }
        return 'Weekly on ${labels.join(', ')}';
      case 'workdays':
        return 'Weekdays (Mon–Fri)';
      case 'monthly':
        final interval = (t.repeatInterval ?? 1);
        if (interval > 1) {
          return 'Every $interval months';
        }
        return 'Repeats monthly';
      case 'yearly':
        final interval = (t.repeatInterval ?? 1);
        if (interval > 1) return 'Every $interval years';
        return 'Repeats annually';
      default:
        return 'Repeats';
    }
  }

  Widget _buildEditOption(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

Future<EditScope?> showRecurringTaskEditDialog(
  BuildContext context,
  Task task,
) {
  return showDialog<EditScope>(
    context: context,
    builder: (context) => RecurringTaskEditDialog(task: task),
  );
}
