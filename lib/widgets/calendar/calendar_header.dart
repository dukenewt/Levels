import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';
import '../../models/task.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(BuildContext, DateTime, DateTime) onDaySelected;

  const CalendarHeader({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  Widget _buildTaskDot(Task task, CalendarProvider provider) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: provider.getCategoryColor(task.category),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTaskDots(List<Task> tasks, CalendarProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: tasks.take(3).map((task) => _buildTaskDot(task, provider)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarProvider = Provider.of<CalendarProvider>(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: focusedDay,
            calendarFormat: calendarProvider.calendarFormat,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) => onDaySelected(context, selectedDay, focusedDay),
            eventLoader: calendarProvider.getEventsForDay,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: theme.textTheme.titleLarge!,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 1,
                  child: _buildTaskDots(events.cast<Task>(), calendarProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}