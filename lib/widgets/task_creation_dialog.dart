import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../services/enhanced_xp_calculation_service.dart';
import '../services/task_analyzer_service.dart';
import '../services/pure_effect_engine.dart' as pe;
import '../core/theme/app_design_tokens.dart';
import 'package:intl/intl.dart';
import 'recurrence_pattern_dialog.dart';

class EnhancedTaskCreationDialog extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const EnhancedTaskCreationDialog({
    Key? key,
    this.initialDate,
    this.initialTime,
  }) : super(key: key);

  @override
  State<EnhancedTaskCreationDialog> createState() =>
      _EnhancedTaskCreationDialogState();
}

class _EnhancedTaskCreationDialogState extends State<EnhancedTaskCreationDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Task properties
  TaskDifficulty _difficulty = TaskDifficulty.medium;
  String _category = 'Work';
  int _estimatedXp = 50;
  DateTime? _dueDate;
  TimeOfDay? _scheduledTime;
  RecurrenceSettings _recurrenceSettings = const RecurrenceSettings();
  int _timeInvestmentMinutes = 30;
  bool _showTimePicker = false;

  // Perk and talent system properties
  List<String> _activePerkEffects = [];
  int _perkBonusXp = 0;
  String? _nlpSuggestedCategory;
  bool _showPerkEffects = false;

  // Animation controllers
  late AnimationController _xpAnimationController;

  // Animations
  late Animation<double> _xpScaleAnimation;

  final FocusNode _titleFocusNode = FocusNode();

  final List<String> _categoryOptions = [
    'Work',
    'Learning',
    'Health',
    'Social',
    'Creativity',
    'Maintenance'
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
    _validateAndUpdateDifficulty();
    _updateEstimatedXp();

    // Auto-focus title field after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_titleFocusNode);
      }
    });
  }

  void _setupAnimations() {
    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _xpScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _xpAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _onTitleChanged(String title) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) return;

    // Apply NLP analysis if user has the talent
    if (user.hasNLPTalent()) {
      final analysis = TaskAnalyzerService.analyzeTask(
        title,
        hasProjectManagementTalent: user.hasProjectManagementTalent(),
        hasNLPTalent: user.hasNLPTalent(),
      );

      setState(() {
        // Auto-assign category if suggested
        if (analysis.suggestedCategory != null &&
            analysis.isHighConfidence &&
            _categoryOptions.contains(analysis.suggestedCategory)) {
          _category = analysis.suggestedCategory!;
          _nlpSuggestedCategory = analysis.suggestedCategory;
        }

        // Auto-assign difficulty if suggested
        final suggestedDifficulty =
            TaskDifficulty.fromString(analysis.suggestedDifficulty);
        if (suggestedDifficulty != _difficulty) {
          _difficulty = suggestedDifficulty;
        }
      });
      // Ensure suggested difficulty respects allowed set (no Epic here)
      _validateAndUpdateDifficulty();
    }

    _updateEstimatedXp();
  }

  void _validateAndUpdateDifficulty() {
    final availableDifficulties = _getAvailableDifficulties();

    // If current difficulty is not available, reset to medium
    if (!availableDifficulties.contains(_difficulty)) {
      setState(() {
        _difficulty = TaskDifficulty.medium;
      });
    }
  }

  List<TaskDifficulty> _getAvailableDifficulties() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null)
      return const [
        TaskDifficulty.easy,
        TaskDifficulty.medium,
        TaskDifficulty.hard,
      ];

    // Use enhanced XP calculation service to get available difficulties
    final enhancedService = EnhancedXPCalculationService();
    // Regular task creation: do not include Epic difficulty
    return enhancedService.getAvailableDifficulties(user, includeEpic: false);
  }

  void _updateEstimatedXp() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) return;

    final tempTask = Task(
      id: 'temp_xp_id',
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      difficulty: _difficulty,
      timeCostMinutes: _timeInvestmentMinutes,
    );

    // Use enhanced XP calculation service with perk effects
    final enhancedService = EnhancedXPCalculationService();
    final xpPreview = enhancedService.getXPPreview(user, tempTask);

    final newXp = xpPreview['totalXP'] as int;
    final perkBonus = xpPreview['perkBonus'] as int;

    if (newXp != _estimatedXp || perkBonus != _perkBonusXp) {
      setState(() {
        _estimatedXp = newXp;
        _perkBonusXp = perkBonus;
        _activePerkEffects = pe.PureEffectEngine.getEffectPreview(
            user: user, category: _category);
        _showPerkEffects = _activePerkEffects.isNotEmpty;
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
        recurrencePattern: _recurrenceSettings.type == RecurrenceType.none
            ? null
            : _recurrenceSettings.type.name,
        weeklyDays: _recurrenceSettings.weeklyDays.isEmpty
            ? null
            : _recurrenceSettings.weeklyDays,
        repeatInterval: _recurrenceSettings.interval == 1
            ? null
            : _recurrenceSettings.interval,
        endDate: _recurrenceSettings.endDate,
        timeCostMinutes: _timeInvestmentMinutes,
      );

      taskProvider.createTask(context, task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 100),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetHandle(theme),
              _buildHeader(theme),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                          if (_showPerkEffects) ...[
                            _buildPerkEffectsSection(theme),
                            const SizedBox(height: 24),
                          ],
                          _buildTimeInvestmentSection(theme),
                          const SizedBox(height: 32),
                          _buildActionButtons(theme),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetHandle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Create a new Task',
              style: theme.textTheme.titleLarge?.copyWith(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          fontSize: 16,
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
        onChanged: _onTitleChanged,
        decoration: InputDecoration(
          labelText: 'Task Title',
          hintText: 'What do you want to accomplish?',
          prefixIcon:
              Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
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
          prefixIcon:
              Icon(Icons.notes_outlined, color: theme.colorScheme.primary),
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
        InkWell(
          onTap: () => _showRecurrenceDialog(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _recurrenceSettings.type != RecurrenceType.none
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _recurrenceSettings.type != RecurrenceType.none
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: _recurrenceSettings.type != RecurrenceType.none
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurrence Pattern',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _recurrenceSettings.description,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _recurrenceSettings.type != RecurrenceType.none
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
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
      TaskDifficulty.easy: Colors.green,
      TaskDifficulty.medium: Colors.orange,
      TaskDifficulty.hard: Colors.red,
      TaskDifficulty.epic: Colors.purple,
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
          child: DropdownButtonFormField<TaskDifficulty>(
            value: _difficulty,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.trending_up,
                color:
                    difficultyColors[_difficulty] ?? theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            items: _getAvailableDifficulties().map((TaskDifficulty value) {
              return DropdownMenuItem<TaskDifficulty>(
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
                    Text(value.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (TaskDifficulty? newValue) {
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
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 20),
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

  Widget _buildPerkEffectsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.stars_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Active Perk Effects',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_nlpSuggestedCategory != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Smart categorized as $_nlpSuggestedCategory',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              ..._activePerkEffects
                  .map((effect) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              effect,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              if (_perkBonusXp > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+$_perkBonusXp XP Bonus',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showRecurrenceDialog() async {
    final result = await showDialog<RecurrenceSettings>(
      context: context,
      builder: (context) => RecurrencePatternDialog(
        initialSettings: _recurrenceSettings,
        baseDate: _dueDate,
      ),
    );

    if (result != null) {
      setState(() {
        _recurrenceSettings = result;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
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
