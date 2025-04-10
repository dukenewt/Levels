import 'package:flutter/material.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'package:provider/provider.dart';
import 'edit_task_dialog.dart';
import 'package:intl/intl.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final Function(DismissDirection)? onDismissed;

  const TaskTile({
    Key? key,
    required this.task,
    this.onDismissed,
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
      
      // Start the animation
      await _animationController.forward();
      
      // Call the completion callback
      if (mounted) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        await taskProvider.completeTask(widget.task.id);
      }
      
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (!widget.task.isCompleted && !_isCompleting) {
          await _handleComplete();
          return true;
        }
        return false;
      },
      onDismissed: widget.onDismissed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // Show edit task dialog
                _showEditTaskDialog(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
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
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.task.category,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${widget.task.xpReward} XP',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
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
                                    color: theme.colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.repeat,
                                        size: 14,
                                        color: theme.colorScheme.onTertiaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          widget.task.recurrencePattern!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onTertiaryContainer,
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
                    if (widget.task.dueDate != null) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDate(widget.task.dueDate!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditTaskDialog(context),
                      tooltip: 'Edit Task',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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