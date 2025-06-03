import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../task_tile.dart';

class WeekCalendarView extends StatelessWidget {
  final DateTime focusedDay;

  const WeekCalendarView({Key? key, required this.focusedDay}) : super(key: key);

  Future<Map<DateTime, List<Task>>> _loadWeekTasks(TaskProvider taskProvider, DateTime focusedDay) async {
    final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final Map<DateTime, List<Task>> weekTasks = {};
    for (final day in days) {
      final tasks = await taskProvider.getTasksForDate(day);
      weekTasks[day] = tasks.where((t) => !t.isCompleted).toList();
    }
    return weekTasks;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final theme = Theme.of(context);
    const double hourHeight = 60.0;

    return FutureBuilder<Map<DateTime, List<Task>>>(
      future: _loadWeekTasks(taskProvider, focusedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading tasks'));
        }
        final weekTasks = snapshot.data ?? {};
        // Find earliest scheduled task for the week
        int? earliestHour;
        int? earliestMinute;
        for (final day in days) {
          final tasks = weekTasks[day]?.where((t) => t.scheduledTime != null).toList() ?? [];
          for (final task in tasks) {
            final h = task.scheduledTime!.hour;
            final m = task.scheduledTime!.minute;
            if (earliestHour == null || h < earliestHour || (h == earliestHour && m < (earliestMinute ?? 60))) {
              earliestHour = h;
              earliestMinute = m;
            }
          }
        }
        int scrollToHour = (earliestHour ?? 0) - 1;
        if (scrollToHour < 0) scrollToHour = 0;
        final double initialScrollOffset = scrollToHour * hourHeight;
        final ScrollController _weekVerticalScrollController = ScrollController(initialScrollOffset: initialScrollOffset);

        // Overlapping groups logic
        List<Task> allWeekTasks = [];
        Map<Task, DateTime> taskDayMap = {};
        for (final day in days) {
          final tasks = weekTasks[day]?.where((task) => task.scheduledTime != null).toList() ?? [];
          allWeekTasks.addAll(tasks);
          for (final task in tasks) {
            taskDayMap[task] = day;
          }
        }
        allWeekTasks.sort((a, b) {
          final aStart = a.scheduledTime!.hour * 60 + a.scheduledTime!.minute;
          final bStart = b.scheduledTime!.hour * 60 + b.scheduledTime!.minute;
          return aStart.compareTo(bStart);
        });
        bool isOverlap(Task a, Task b) {
          final aDay = taskDayMap[a];
          final bDay = taskDayMap[b];
          if (aDay == null || bDay == null) return false;
          if (aDay != bDay) return false;
          final aStart = a.scheduledTime!.hour * 60 + a.scheduledTime!.minute;
          final aEnd = aStart + a.timeCostMinutes;
          final bStart = b.scheduledTime!.hour * 60 + b.scheduledTime!.minute;
          final bEnd = bStart + b.timeCostMinutes;
          return aStart < bEnd && bStart < aEnd;
        }
        List<List<Task>> overlappingGroups = [];
        List<Task> visited = [];
        for (int i = 0; i < allWeekTasks.length; i++) {
          final task = allWeekTasks[i];
          if (visited.contains(task)) continue;
          List<Task> group = [task];
          for (int j = i + 1; j < allWeekTasks.length; j++) {
            if (isOverlap(task, allWeekTasks[j])) {
              group.add(allWeekTasks[j]);
            }
          }
          for (final t in group) {
            visited.add(t);
          }
          overlappingGroups.add(group);
        }

        void showOverflowDialog(List<Task> tasks, DateTime day, int hour) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Tasks at ${DateFormat('EEE, MMM d').format(day)} ${hour.toString().padLeft(2, '0')}:00'),
              content: SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: tasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TaskTile(task: task),
                  )).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
              ],
            ),
          );
        }

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
          child: SizedBox(
            height: 24 * hourHeight + 40, // 24 hours + header row
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hour column
                SizedBox(
                  width: 60,
                  child: Column(
                    children: [
                      Container(width: 60, height: 40, color: theme.colorScheme.surfaceVariant.withOpacity(0.7)),
                      Expanded(
                        child: ListView.builder(
                          controller: _weekVerticalScrollController,
                          itemCount: 24,
                          itemBuilder: (context, hour) => Container(
                            width: 60,
                            height: hourHeight,
                            alignment: Alignment.topCenter,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
                              border: Border(
                                right: BorderSide(color: theme.dividerColor),
                                top: BorderSide(color: theme.dividerColor),
                              ),
                            ),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Day grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 7 * 120.0,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Grid and header
                          Column(
                            children: [
                              // Header row
                              Row(
                                children: days.map((day) => Container(
                                  width: 120,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.08),
                                    border: Border(
                                      right: BorderSide(color: theme.dividerColor),
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat('EEE\nMM/dd').format(day),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                )).toList(),
                              ),
                              // All hour rows
                              Expanded(
                                child: ListView.builder(
                                  controller: _weekVerticalScrollController,
                                  itemCount: 24,
                                  itemBuilder: (context, hour) => Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: days.map((day) {
                                      return Container(
                                        width: 120,
                                        height: hourHeight,
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: theme.dividerColor),
                                            top: BorderSide(color: theme.dividerColor),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Task cards (always in front)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: false,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ...overlappingGroups.expand((group) {
                                    if (group.isEmpty) return [];
                                    final firstTask = group.first;
                                    final start = firstTask.scheduledTime!;
                                    final parentDay = taskDayMap[firstTask]!;
                                    final startMinutes = start.hour * 60 + start.minute;
                                    final top = startMinutes * hourHeight / 60 + 40; // 40 for header
                                    final height = firstTask.timeCostMinutes * hourHeight / 60;
                                    final cardMargin = 4.0;
                                    final width = (120.0 - (2 + 1) * cardMargin) / 2; // Only show 2
                                    final left = days.indexOf(parentDay) * 120.0 + cardMargin;
                                    List<Widget> widgets = [];
                                    for (int i = 0; i < group.take(2).length; i++) {
                                      final t = group[i];
                                      widgets.add(Positioned(
                                        top: top + i * 6,
                                        left: left + i * (width + cardMargin),
                                        width: width,
                                        height: height > 28 ? height : 28,
                                        child: TaskTile(task: t, height: height > 28 ? height : 28, superCompact: true),
                                      ));
                                    }
                                    if (group.length > 2) {
                                      widgets.add(Positioned(
                                        top: top + 2 * 6,
                                        left: left + 2 * (width + cardMargin),
                                        width: width,
                                        height: 28,
                                        child: GestureDetector(
                                          onTap: () => showOverflowDialog(group, parentDay, start.hour),
                                          child: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '+${group.length - 2} more',
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ));
                                    }
                                    return widgets;
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 