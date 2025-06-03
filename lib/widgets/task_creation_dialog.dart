import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/skill_provider.dart';

class TaskCreationDialog extends StatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const TaskCreationDialog({
    Key? key,
    this.initialDate,
    this.initialTime,
  }) : super(key: key);

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _xpReward = 0;
  String _difficulty = 'easy';
  int _minXp = 0;
  int _maxXp = 25;
  DateTime? _dueDate;
  TimeOfDay? _scheduledTime;
  String? _recurrencePattern;
  List<int>? _weeklyDays;
  int? _repeatInterval;
  DateTime? _endDate;
  String? _selectedSkillId;
  int _timeCostMinutes = 10;
  bool _showTimePicker = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

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
    _dueDate = widget.initialDate ?? DateTime.now();
    _scheduledTime = widget.initialTime ?? TimeOfDay.now();
    _updateXpRangeForDifficulty(_difficulty);
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

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: '',
        difficulty: _difficulty,
        xpReward: _xpReward,
        dueDate: _dueDate,
        scheduledTime: _showTimePicker ? _startTime : null,
        recurrencePattern: _recurrencePattern == 'None' ? null : _recurrencePattern?.toLowerCase(),
        weeklyDays: _weeklyDays,
        repeatInterval: _repeatInterval,
        endDate: _endDate,
        skillId: _selectedSkillId,
        timeCostMinutes: _timeCostMinutes,
      );
      taskProvider.createTask(task);
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

  void _updateTimeCost() {
    if (_showTimePicker && _startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      final diff = endMinutes - startMinutes;
      _timeCostMinutes = diff >= 5 ? diff : 5;
    }
  }

  TimeOfDay _roundToNearest5(TimeOfDay t) {
    int minute = (t.minute / 5).round() * 5;
    int hour = t.hour;
    if (minute == 60) {
      minute = 0;
      hour = (hour + 1) % 24;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final skillProvider = Provider.of<SkillProvider>(context);
    final skills = skillProvider.skills;
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
                'Create New Task',
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
              DropdownButtonFormField<String>(
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
                  setState(() {
                    _selectedSkillId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Date picker row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _dueDate != null
                              ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                              : 'No Date',
                          style: TextStyle(
                            color: _dueDate != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear Date',
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Time toggle row
              Row(
                children: [
                  Switch(
                    value: _showTimePicker,
                    onChanged: (value) {
                      setState(() {
                        _showTimePicker = value;
                        if (!_showTimePicker) {
                          _scheduledTime = null;
                          _startTime = null;
                          _endTime = null;
                          _timeCostMinutes = 10;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Text('Add Time'),
                ],
              ),
              // Time pickers row below the switch
              if (_showTimePicker) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? TimeOfDay(hour: 8, minute: 0),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _startTime = _roundToNearest5(picked);
                              // If end time is before start, reset end time
                              if (_endTime != null && (_endTime!.hour < _startTime!.hour || (_endTime!.hour == _startTime!.hour && _endTime!.minute <= _startTime!.minute))) {
                                _endTime = null;
                              }
                              _updateTimeCost();
                            });
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          _startTime != null
                              ? _startTime!.format(context)
                              : 'Start Time',
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? (_startTime != null ? _startTime!.replacing(minute: (_startTime!.minute + 5) % 60) : TimeOfDay(hour: 8, minute: 5)),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _endTime = _roundToNearest5(picked);
                              _updateTimeCost();
                            });
                          }
                        },
                        icon: const Icon(Icons.stop),
                        label: Text(
                          _endTime != null
                              ? _endTime!.format(context)
                              : 'End Time',
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                          initialValue: '1',
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
                            ? 'Ends ${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
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
                      min: 5,
                      max: 240,
                      divisions: 47,
                      label: '${_timeCostMinutes ~/ 60 > 0 ? '${_timeCostMinutes ~/ 60}h ' : ''}${_timeCostMinutes % 60 > 0 ? '${_timeCostMinutes % 60}m' : ''}',
                      onChanged: (value) {
                        setState(() {
                          _timeCostMinutes = (value ~/ 5) * 5;
                        });
                      },
                    ),
                  ),
                  Text('${_timeCostMinutes ~/ 60 > 0 ? '${_timeCostMinutes ~/ 60}h ' : ''}${_timeCostMinutes % 60 > 0 ? '${_timeCostMinutes % 60}m' : ''}'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _createTask,
                    child: const Text('Create Task'),
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