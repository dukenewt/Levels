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
  int _xpReward = 10;
  DateTime? _dueDate;
  TimeOfDay? _scheduledTime;
  String? _recurrencePattern;
  List<int>? _weeklyDays;
  int? _repeatInterval;
  DateTime? _endDate;
  String? _selectedSkillId;

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
        xpReward: _xpReward,
        dueDate: _dueDate,
        scheduledTime: _scheduledTime,
        recurrencePattern: _recurrencePattern == 'None' ? null : _recurrencePattern?.toLowerCase(),
        weeklyDays: _weeklyDays,
        repeatInterval: _repeatInterval,
        endDate: _endDate,
      );

      taskProvider.addTask(task);
      Navigator.of(context).pop();
    }
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
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _dueDate != null
                            ? '	${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
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
              Row(
                children: [
                  const Text('XP Reward:'),
                  Expanded(
                    child: Slider(
                      value: _xpReward.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
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