import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/secure_task_provider.dart';
import '../services/enhanced_task_completion_service.dart';
import 'package:intl/intl.dart';

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
  String _difficulty = 'medium';
  String _category = 'Work'; // Default category
  int _estimatedXp = 0;
  DateTime? _dueDate;
  TimeOfDay? _scheduledTime;
  String? _recurrencePattern;
  List<int>? _weeklyDays;
  int? _repeatInterval;
  DateTime? _endDate;
  int _timeCostMinutes = 10;
  bool _showTimePicker = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final FocusNode _titleFocusNode = FocusNode();

  final List<String> _recurrenceOptions = [
    'None',
    'Daily',
    'Weekly',
    'Workdays',
    'Monthly',
  ];

  final List<String> _categoryOptions = [
    'Work', 'Learning', 'Health', 'Social', 'Creativity', 'Maintenance'
  ];

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDate ?? DateTime.now();
    _scheduledTime = widget.initialTime ?? TimeOfDay.now();
    _updateEstimatedXp();
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
        _updateEstimatedXp();
      });
    }
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<SecureTaskProvider>(context, listen: false);
      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        difficulty: _difficulty,
        xpReward: _estimatedXp, // Use estimated XP
        dueDate: _dueDate,
        scheduledTime: _showTimePicker ? _startTime : null,
        recurrencePattern: _recurrencePattern == 'None' ? null : _recurrencePattern?.toLowerCase(),
        weeklyDays: _weeklyDays,
        repeatInterval: _repeatInterval,
        endDate: _endDate,
        timeCostMinutes: _timeCostMinutes,
      );
      taskProvider.createTask(task);
      Navigator.of(context).pop();
    }
  }

  void _updateEstimatedXp() {
    final xp = EnhancedTaskCompletionService.calculateEstimatedXP(
      timeCostMinutes: _timeCostMinutes,
      category: _category,
      difficulty: _difficulty,
    );
    setState(() {
      _estimatedXp = xp;
    });
  }

  void _updateTimeCost() {
    if (_showTimePicker && _startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      final diff = endMinutes - startMinutes;
      _timeCostMinutes = diff >= 5 ? diff : 5;
      _updateEstimatedXp();
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
    // Request focus after build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_titleFocusNode);
      }
    });
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
                focusNode: _titleFocusNode,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length > 100) {
                    return 'Title cannot exceed 100 characters';
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
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Add Time switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Time'),
                  Switch(
                    value: _showTimePicker,
                    onChanged: (value) {
                      setState(() {
                        _showTimePicker = value;
                        if (value) {
                          _startTime = _roundToNearest5(TimeOfDay.now());
                          _endTime = _roundToNearest5(
                              TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 30))));
                          _updateTimeCost();
                        } else {
                          _updateEstimatedXp();
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_showTimePicker) _buildTimeRangePicker(context),
              const SizedBox(height: 16),
              // Recurrence dropdown
              _buildRecurrenceDropdown(),
              const SizedBox(height: 16),
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categoryOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                    _updateEstimatedXp();
                  });
                },
              ),
              const SizedBox(height: 16),
              // Difficulty dropdown
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                items: ['easy', 'medium', 'hard', 'epic'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.substring(0, 1).toUpperCase() + value.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _difficulty = newValue!;
                    _updateEstimatedXp();
                  });
                },
              ),
              const SizedBox(height: 16),
              // Time Cost and Estimated XP
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time Cost'),
                        Slider(
                          value: _timeCostMinutes.toDouble(),
                          min: 5,
                          max: 180,
                          divisions: 35,
                          label: '${_timeCostMinutes}m',
                          onChanged: (double value) {
                            setState(() {
                              _timeCostMinutes = value.round();
                              _updateEstimatedXp();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        '$_estimatedXp',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text('XP'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
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

  Widget _buildTimeRangePicker(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimePickerButton(context, _startTime!, (t) {
              setState(() {
                _startTime = t;
                if (_endTime!.hour * 60 + _endTime!.minute < _startTime!.hour * 60 + _startTime!.minute) {
                  _endTime = _startTime;
                }
                _updateTimeCost();
              });
            }),
            const Text('to'),
            _buildTimePickerButton(context, _endTime!, (t) {
              setState(() {
                _endTime = t;
                if (_endTime!.hour * 60 + _endTime!.minute < _startTime!.hour * 60 + _startTime!.minute) {
                  _startTime = _endTime;
                }
                _updateTimeCost();
              });
            }),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Duration: ${_timeCostMinutes} minutes',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTimePickerButton(
      BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimeChanged) {
    return TextButton(
        onPressed: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onTimeChanged(_roundToNearest5(picked));
          }
        },
        child: Text(_formatTime(initialTime)));
  }

  Widget _buildRecurrenceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _recurrencePattern ?? 'None',
          decoration: const InputDecoration(
            labelText: 'Repeat',
            border: OutlineInputBorder(),
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
              // Reset other recurrence fields when changing pattern
              _weeklyDays = null;
              _repeatInterval = null;
              _endDate = null;
            });
          },
        ),
        if (_recurrencePattern != null && _recurrencePattern != 'None')
          _buildRecurrenceOptions(),
      ],
    );
  }

  Widget _buildRecurrenceOptions() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recurrencePattern == 'Daily') ...[
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Repeat every (days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: '1',
              onChanged: (value) {
                _repeatInterval = int.tryParse(value) ?? 1;
              },
            ),
          ],
          if (_recurrencePattern == 'Weekly') ...[
            const Text('Repeat on:'),
            Wrap(
              spacing: 8.0,
              children: List.generate(7, (index) {
                final day = index + 1;
                final dayName = DateFormat.E().format(DateTime(2023, 1, day + 1));
                return ChoiceChip(
                  label: Text(dayName),
                  selected: _weeklyDays?.contains(day) ?? false,
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
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectEndDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'End Date (optional)',
                border: OutlineInputBorder(),
              ),
              child: Text(
                _endDate != null
                    ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                    : 'No end date',
                style: TextStyle(
                  color: _endDate != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}