import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/task.dart';
import '../providers/secure_task_provider.dart';
import '../models/task_results.dart';
import 'task_editing_dialog.dart';
import '../core/error_handling.dart';
import '../core/theme/app_design_tokens.dart';
import '../core/utils/date_helpers.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final Function(DismissDirection)? onDismissed;
  final bool showTime;
  final VoidCallback? onEdit;

  const TaskTile({
    super.key,
    required this.task,
    this.onDismissed,
    this.showTime = true,
    this.onEdit,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with TickerProviderStateMixin {
  
  // Animation controllers for different effects
  late AnimationController _completionController;
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  
  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isCompleting = false;
  bool _isHovered = false;

  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimationControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationsInitialized) {
      _setupAnimations();
      _startIdleAnimations();
      _animationsInitialized = true;
    }
  }

  void _setupAnimationControllers() {
    // Completion animation - triggered when task is completed
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Hover/tap feedback animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Subtle pulse for active tasks
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _setupAnimations() {
    if (!mounted) return;
    
    final theme = Theme.of(context);
    
    // Scale effect for completion
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
    ));

    // Rotation for completion celebration
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02, // Very subtle rotation
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: const Interval(0.1, 0.4, curve: Curves.easeInOut),
    ));

    // Fade out after completion
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    // Color shift during completion
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: theme.colorScheme.primary.withOpacity(0.1),
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Gentle pulse for incomplete tasks
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startIdleAnimations() {
    // Only pulse if task is not completed and animations are initialized
    if (!widget.task.isCompleted && _animationsInitialized && mounted) {
      // Add small random delay to prevent all tiles pulsing in sync
      Future.delayed(
        Duration(milliseconds: 300 + (widget.task.id.hashCode % 1000)),
        () {
          if (mounted && !widget.task.isCompleted && _animationsInitialized) {
            _pulseController.safeRepeat(reverse: true);
          }
        },
      );
    }
  }

  Future<void> _handleComplete() async {
    if (!widget.task.isCompleted && !_isCompleting) {
      setState(() {
        _isCompleting = true;
      });
      
      // Stop all animations cleanly using safe methods
      _pulseController.safeStop();
      _hoverController.safeStop();
      
      // Start completion animation
      _completionController.forward();
      
      try {
        final taskProvider = Provider.of<SecureTaskProvider>(context, listen: false);
        final result = await taskProvider.completeTask(context, widget.task, isEnhanced: true);
        
        if (mounted) {
          if (result.isSuccess) {
            // Let completion animation finish before showing success
            await Future.delayed(const Duration(milliseconds: 400));
            
            // Ensure all animations are in their final completed state
            if (mounted) {
              _ensureAnimationsInCompletedState();
              // Note: XP reward snackbar is shown by the task provider, 
              // so we don't need to show another success message here
            }
          } else {
            // Revert animation on error
            await _revertCompletionAnimation();
            _handleCompletionError(result);
            _startIdleAnimations(); // Restart idle animations
          }
        }
      } catch (e) {
        debugPrint('Unexpected error in task completion: $e');
        if (mounted) {
          await _revertCompletionAnimation();
          _showUnexpectedErrorMessage();
          _startIdleAnimations();
        }
      } finally {
        if (mounted) {
          setState(() => _isCompleting = false);
        }
      }
    }
  }

  /// Ensure all animations are in their proper completed state
  void _ensureAnimationsInCompletedState() {
    // Stop any lingering animations
    _pulseController.safeStop();
    _hoverController.safeReset();
    
    // Reset hover state
    setState(() => _isHovered = false);
  }

  /// Safely revert completion animation with proper cleanup
  Future<void> _revertCompletionAnimation() async {
    await _completionController.safeReverse();
    
    // Reset hover state
    if (mounted) {
      setState(() => _isHovered = false);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isCompleting && !widget.task.isCompleted) {
      _hoverController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isCompleting) {
      _hoverController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!_isCompleting) {
      _hoverController.reverse();
    }
  }

  void _showSuccessMessage(Result<TaskCompletionResult> result) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Task completed! +${result.data?.xpGained ?? 0} XP'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _handleCompletionError(Result<TaskCompletionResult> result) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing task: ${result.error?.message ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showUnexpectedErrorMessage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If animations aren't initialized yet, return a simple version
    if (!_animationsInitialized) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: _buildTaskCard(theme),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _completionController,
        _hoverController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: (_scaleAnimation.value) * 
                (_isHovered ? 1.02 : 1.0) * 
                (_pulseAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _colorAnimation.value ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildTaskCard(theme),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if task completion state changed
    if (oldWidget.task.isCompleted != widget.task.isCompleted) {
      if (widget.task.isCompleted) {
        // Task was just completed - ensure animations are in completed state
        _ensureAnimationsInCompletedState();
        // Force immediate rebuild to reflect completion state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      } else if (!widget.task.isCompleted && !_isCompleting) {
        // Task was uncompleted - restart idle animations
        _startIdleAnimations();
      }
    }
  }

  Widget _buildTaskCard(ThemeData theme) {
    Widget taskWidget = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Card(
        elevation: _isHovered ? 6 : 2,
        shadowColor: theme.colorScheme.primary.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: widget.task.isCompleted 
                ? theme.colorScheme.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildCompletionButton(theme),
              const SizedBox(width: 16),
              Expanded(child: _buildTaskContent(theme)),
              _buildXpBadge(theme),
              _buildMenuButton(theme),
            ],
          ),
        ),
      ),
    );

    // Add dismissible functionality if callback provided
    if (widget.onDismissed != null) {
      return Dismissible(
        key: Key(widget.task.id),
        onDismissed: widget.onDismissed,
        background: _buildSwipeBackground(Colors.green, Icons.check, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBackground(Colors.red, Icons.delete, Alignment.centerRight),
        child: taskWidget,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: taskWidget,
    );
  }

  Widget _buildCompletionButton(ThemeData theme) {
    return GestureDetector(
      onTap: widget.task.isCompleted ? null : _handleComplete,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('completion_${widget.task.id}_${widget.task.isCompleted}'),
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(
          begin: 0.0,
          end: widget.task.isCompleted ? 1.0 : 0.0,
        ),
        builder: (context, progress, child) {
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                Colors.transparent,
                theme.colorScheme.primary,
                progress,
              ),
              border: Border.all(
                color: Color.lerp(
                  theme.colorScheme.outline,
                  theme.colorScheme.primary,
                  progress,
                )!,
                width: 2,
              ),
            ),
            child: _isCompleting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : AnimatedScale(
                    scale: progress,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTaskContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          key: ValueKey('title_${widget.task.id}_${widget.task.isCompleted}'),
          duration: const Duration(milliseconds: 300),
          style: theme.textTheme.titleMedium!.copyWith(
            decoration: widget.task.isCompleted 
                ? TextDecoration.lineThrough 
                : null,
            color: widget.task.isCompleted 
                ? theme.colorScheme.onSurface.withOpacity(0.6)
                : theme.colorScheme.onSurface,
          ),
          child: Text(widget.task.title),
        ),
        if (widget.task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            key: ValueKey('description_${widget.task.id}_${widget.task.isCompleted}'),
            duration: const Duration(milliseconds: 300),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              decoration: widget.task.isCompleted 
                  ? TextDecoration.lineThrough 
                  : null,
            ),
            child: Text(
              widget.task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (widget.showTime && widget.task.dueDate != null) ...[
          const SizedBox(height: 8),
          _buildTimeChip(theme),
        ],
      ],
    );
  }

  Widget _buildTimeChip(ThemeData theme) {
    final isOverdue = DateHelpers.isOverdue(widget.task.dueDate!);
    final timeText = DateHelpers.formatDueDate(context, widget.task.dueDate!);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue 
            ? theme.colorScheme.error.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isOverdue 
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildXpBadge(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('xp_badge_${widget.task.id}_${widget.task.isCompleted}'),
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(
        begin: 1.0,
        end: widget.task.isCompleted ? 0.8 : 1.0,
      ),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(
                widget.task.isCompleted ? 0.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.task.xpReward} XP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(
                  widget.task.isCompleted ? 0.7 : 1.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(ThemeData theme) {
    return IconButton(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      onPressed: () => _showTaskMenu(context),
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  void _showTaskMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Edit Task'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onEdit != null) {
                  widget.onEdit!();
                } else {
                  _showEditTaskDialog(context);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Task'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaskEditingDialog(task: widget.task),
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

  @override
  void dispose() {
    _completionController.dispose();
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
} 