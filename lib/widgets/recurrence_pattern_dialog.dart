import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

enum MonthlyPattern {
  dayOfMonth, // e.g., 15th of every month
  dayOfWeek,  // e.g., 2nd Tuesday of every month
}

class RecurrenceSettings {
  final RecurrenceType type;
  final int interval;
  final List<int> weeklyDays; // 1=Monday, 7=Sunday
  final MonthlyPattern? monthlyPattern;
  final int? monthlyDayOfMonth;
  final int? monthlyWeekOfMonth; // 1st, 2nd, 3rd, 4th, -1=last
  final int? monthlyDayOfWeek; // 1=Monday, 7=Sunday
  final DateTime? endDate;
  final int? maxOccurrences;
  final bool skipWeekends;

  const RecurrenceSettings({
    this.type = RecurrenceType.none,
    this.interval = 1,
    this.weeklyDays = const [],
    this.monthlyPattern,
    this.monthlyDayOfMonth,
    this.monthlyWeekOfMonth,
    this.monthlyDayOfWeek,
    this.endDate,
    this.maxOccurrences,
    this.skipWeekends = false,
  });

  RecurrenceSettings copyWith({
    RecurrenceType? type,
    int? interval,
    List<int>? weeklyDays,
    MonthlyPattern? monthlyPattern,
    int? monthlyDayOfMonth,
    int? monthlyWeekOfMonth,
    int? monthlyDayOfWeek,
    DateTime? endDate,
    int? maxOccurrences,
    bool? skipWeekends,
  }) {
    return RecurrenceSettings(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      monthlyPattern: monthlyPattern ?? this.monthlyPattern,
      monthlyDayOfMonth: monthlyDayOfMonth ?? this.monthlyDayOfMonth,
      monthlyWeekOfMonth: monthlyWeekOfMonth ?? this.monthlyWeekOfMonth,
      monthlyDayOfWeek: monthlyDayOfWeek ?? this.monthlyDayOfWeek,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      skipWeekends: skipWeekends ?? this.skipWeekends,
    );
  }

  String get description {
    switch (type) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        if (interval == 1) {
          return skipWeekends ? 'Daily (weekdays only)' : 'Daily';
        } else {
          return 'Every $interval days${skipWeekends ? ' (skip weekends)' : ''}';
        }
      case RecurrenceType.weekly:
        if (interval == 1 && weeklyDays.length == 7) {
          return 'Daily';
        } else if (interval == 1 && weeklyDays.length == 5 && 
                   weeklyDays.every((day) => day <= 5)) {
          return 'Weekdays';
        } else if (interval == 1 && weeklyDays.length == 1) {
          return 'Weekly on ${_getDayName(weeklyDays.first)}';
        } else if (interval == 1) {
          final dayNames = weeklyDays.map(_getDayName).join(', ');
          return 'Weekly on $dayNames';
        } else {
          final dayNames = weeklyDays.map(_getDayName).join(', ');
          return 'Every $interval weeks on $dayNames';
        }
      case RecurrenceType.monthly:
        if (monthlyPattern == MonthlyPattern.dayOfMonth) {
          if (interval == 1) {
            return 'Monthly on day $monthlyDayOfMonth';
          } else {
            return 'Every $interval months on day $monthlyDayOfMonth';
          }
        } else {
          final weekName = _getWeekOfMonthName(monthlyWeekOfMonth!);
          final dayName = _getDayName(monthlyDayOfWeek!);
          if (interval == 1) {
            return 'Monthly on $weekName $dayName';
          } else {
            return 'Every $interval months on $weekName $dayName';
          }
        }
      case RecurrenceType.yearly:
        if (interval == 1) {
          return 'Annually';
        } else {
          return 'Every $interval years';
        }
      case RecurrenceType.custom:
        return 'Custom pattern';
    }
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  String _getWeekOfMonthName(int week) {
    switch (week) {
      case 1: return 'first';
      case 2: return 'second';
      case 3: return 'third';
      case 4: return 'fourth';
      case -1: return 'last';
      default: return '${week}th';
    }
  }
}

class RecurrencePatternDialog extends StatefulWidget {
  final RecurrenceSettings initialSettings;
  final DateTime? baseDate;

  const RecurrencePatternDialog({
    Key? key,
    this.initialSettings = const RecurrenceSettings(),
    this.baseDate,
  }) : super(key: key);

  @override
  State<RecurrencePatternDialog> createState() => _RecurrencePatternDialogState();
}

class _RecurrencePatternDialogState extends State<RecurrencePatternDialog> {
  late RecurrenceSettings _settings;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            Flexible(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildRecurrenceTypePage(theme),
                  _buildRecurrenceDetailsPage(theme),
                  _buildEndConditionsPage(theme),
                ],
              ),
            ),
            _buildNavigationButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final titles = ['Repeat Pattern', 'Details', 'End Conditions'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.repeat,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titles[_currentPage],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentPage;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceTypePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How often should this repeat?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _buildRecurrenceTypeOptions(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecurrenceTypeOptions(ThemeData theme) {
    final options = [
      (RecurrenceType.none, Icons.close, 'Does not repeat'),
      (RecurrenceType.daily, Icons.today, 'Daily'),
      (RecurrenceType.weekly, Icons.view_week, 'Weekly'),
      (RecurrenceType.monthly, Icons.calendar_month, 'Monthly'),
      (RecurrenceType.yearly, Icons.event_repeat, 'Yearly'),
    ];

    return options.map((option) {
      final type = option.$1;
      final icon = option.$2;
      final label = option.$3;
      final isSelected = _settings.type == type;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            setState(() {
              _settings = _settings.copyWith(type: type);
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRecurrenceDetailsPage(ThemeData theme) {
    if (_settings.type == RecurrenceType.none) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No additional settings needed for non-repeating tasks.'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntervalSection(theme),
            const SizedBox(height: 16),
            if (_settings.type == RecurrenceType.weekly) ...[
              _buildWeeklyDaysSection(theme),
              const SizedBox(height: 16),
            ],
            if (_settings.type == RecurrenceType.monthly) ...[
              _buildMonthlyPatternSection(theme),
              const SizedBox(height: 16),
            ],
            _buildSkipWeekendsSection(theme),
            const SizedBox(height: 16),
            _buildPreviewSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSection(ThemeData theme) {
    String unitName;
    switch (_settings.type) {
      case RecurrenceType.daily:
        unitName = 'day${_settings.interval > 1 ? 's' : ''}';
        break;
      case RecurrenceType.weekly:
        unitName = 'week${_settings.interval > 1 ? 's' : ''}';
        break;
      case RecurrenceType.monthly:
        unitName = 'month${_settings.interval > 1 ? 's' : ''}';
        break;
      case RecurrenceType.yearly:
        unitName = 'year${_settings.interval > 1 ? 's' : ''}';
        break;
      default:
        unitName = 'period';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat every',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  initialValue: _settings.interval.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    final interval = int.tryParse(value) ?? 1;
                    setState(() {
                      _settings = _settings.copyWith(
                        interval: interval.clamp(1, 99),
                      );
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                unitName,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyDaysSection(ThemeData theme) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat on',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final buttonWidth = (availableWidth - (6 * 8)) / 7; // 6 spaces between 7 buttons
            
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
            final dayNumber = index + 1;
            final isSelected = _settings.weeklyDays.contains(dayNumber);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  final newDays = List<int>.from(_settings.weeklyDays);
                  if (isSelected) {
                    newDays.remove(dayNumber);
                  } else {
                    newDays.add(dayNumber);
                  }
                  newDays.sort();
                  _settings = _settings.copyWith(weeklyDays: newDays);
                });
              },
              child: Container(
                width: buttonWidth.clamp(32.0, 44.0),
                height: buttonWidth.clamp(32.0, 44.0),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(buttonWidth.clamp(16.0, 22.0)),
                ),
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: (buttonWidth * 0.25).clamp(10.0, 14.0),
                    ),
                  ),
                ),
              ),
            );
          }),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _settings = _settings.copyWith(weeklyDays: [1, 2, 3, 4, 5]);
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Weekdays', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _settings = _settings.copyWith(weeklyDays: [6, 7]);
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Weekends', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _settings = _settings.copyWith(weeklyDays: [1, 2, 3, 4, 5, 6, 7]);
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('All Days', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyPatternSection(ThemeData theme) {
    final baseDate = widget.baseDate ?? DateTime.now();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly pattern',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<MonthlyPattern>(
          title: Text('Day ${baseDate.day} of each month'),
          value: MonthlyPattern.dayOfMonth,
          groupValue: _settings.monthlyPattern,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(
                monthlyPattern: value,
                monthlyDayOfMonth: baseDate.day,
              );
            });
          },
        ),
        RadioListTile<MonthlyPattern>(
          title: Text('${_getWeekOfMonth(baseDate)} ${_getDayOfWeekName(baseDate.weekday)} of each month'),
          value: MonthlyPattern.dayOfWeek,
          groupValue: _settings.monthlyPattern,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(
                monthlyPattern: value,
                monthlyWeekOfMonth: _calculateWeekOfMonth(baseDate),
                monthlyDayOfWeek: baseDate.weekday,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildSkipWeekendsSection(ThemeData theme) {
    return Row(
      children: [
        Checkbox(
          value: _settings.skipWeekends,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(skipWeekends: value ?? false);
            });
          },
        ),
        Expanded(
          child: Text(
            'Skip weekends',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _settings.description,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEndConditionsPage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'When should this stop repeating?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioListTile<String>(
                    title: const Text('Never'),
                    value: 'never',
                    groupValue: _getEndConditionType(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          endDate: null,
                          maxOccurrences: null,
                        );
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('On a specific date'),
                    value: 'date',
                    groupValue: _getEndConditionType(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          endDate: DateTime.now().add(const Duration(days: 30)),
                          maxOccurrences: null,
                        );
                      });
                    },
                  ),
                  if (_settings.endDate != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32, right: 16),
                      child: InkWell(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_settings.endDate!),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                  RadioListTile<String>(
                    title: const Text('After a number of occurrences'),
                    value: 'count',
                    groupValue: _getEndConditionType(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                          endDate: null,
                          maxOccurrences: 10,
                        );
                      });
                    },
                  ),
                  if (_settings.maxOccurrences != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32, right: 16),
                      child: Row(
                        children: [
                          const Text('After'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: _settings.maxOccurrences.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (value) {
                                final count = int.tryParse(value) ?? 10;
                                setState(() {
                                  _settings = _settings.copyWith(
                                    maxOccurrences: count.clamp(1, 999),
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('occurrences'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < 2 && _settings.type != RecurrenceType.none) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.of(context).pop(_settings);
                }
              },
              child: Text(_currentPage < 2 && _settings.type != RecurrenceType.none ? 'Next' : 'Done'),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getEndConditionType() {
    if (_settings.endDate != null) return 'date';
    if (_settings.maxOccurrences != null) return 'count';
    return 'never';
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _settings.endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _settings = _settings.copyWith(endDate: picked);
      });
    }
  }

  String _getWeekOfMonth(DateTime date) {
    final week = _calculateWeekOfMonth(date);
    switch (week) {
      case 1: return 'First';
      case 2: return 'Second';
      case 3: return 'Third';
      case 4: return 'Fourth';
      case -1: return 'Last';
      default: return '${week}th';
    }
  }

  int _calculateWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    
    // Check if it's in the last week
    final daysFromEnd = lastDayOfMonth.day - date.day;
    if (daysFromEnd < 7 && lastDayOfMonth.subtract(Duration(days: daysFromEnd)).weekday == date.weekday) {
      return -1; // Last occurrence
    }
    
    // Calculate which week (1-based)
    return ((date.day - 1) ~/ 7) + 1;
  }

  String _getDayOfWeekName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}