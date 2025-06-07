import 'package:flutter/material.dart';
import '../models/task.dart';
import '../core/theme/app_design_tokens.dart';
import 'dart:io' show Platform;

class ProfessionalTaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final bool showTime;

  const ProfessionalTaskTile({
    Key? key,
    required this.task,
    this.onComplete,
    this.onEdit,
    this.showTime = true,
  }) : super(key: key);

  @override
  State<ProfessionalTaskTile> createState() => _ProfessionalTaskTileState();
}

class _ProfessionalTaskTileState extends State<ProfessionalTaskTile>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _completeController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: AppDesignTokens.fast,
      vsync: this,
    );
    _completeController = AnimationController(
      duration: AppDesignTokens.slow,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _completeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ProfessionalTheme.isDesktop;
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _completeController]),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_hoverController.value * 0.02),
          child: Semantics(
            label: widget.task.title,
            hint: widget.task.description,
            button: true,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppDesignTokens.space3),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04 + (_hoverController.value * 0.04)),
                    blurRadius: 8 + (_hoverController.value * 8),
                    offset: Offset(0, 2 + (_hoverController.value * 4)),
                  ),
                ],
                border: Border.all(
                  color: widget.task.isCompleted 
                      ? ProfessionalTheme.success.withOpacity(0.3)
                      : ProfessionalTheme.neutral200,
                  width: 1 + (_hoverController.value * 0.5),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onEdit,
                  onHover: isDesktop
                      ? (isHovered) {
                          setState(() => _isHovered = isHovered);
                          if (isHovered) {
                            _hoverController.forward();
                          } else {
                            _hoverController.reverse();
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesignTokens.space4),
                    child: Row(
                      children: [
                        _buildCompletionButton(),
                        const SizedBox(width: AppDesignTokens.space3),
                        Expanded(child: _buildTaskContent(theme)),
                        _buildTaskMetadata(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionButton() {
    return GestureDetector(
      onTap: () {
        if (!widget.task.isCompleted) {
          _completeController.forward();
          widget.onComplete?.call();
        }
      },
      child: AnimatedContainer(
        duration: AppDesignTokens.fast,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.task.isCompleted 
              ? ProfessionalTheme.success 
              : Colors.transparent,
          border: Border.all(
            color: widget.task.isCompleted 
                ? ProfessionalTheme.success 
                : ProfessionalTheme.neutral300,
            width: 2,
          ),
        ),
        child: widget.task.isCompleted
            ? Transform.scale(
                scale: _completeController.value,
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTaskContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.task.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: widget.task.isCompleted 
                ? TextDecoration.lineThrough 
                : null,
            color: widget.task.isCompleted 
                ? ProfessionalTheme.neutral400 
                : ProfessionalTheme.neutral800,
          ),
        ),
        if (widget.task.description.isNotEmpty) ...[
          const SizedBox(height: AppDesignTokens.space1),
          Text(
            widget.task.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ProfessionalTheme.neutral500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (widget.showTime && widget.task.dueDate != null) ...[
          const SizedBox(height: AppDesignTokens.space2),
          _buildTimeChip(),
        ],
      ],
    );
  }

  Widget _buildTimeChip() {
    final isOverdue = widget.task.dueDate!.isBefore(DateTime.now());
    final isToday = DateTime.now().difference(widget.task.dueDate!).inDays == 0;
    Color chipColor;
    Color textColor;
    IconData icon;
    if (isOverdue) {
      chipColor = ProfessionalTheme.error.withOpacity(0.1);
      textColor = ProfessionalTheme.error;
      icon = Icons.warning_amber_rounded;
    } else if (isToday) {
      chipColor = ProfessionalTheme.warning.withOpacity(0.1);
      textColor = ProfessionalTheme.warning;
      icon = Icons.today_rounded;
    } else {
      chipColor = ProfessionalTheme.info.withOpacity(0.1);
      textColor = ProfessionalTheme.info;
      icon = Icons.schedule_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space2,
        vertical: AppDesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: AppDesignTokens.space1),
          Text(
            _formatTime(widget.task.dueDate!),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskMetadata(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space2,
            vertical: AppDesignTokens.space1,
          ),
          decoration: BoxDecoration(
            color: ProfessionalTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
          ),
          child: Text(
            '${widget.task.xpReward} XP',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ProfessionalTheme.accent,
            ),
          ),
        ),
        const SizedBox(height: AppDesignTokens.space1),
        _buildDifficultyIndicator(),
      ],
    );
  }

  Widget _buildDifficultyIndicator() {
    final difficultyColors = {
      'easy': ProfessionalTheme.success,
      'medium': ProfessionalTheme.warning,
      'hard': ProfessionalTheme.error,
      'epic': ProfessionalTheme.primary,
    };
    final color = difficultyColors[widget.task.difficulty] ?? ProfessionalTheme.neutral400;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < _getDifficultyLevel(widget.task.difficulty);
        return Container(
          width: 4,
          height: 12,
          margin: EdgeInsets.only(left: index > 0 ? 2 : 0),
          decoration: BoxDecoration(
            color: isActive ? color : ProfessionalTheme.neutral200,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  int _getDifficultyLevel(String difficulty) {
    switch (difficulty) {
      case 'easy': return 1;
      case 'medium': return 2;
      case 'hard': return 3;
      case 'epic': return 4;
      default: return 1;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    if (difference.isNegative) return 'Overdue';
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Tomorrow';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }
} 