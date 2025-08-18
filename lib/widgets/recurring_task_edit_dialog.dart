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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'This is a recurring task.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How would you like to edit it?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                    subtitle: 'Changes will apply to this and all future occurrences',
                    onTap: () {
                      Navigator.of(context).pop(EditScope.allFutureTasks);
                      onEditAllFuture?.call();
                    },
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
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