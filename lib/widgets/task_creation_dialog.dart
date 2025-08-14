import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../features/character_progression/application/intelligent_xp_engine.dart';
import '../core/theme/app_design_tokens.dart';
import 'package:intl/intl.dart';

class EnhancedTaskCreationDialog extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const EnhancedTaskCreationDialog({
    Key? key,
    this.initialDate,
    this.initialTime,
  }) : super(key: key);

  @override
  State<EnhancedTaskCreationDialog> createState() => _EnhancedTaskCreationDialogState();
}

class _EnhancedTaskCreationDialogState extends State<EnhancedTaskCreationDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Task properties
  String _difficulty = 'medium';
  String _category = 'Work';
  int _estimatedXp = 50;
  DateTime? _dueDate;
  TimeOfDay? _scheduledTime;
  String? _recurrencePattern;
  List<int>? _weeklyDays;
  int? _repeatInterval;
  DateTime? _endDate;
  int _timeInvestmentMinutes = 30;
  bool _showTimePicker = false;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _xpAnimationController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _xpScaleAnimation;
  
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
    _dueDate = widget.initialDate ?? DateTime.now();
    _scheduledTime = widget.initialTime;
    
    _setupAnimations();
    _updateEstimatedXp();
    
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
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _xpScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _xpAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
  }

  void _updateEstimatedXp() {
    final tempTask = Task(
      id: 'temp_xp_id',
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      difficulty: _difficulty,
      timeCostMinutes: _timeInvestmentMinutes,
    );
    
    final newXp = IntelligentXPEngine().calculateBaseXP(tempTask);
    if (newXp != _estimatedXp) {
      setState(() {
        _estimatedXp = newXp;
      });
      if (mounted) {
        _xpAnimationController.safeForward(from: 0.0);
      }
    }
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        difficulty: _difficulty,
        xpReward: _estimatedXp,
        dueDate: _dueDate,
        scheduledTime: _showTimePicker ? _scheduledTime : null,
        recurrencePattern: _recurrencePattern == 'None' ? null : _recurrencePattern?.toLowerCase(),
        weeklyDays: _weeklyDays,
        repeatInterval: _repeatInterval,
        endDate: _endDate,
        timeCostMinutes: _timeInvestmentMinutes,
      );
      
      taskProvider.createTask(context, task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
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
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_task,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Create New Task',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _xpScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _xpScaleAnimation.value,
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
                        '$_estimatedXp',
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
        onChanged: (_) => _updateEstimatedXp(),
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
        onChanged: (_) => _updateEstimatedXp(),
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
              _showTimePicker && _scheduledTime != null
                  ? _scheduledTime!.format(context)
                  : 'All day',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _showTimePicker
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
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
              prefixIcon: Icon(Icons.repeat, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            items: _recurrenceOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _recurrencePattern = newValue == 'None' ? null : newValue;
                _weeklyDays = null;
                _repeatInterval = null;
                _endDate = null;
              });
            },
          ),
        ),
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
                _updateEstimatedXp();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySection(ThemeData theme) {
    final difficultyColors = {
      'easy': Colors.green,
      'medium': Colors.orange,
      'hard': Colors.red,
      'epic': Colors.purple,
    };

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
              color: difficultyColors[_difficulty]?.withOpacity(0.3) ??
                  theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _difficulty,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.trending_up,
                color: difficultyColors[_difficulty] ?? theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            items: ['easy', 'medium', 'hard', 'epic'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: difficultyColors[value],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(value.substring(0, 1).toUpperCase() + value.substring(1)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _difficulty = newValue!;
                _updateEstimatedXp();
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Investment',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_timeInvestmentMinutes}m',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
                  value: _timeInvestmentMinutes.toDouble(),
                  min: 5,
                  max: 180,
                  divisions: 35,
                  onChanged: (double value) {
                    setState(() {
                      _timeInvestmentMinutes = value.round();
                      _updateEstimatedXp();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How long do you expect this task to take?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
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
            onPressed: _createTask,
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
                const Icon(Icons.add_task),
                const SizedBox(width: 8),
                const Text('Create Task'),
              ],
            ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _slideController.dispose();
    _xpAnimationController.dispose();
    super.dispose();
  }
}

// Keep the old class name for backwards compatibility
class TaskCreationDialog extends EnhancedTaskCreationDialog {
  const TaskCreationDialog({
    Key? key,
    DateTime? initialDate,
    TimeOfDay? initialTime,
  }) : super(key: key, initialDate: initialDate, initialTime: initialTime);
}