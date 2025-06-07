import 'package:flutter/material.dart';
import '../models/task.dart';
import '../providers/secure_task_provider.dart';
import 'package:provider/provider.dart';
import 'edit_task_dialog.dart';
import 'package:intl/intl.dart';
import '../models/task_results.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final Function(DismissDirection)? onDismissed;
  final bool showTime;
  final bool compact;
  final bool superCompact;
  final double? height;

  const TaskTile({
    Key? key,
    required this.task,
    this.onDismissed,
    this.showTime = true,
    this.compact = false,
    this.superCompact = false,
    this.height,
  }) : super(key: key);

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkScaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupAnimations();
  }

  void _setupAnimations() {
    final theme = Theme.of(context);
    
    // Scale animation for the entire tile
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70.0,
      ),
    ]).animate(_animationController);

    // Check mark scale animation
    _checkScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60.0,
      ),
    ]).animate(_animationController);

    // Color animation for the check mark
    _colorAnimation = ColorTween(
      begin: theme.colorScheme.outline,
      end: theme.colorScheme.primary,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
  if (!widget.task.isCompleted && !_isCompleting) {
    setState(() {
      _isCompleting = true;
    });
    
    try {
      // Get the provider reference before starting the operation
      final taskProvider = Provider.of<SecureTaskProvider>(context, listen: false);
      
      // Use our new robust completion method
      final result = await taskProvider.completeTask(widget.task.id);
      
      if (mounted) {
        if (result.isSuccess) {
          // Handle successful completion with user feedback
          await _handleSuccessfulCompletion(result);
        } else {
          // Handle errors with specific, helpful feedback
          await _handleCompletionError(result);
        }
      }
    } catch (e) {
      // This catch block now handles only unexpected errors
      debugPrint('Unexpected error in task completion: $e');
      if (mounted) {
        _showUnexpectedErrorMessage();
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}

/// Handles successful task completion with appropriate user feedback
Future<void> _handleSuccessfulCompletion(TaskCompletionResult result) async {
  // Start the animation if still mounted
  await _animationController.forward();
  
  // Show success feedback to the user
  if (mounted && result.completedTask != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task completed! +${result.completedTask!.xpReward} XP'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Handles task completion errors with specific, actionable feedback
Future<void> _handleCompletionError(TaskCompletionResult result) async {
  if (!mounted) return;
  
  switch (result.errorType) {
    case TaskCompletionError.taskNotFound:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This task no longer exists. Refreshing your task list.'),
          backgroundColor: Colors.orange,
        ),
      );
      // You might want to trigger a task list refresh here
      break;
      
    case TaskCompletionError.storageFailure:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to save. Please try again.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _handleComplete(), // Retry the operation
          ),
        ),
      );
      break;
      
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
  }
}

/// Shows a message for truly unexpected errors
void _showUnexpectedErrorMessage() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('An unexpected error occurred. Please restart the app if this continues.'),
      backgroundColor: Colors.red,
    ),
  );
}

  // This method decides what UI to build based on the display mode
  Widget _buildTaskContent(ThemeData theme) {
    // Super compact mode: minimal info for calendar cells
    if (widget.superCompact) {
      return _buildSuperCompactContent(theme);
    }
    
    // Compact mode: condensed for lists
    if (widget.compact) {
      return _buildCompactContent(theme);
    }
    
    // Full mode: all details (original implementation)
    return _buildFullContent(theme);
  }

  // Super compact version for calendar grid cells
  Widget _buildSuperCompactContent(ThemeData theme) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          // Small checkbox
          GestureDetector(
            key: const Key('task-complete-button'),
            onTap: _handleComplete,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.task.isCompleted 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline,
                  width: 1.5,
                ),
                color: widget.task.isCompleted 
                    ? theme.colorScheme.primary 
                    : Colors.transparent,
              ),
              child: widget.task.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 10,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          
          // Task title only (truncated)
          Expanded(
            child: Text(
              widget.task.title,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: widget.task.isCompleted
                    ? TextDecoration.lineThrough 
                    : null,
                color: widget.task.isCompleted
                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                    : null,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Compact version for list views
  Widget _buildCompactContent(ThemeData theme) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Standard checkbox
          GestureDetector(
            key: const Key('task-complete-button'),
            onTap: _handleComplete,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.task.isCompleted 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline,
                  width: 2,
                ),
                color: widget.task.isCompleted 
                    ? theme.colorScheme.primary 
                    : Colors.transparent,
              ),
              child: widget.task.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Task info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: widget.task.isCompleted
                        ? TextDecoration.lineThrough 
                        : null,
                    color: widget.task.isCompleted
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Show time if requested and available
                if (widget.showTime && widget.task.scheduledTime != null)
                  Text(
                    widget.task.scheduledTime!.format(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${widget.task.xpReward}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Full content version (original implementation, slightly modified)
  Widget _buildFullContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('task-complete-button'),
            onTap: _handleComplete,
            child: AnimatedBuilder(
              animation: _checkScaleAnimation,
              builder: (context, child) {
                return Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.task.isCompleted 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                    color: widget.task.isCompleted 
                        ? theme.colorScheme.primary 
                        : Colors.transparent,
                  ),
                  child: widget.task.isCompleted
                      ? Transform.scale(
                          scale: _checkScaleAnimation.value,
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: widget.task.isCompleted
                        ? TextDecoration.lineThrough 
                        : null,
                    color: widget.task.isCompleted
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : null,
                  ),
                ),
                if (widget.task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.task.xpReward} XP',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.task.recurrencePattern != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.task.recurrencePattern!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.task.dueDate != null && widget.showTime) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDate(widget.task.dueDate!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showTaskMenu(context),
            tooltip: 'Edit Task',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // For super compact mode, don't use Dismissible (too small)
    if (widget.superCompact) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
            ),
            color: theme.colorScheme.surface,
            child: _buildTaskContent(theme),
          ),
        ),
      );
    }
    
    // For full and compact modes, keep the Dismissible functionality
    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20.0),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          child: const Icon(Icons.check, color: Colors.white),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Complete
          if (!widget.task.isCompleted && !_isCompleting) {
            await _handleComplete();
            return true;
          }
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          // Delete
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Task'),
              content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          return shouldDelete == true;
        }
        return false;
      },
      onDismissed: (direction) {
        if (widget.onDismissed != null) {
          widget.onDismissed!(direction);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
            ),
            color: theme.colorScheme.surface,
            child: Container(
              height: widget.height, // Apply height constraint if provided
              child: InkWell(
                onTap: () {
                  _showTaskMenu(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: _buildTaskContent(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text('Edit Task', style: Theme.of(context).textTheme.titleMedium),
              onTap: () {
                Navigator.pop(context);
                _showEditTaskDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Task', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<SecureTaskProvider>(context, listen: false).deleteTask(widget.task.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(task: widget.task),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }
} 