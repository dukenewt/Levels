import 'package:flutter/material.dart';
import '../models/epic_project.dart';
import '../models/task.dart';

class EpicProgressCard extends StatelessWidget {
  final EpicProject epic;
  final List<Task> tasks;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  const EpicProgressCard({
    Key? key,
    required this.epic,
    required this.tasks,
    this.onTap,
    this.onStart,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          epic.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (epic.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            epic.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context),
                ],
              ),

              const SizedBox(height: 16),

              // Progress section
              if (epic.isActive || epic.isCompleted) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${epic.completedTasks}/${epic.requiredTasks} tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: epic.progressPercentage,
                    minHeight: 8,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      epic.isCompleted
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tasks preview
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tasks.length} tasks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      epic.reward.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Due date if set
              if (epic.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 20,
                      color: _getDueDateColor(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${_formatDate(epic.dueDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _getDueDateColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],

              // Action buttons
              if (onStart != null || onComplete != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onStart != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Epic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    if (onComplete != null) ...[
                      if (onStart != null) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onComplete,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Completion celebration indicator
              if (epic.isCompleted) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.celebration,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Epic completed! Reward unlocked: ${epic.reward.name}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (epic.status) {
      case EpicStatus.planning:
        color = Colors.orange;
        icon = Icons.edit;
        text = 'Planning';
        break;
      case EpicStatus.active:
        color = Colors.blue;
        icon = Icons.play_arrow;
        text = 'Active';
        break;
      case EpicStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Completed';
        break;
      case EpicStatus.abandoned:
        color = Colors.red;
        icon = Icons.close;
        text = 'Abandoned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(BuildContext context) {
    if (epic.dueDate == null) return Theme.of(context).colorScheme.onSurface;

    final now = DateTime.now();
    final dueDate = epic.dueDate!;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // Overdue
    } else if (difference <= 1) {
      return Colors.orange; // Due soon
    } else if (difference <= 7) {
      return Colors.amber; // Due this week
    } else {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue (${date.day}/${date.month})';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference <= 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
