import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/intelligent_xp_engine.dart';
import '../core/theme/app_design_tokens.dart';
import 'package:intl/intl.dart';

class TaskEditingDialog extends StatefulWidget {
  final Task task;

  const TaskEditingDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskEditingDialog> createState() => _TaskEditingDialogState();
}

class _TaskEditingDialogState extends State<TaskEditingDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  // Task properties
  late int _xpReward;
  late String _difficulty;
  late String _category;
  late DateTime? _dueDate;
  late TimeOfDay? _scheduledTime;
  late String? _recurrencePattern;
  late List<int>? _weeklyDays;
  late int? _repeatInterval;
  late DateTime? _endDate;
  late int _timeCostMinutes;
  bool _showTimePicker = false;
  
  // Animation controllers
  AnimationController? _slideController;
  AnimationController? _xpAnimationController;
  
  // Animations
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;
  Animation<double>? _xpScaleAnimation;
  
  final FocusNode _titleFocusNode = FocusNode();

  final List<String> _recurrenceOptions = [
    'None', 'Daily', 'Weekly', 'Workdays', 'Monthly'
  ];

  final List<String> _categoryOptions = [
    'Work', 'Learning', 'Health', 'Social', 'Creativity', 'Maintenance'
  ];

  final Map<String, IconData> _categoryIcons = {
    'Work': Icons.work_outline,
    'Learning': Icons.school_outlined,
    'Health': Icons.favorite_outline,
    'Social': Icons.people_outline,
    'Creativity': Icons.palette_outlined,
    'Maintenance': Icons.home_repair_service_outlined,
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _xpReward = widget.task.xpReward;
    _difficulty = widget.task.difficulty;
    _category = widget.task.category;
    _dueDate = widget.task.dueDate;
    _scheduledTime = widget.task.scheduledTime;
    _showTimePicker = widget.task.scheduledTime != null;
    _recurrencePattern = widget.task.recurrencePattern?.capitalize();
    _weeklyDays = widget.task.weeklyDays;
    _repeatInterval = widget.task.repeatInterval;
    _endDate = widget.task.endDate;
    _timeCostMinutes = widget.task.timeCostMinutes;
    
    _setupAnimations();
    
    // Auto-focus title field after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_titleFocusNode);
      }
    });
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _xpScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _xpAnimationController!,
      curve: Curves.elasticOut,
    ));
    
    _slideController!.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _slideController?.dispose();
    _xpAnimationController?.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      difficulty: _difficulty,
      category: _category,
      xpReward: _xpReward,
      dueDate: _dueDate,
      scheduledTime: _showTimePicker ? _scheduledTime : null,
      recurrencePattern: _recurrencePattern == 'None' ? null : _recurrencePattern?.toLowerCase(),
      weeklyDays: _weeklyDays,
      repeatInterval: _repeatInterval,
      endDate: _endDate,
      timeCostMinutes: _timeCostMinutes,
    );

    taskProvider.updateTask(updatedTask);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return _slideAnimation != null && _fadeAnimation != null
        ? SlideTransition(
            position: _slideAnimation!,
            child: FadeTransition(
              opacity: _fadeAnimation!,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 700),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildTitleField(theme),
                                  const SizedBox(height: 20),
                                  _buildDescriptionField(theme),
                                  const SizedBox(height: 24),
                                  _buildDateTimeSection(theme),
                                  const SizedBox(height: 24),
                                  _buildRecurrenceSection(theme),
                                  const SizedBox(height: 24),
                                  _buildCategorySection(theme),
                                  const SizedBox(height: 24),
                                  _buildDifficultySection(theme),
                                  const SizedBox(height: 24),
                                  _buildTimeInvestmentSection(theme),
                                  const SizedBox(height: 32),
                                  _buildActionButtons(theme),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        : Container(); // Fallback while animations are loading
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
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edit Task',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _xpScaleAnimation != null 
            ? AnimatedBuilder(
                animation: _xpScaleAnimation!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _xpScaleAnimation!.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_xpReward',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'XP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_xpReward',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'XP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        maxLength: 100,
        decoration: InputDecoration(
          labelText: 'Task Title',
          hintText: 'What do you want to accomplish?',
          prefixIcon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          counterText: '',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a task title';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Description (Optional)',
          hintText: 'Add more details...',
          prefixIcon: Icon(Icons.notes_outlined, color: theme.colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateCard(theme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeToggleCard(theme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateCard(ThemeData theme) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              'Due Date',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _dueDate != null
                  ? DateFormat('MMM d, yyyy').format(_dueDate!)
                  : 'Select date',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeToggleCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _showTimePicker
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showTimePicker
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.access_time,
                color: _showTimePicker
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
              Switch(
                value: _showTimePicker,
                onChanged: (value) {
                  setState(() {
                    _showTimePicker = value;
                    if (value && _scheduledTime == null) {
                      _scheduledTime = TimeOfDay.now();
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add Time',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _showTimePicker ? () => _selectTime(context) : null,
            child: Text(
              _showTimePicker
                  ? (_scheduledTime?.format(context) ?? 'Select time')
                  : 'All day',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _showTimePicker 
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _recurrencePattern ?? 'None',
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.repeat,
                color: theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            items: _recurrenceOptions.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _recurrencePattern = value;
                if (value != 'Weekly') {
                  _weeklyDays = null;
                }
                if (value == 'None') {
                  _endDate = null;
                  _repeatInterval = null;
                }
              });
            },
          ),
        ),
        if (_recurrencePattern != null && _recurrencePattern != 'None') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (_recurrencePattern == 'Daily') ...[
                const Text('Every'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _repeatInterval?.toString() ?? '1',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (value) {
                      _repeatInterval = int.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('days'),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () => _selectEndDate(context),
                icon: const Icon(Icons.event),
                label: Text(
                  _endDate != null
                      ? 'Ends ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                      : 'Set End Date',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              prefixIcon: Icon(
                _categoryIcons[_category] ?? Icons.category,
                color: theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            items: _categoryOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Icon(
                      _categoryIcons[value] ?? Icons.category,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(value),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _category = newValue!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _difficulty,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.bar_chart,
                color: theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            items: const [
              DropdownMenuItem(value: 'easy', child: Text('Easy')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'hard', child: Text('Hard')),
              DropdownMenuItem(value: 'epic', child: Text('Epic')),
            ],
            onChanged: (value) {
              setState(() {
                _difficulty = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInvestmentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Investment',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time Cost:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_timeCostMinutes ~/ 60 > 0 ? '${_timeCostMinutes ~/ 60}h ' : ''}${_timeCostMinutes % 60 > 0 ? '${_timeCostMinutes % 60}m' : ''}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _timeCostMinutes.toDouble(),
                min: 10,
                max: 240,
                divisions: 23,
                onChanged: (value) {
                  setState(() {
                    _timeCostMinutes = (value ~/ 10) * 10;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Reward:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$_xpReward XP',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _xpReward.toDouble(),
                min: 10,
                max: 200,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _xpReward = value.round();
                  });
                  _xpAnimationController?.forward(from: 0.0);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save),
                    const SizedBox(width: 8),
                    const Text('Save Changes'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            final taskProvider = Provider.of<TaskProvider>(context, listen: false);
            taskProvider.deleteTask(widget.task.id);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text('Delete Task', style: TextStyle(color: Colors.red)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _scheduledTime) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 