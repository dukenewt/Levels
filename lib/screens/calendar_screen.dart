import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  DateTime _calculateNextOccurrence(Task task, DateTime startDate) {
    if (task.recurrencePattern == null || task.dueDate == null) {
      return task.dueDate!;
    }

    DateTime nextDate = task.dueDate!;
    while (nextDate.isBefore(startDate)) {
      switch (task.recurrencePattern) {
        case 'daily':
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDate = DateTime(
            nextDate.year + (nextDate.month == 12 ? 1 : 0),
            nextDate.month == 12 ? 1 : nextDate.month + 1,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
      }
    }
    return nextDate;
  }

  void _loadEvents() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = taskProvider.tasks;
    
    _events = {};
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 365)); // Show events for the next year

    for (var task in tasks) {
      // Skip completed tasks
      if (task.isCompleted) continue;
      
      if (task.dueDate != null) {
        DateTime currentDate = task.dueDate!;
        
        // Only add the initial occurrence if it's not in the past
        if (!currentDate.isBefore(now)) {
          final date = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          );
          if (_events[date] == null) _events[date] = [];
          _events[date]!.add(task);
        }

        // If it's a recurring task, add future occurrences
        if (task.recurrencePattern != null) {
          while (currentDate.isBefore(endDate)) {
            currentDate = _calculateNextOccurrence(task, currentDate.add(const Duration(days: 1)));
            if (currentDate.isBefore(endDate)) {
              final futureDate = DateTime(
                currentDate.year,
                currentDate.month,
                currentDate.day,
              );
              if (_events[futureDate] == null) _events[futureDate] = [];
              _events[futureDate]!.add(task);
            }
          }
        }
      }
    }
  }

  List<Task> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Color(0xFFFF8A43),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text('Select a day to view tasks'),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _getEventsForDay(_selectedDay!).map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TaskTile(
                          task: task,
                          onComplete: () {
                            Provider.of<TaskProvider>(context, listen: false)
                                .completeTask(task.id);
                            _loadEvents(); // Reload events after completing a task
                          },
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
} 