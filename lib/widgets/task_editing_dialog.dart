import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_creation_dialog.dart';
import '../providers/skill_provider.dart';

class TaskEditingDialog extends StatefulWidget {
  final Task task;

  const TaskEditingDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskEditingDialog> createState() => _TaskEditingDialogState();
}

class _TaskEditingDialogState extends State<TaskEditingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _xpReward;
  late String _difficulty;
  int _minXp = 0;
  int _maxXp = 25;
  late DateTime? _dueDate;
  late TimeOfDay? _scheduledTime;
  late String? _recurrencePattern;
  late List<int>? _weeklyDays;
  late int? _repeatInterval;
  late DateTime? _endDate;
  late String? _selectedSkillId;
  int _timeCostMinutes = 10;

  final List<String> _recurrenceOptions = [
    'None',
    'Daily',
    'Weekly',
    'Workdays',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _xpReward = widget.task.xpReward;
    _difficulty = widget.task.difficulty;
    _updateXpRangeForDifficulty(_difficulty);
    _dueDate = widget.task.dueDate;
    _scheduledTime = widget.task.scheduledTime;
    _recurrencePattern = widget.task.recurrencePattern?.capitalize();
    _weeklyDays = widget.task.weeklyDays;
    _repeatInterval = widget.task.repeatInterval;
    _endDate = widget.task.endDate;
    _selectedSkillId = widget.task.skillId;
    _timeCostMinutes = widget.task.timeCostMinutes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  void _updateTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      final updatedTask = widget.task.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        difficulty: _difficulty,
        xpReward: _xpReward,
        dueDate: _dueDate,
        scheduledTime: _scheduledTime,
        recurrencePattern: _recurrencePattern == 'None' ? null : _recurrencePattern?.toLowerCase(),
        weeklyDays: _weeklyDays,
        repeatInterval: _repeatInterval,
        endDate: _endDate,
        skillId: _selectedSkillId,
        timeCostMinutes: _timeCostMinutes,
      );

      taskProvider.updateTask(updatedTask);
      Navigator.of(context).pop();
    }
  }

  void _updateXpRangeForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'easy':
        _minXp = 0;
        _maxXp = 25;
        break;
      case 'medium':
        _minXp = 25;
        _maxXp = 50;
        break;
      case 'hard':
        _minXp = 50;
        _maxXp = 100;
        break;
      case 'epic':
        _minXp = 100;
        _maxXp = 250;
        break;
      default:
        _minXp = 0;
        _maxXp = 25;
    }
    if (_xpReward < _minXp) _xpReward = _minXp;
    if (_xpReward > _maxXp) _xpReward = _maxXp;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Task',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Skill group dropdown
              Builder(
                builder: (context) {
                  final skillProvider = Provider.of<SkillProvider>(context);
                  final skills = skillProvider.skills;
                  return StatefulBuilder(
                    builder: (context, setStateSB) {
                      return DropdownButtonFormField<String>(
                        value: _selectedSkillId,
                        decoration: InputDecoration(
                          labelText: 'Related Skill',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'None',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          ...skills.map((skill) => DropdownMenuItem<String>(
                                value: skill.id,
                                child: Text(skill.name),
                              )),
                        ],
                        onChanged: (value) {
                          setStateSB(() {
                            _selectedSkillId = value;
                          });
                          setState(() {}); // To update parent state on change
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Select Date',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _scheduledTime != null
                            ? _scheduledTime!.format(context)
                            : 'Select Time',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurrencePattern ?? 'None',
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  border: OutlineInputBorder(),
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
              if (_recurrencePattern == 'Weekly') ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = _weeklyDays?.contains(day) ?? false;
                    return FilterChip(
                      label: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _weeklyDays ??= [];
                          if (selected) {
                            _weeklyDays!.add(day);
                          } else {
                            _weeklyDays!.remove(day);
                          }
                          _weeklyDays!.sort();
                        });
                      },
                    );
                  }),
                ),
              ],
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
                            ? 'Ends ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Set End Date',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
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
                    _updateXpRangeForDifficulty(_difficulty);
                    _xpReward = _minXp;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('XP Reward:'),
                  Expanded(
                    child: Slider(
                      value: _xpReward.toDouble(),
                      min: _minXp.toDouble(),
                      max: _maxXp.toDouble(),
                      divisions: (_maxXp - _minXp) > 0 ? (_maxXp - _minXp) : 1,
                      label: _xpReward.toString(),
                      onChanged: (value) {
                        setState(() {
                          _xpReward = value.round();
                        });
                      },
                    ),
                  ),
                  Text(_xpReward.toString()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Time Cost:'),
                  Expanded(
                    child: Slider(
                      value: _timeCostMinutes.toDouble(),
                      min: 10,
                      max: 240,
                      divisions: 23,
                      label: '${_timeCostMinutes ~/ 60 > 0 ? '${_timeCostMinutes ~/ 60}h ' : ''}${_timeCostMinutes % 60 > 0 ? '${_timeCostMinutes % 60}m' : ''}',
                      onChanged: (value) {
                        setState(() {
                          _timeCostMinutes = (value ~/ 10) * 10;
                        });
                      },
                    ),
                  ),
                  Text('${_timeCostMinutes ~/ 60 > 0 ? '${_timeCostMinutes ~/ 60}h ' : ''}${_timeCostMinutes % 60 > 0 ? '${_timeCostMinutes % 60}m' : ''}'),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                      taskProvider.deleteTask(widget.task.id);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _updateTask,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 