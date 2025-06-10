import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/task.dart';
import '../providers/secure_task_provider.dart';
import '../models/task_results.dart';
import 'task_editing_dialog.dart';
import 'xp_orb_overlay.dart';
import 'package:intl/intl.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final Function(DismissDirection)? onDismissed;
  final bool showTime;
  final VoidCallback? onEdit;

  const TaskTile({
    Key? key,
    required this.task,
    this.onDismissed,
    this.showTime = true,
    this.onEdit,
  }) : super(key: key);

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with TickerProviderStateMixin {
  
  late AnimationController _dissolveController;
  late AnimationController _rippleController;
  late AnimationController _idleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<Color?> _colorShiftAnimation;
  late Animation<double> _idleFloatAnimation;
  
  bool _isCompleting = false;
  bool _showRipples = false;

  @override
  void initState() {
    super.initState();
    _setupControllers();
     WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupAnimations();
        _startIdleAnimation();
      }
    });
  }

  void _setupControllers() {
    _dissolveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
  }

  void _setupAnimations() {
    final theme = Theme.of(context);
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInExpo)),
        weight: 80.0,
      ),
    ]).animate(_dissolveController);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 80.0,
      ),
    ]).animate(_dissolveController);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _dissolveController,
      curve: Curves.easeInOut,
    ));

    _colorShiftAnimation = ColorTween(
      begin: Colors.transparent,
      end: theme.colorScheme.primary.withOpacity(0.2),
    ).animate(CurvedAnimation(
      parent: _dissolveController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _idleFloatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _idleController,
      curve: Curves.easeInOut,
    ));
  }

  void _startIdleAnimation() {
    if (!widget.task.isCompleted) {
      Future.delayed(Duration(milliseconds: 500 + (widget.task.id.hashCode % 2000)), () {
        if (mounted && !_isCompleting) {
          _idleController.repeat(reverse: true);
        }
      });
    }
  }

  Future<void> _handleComplete() async {
    if (!widget.task.isCompleted && !_isCompleting) {
      setState(() {
        _isCompleting = true;
        _showRipples = true;
      });
      
      _idleController.stop();
      
      try {
        final taskProvider = Provider.of<SecureTaskProvider>(context, listen: false);
        
        _startCompletionAnimation();
        
        final result = await taskProvider.completeTaskWithIntelligentXP(context, widget.task.id);
        
        if (mounted) {
          if (result.isSuccess) {
            await _dissolveController.forward();
            _showSuccessMessage(result);
          } else {
            await _revertAnimations();
            _handleCompletionError(result);
          }
        }
      } catch (e) {
        debugPrint('Unexpected error in task completion: $e');
        if (mounted) {
          await _revertAnimations();
          _showUnexpectedErrorMessage();
        }
      } finally {
        if (mounted) {
          setState(() => _isCompleting = false);
        }
      }
    }
  }

  void _startCompletionAnimation() {
    _dissolveController.forward();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _showRipples) {
        _rippleController.forward();
      }
    });
    
    _triggerXPOrbAnimation();
  }

  void _triggerXPOrbAnimation() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset taskPosition = renderBox.localToGlobal(Offset.zero);
      final Size taskSize = renderBox.size;
      
      final Offset startPosition = Offset(
        taskPosition.dx + taskSize.width / 2,
        taskPosition.dy + taskSize.height / 2,
      );
      
      XPOrbOverlay.show(
        context: context,
        startPosition: startPosition,
        xpAmount: widget.task.xpReward,
      );
    }
  }

  Future<void> _revertAnimations() async {
    setState(() {
      _showRipples = false;
    });
    
    await Future.wait([
      _dissolveController.reverse(),
      _rippleController.reverse(),
    ]);
    
    _startIdleAnimation();
  }

  void _showSuccessMessage(TaskCompletionResult result) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Task completed! +${result.completedTask?.xpReward ?? 0} XP'),
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

  void _handleCompletionError(TaskCompletionResult result) {
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to complete task.'),
          backgroundColor: Colors.red,
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
    if (_idleController == null) return const SizedBox.shrink();

    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _dissolveController,
            _idleController,
          ]),
          builder: (context, child) {
            final idleOffset = _isCompleting ? 0.0 : 
              (math.sin(_idleFloatAnimation.value * math.pi * 2) * 1.0);
            
            return Transform.translate(
              offset: Offset(0, idleOffset),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child
                  ),
                ),
              ),
            );
          },
          child: Container(
              decoration: BoxDecoration(
              color: _colorShiftAnimation.value,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildTaskContent(Theme.of(context)),
            ),
          ),
        ),
        
        if (_showRipples)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RipplePainter(
                      animationValue: _rippleAnimation.value,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskContent(ThemeData theme) {
     return InkWell(
        onTap: () => _showTaskMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: _handleComplete,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.task.isCompleted 
                        ? Colors.transparent 
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
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: theme.textTheme.titleMedium,
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
                ],
              ),
            ),
            if (widget.task.dueDate != null && widget.showTime) ...[
              const SizedBox(width: 16),
              Text(_formatDate(widget.task.dueDate!))
            ],
          ],
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
             ListTile(
              leading: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text('Edit Task', style: Theme.of(context).textTheme.titleMedium),
              onTap: () {
                Navigator.pop(context);
                if (widget.onEdit != null) {
                  widget.onEdit!();
                } else {
                  _showEditTaskDialog(context);
                }
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
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (DateUtils.isSameDay(date, now)) {
      return 'Today';
    } else if (DateUtils.isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }


  @override
  void dispose() {
    _dissolveController.dispose();
    _rippleController.dispose();
    _idleController.dispose();
    super.dispose();
  }
}

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  
  RipplePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.8;
    
    _paintRippleWave(canvas, center, maxRadius, 0, 0.0);
    _paintRippleWave(canvas, center, maxRadius, 1, 0.2);
    _paintRippleWave(canvas, center, maxRadius, 2, 0.4);
  }

  void _paintRippleWave(Canvas canvas, Offset center, double maxRadius, 
                       int waveIndex, double delay) {
    final waveProgress = (animationValue - delay).clamp(0.0, 1.0);
    
    if (waveProgress > 0) {
      final radius = maxRadius * waveProgress;
      final opacity = (1.0 - waveProgress) * (0.4 - waveIndex * 0.1);
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 - waveIndex;
      
      canvas.drawCircle(center, radius, paint);
      
      if (waveIndex == 0) {
        _paintSparkles(canvas, center, radius, waveProgress);
      }
    }
  }

  void _paintSparkles(Canvas canvas, Offset center, double radius, double progress) {
    final sparkleCount = 8;
    final sparklePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i * math.pi * 2 / sparkleCount) + (progress * math.pi);
      final sparkleRadius = 2.0 * (1.0 - progress);
      
      final sparklePosition = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      canvas.drawCircle(sparklePosition, sparkleRadius, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
} 