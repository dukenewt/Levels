import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../task_tile.dart';

class DailyCalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final void Function(BuildContext, DateTime) onDayChanged;

  const DailyCalendarView({
    Key? key,
    required this.focusedDay,
    required this.onDayChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final floatingTasks = taskProvider.tasks
        .where((task) =>
          !task.isCompleted &&
          task.scheduledTime == null &&
          (
            task.dueDate == null ||
            (task.dueDate!.isAfter(now.subtract(const Duration(days: 1))) &&
             task.dueDate!.isBefore(nextWeek) &&
             (task.dueDate!.hour == 0 && task.dueDate!.minute == 0))
          )
        )
        .toList();

    const double pixelsPerMinute = 1.0;
    const double hourHeight = 60.0;
    const double leftOffset = 60;
    const double taskAreaWidth = 300;

    return FutureBuilder<List<Task>>(
      future: taskProvider.getTasksForDate(focusedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text('Error loading tasks')));
        }
        final dayTasks = (snapshot.data ?? [])
            .where((task) => !task.isCompleted && task.scheduledTime != null)
            .toList();
        dayTasks.sort((a, b) {
          final aStart = a.scheduledTime!.hour * 60 + a.scheduledTime!.minute;
          final bStart = b.scheduledTime!.hour * 60 + b.scheduledTime!.minute;
          return aStart.compareTo(bStart);
        });

        bool isOverlap(Task a, Task b) {
          final aStart = a.scheduledTime!.hour * 60 + a.scheduledTime!.minute;
          final aEnd = aStart + a.timeCostMinutes;
          final bStart = b.scheduledTime!.hour * 60 + b.scheduledTime!.minute;
          final bEnd = bStart + b.timeCostMinutes;
          return aStart < bEnd && bStart < aEnd;
        }

        // Group overlapping tasks by their time slot
        List<List<Task>> overlappingGroups = [];
        List<Task> visited = [];
        for (int i = 0; i < dayTasks.length; i++) {
          final task = dayTasks[i];
          if (visited.contains(task)) continue;
          List<Task> group = [task];
          for (int j = i + 1; j < dayTasks.length; j++) {
            if (isOverlap(task, dayTasks[j])) {
              group.add(dayTasks[j]);
            }
          }
          for (final t in group) {
            visited.add(t);
          }
          overlappingGroups.add(group);
        }

        void showOverflowDialog(List<Task> tasks, TimeOfDay time) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Tasks at ${time.format(context)}'),
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

        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        splashRadius: 22,
                        onPressed: () => onDayChanged(context, focusedDay.subtract(const Duration(days: 1))),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            DateFormat('EEEE, MMMM d, y').format(focusedDay),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 28),
                        splashRadius: 22,
                        onPressed: () => onDayChanged(context, focusedDay.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.black.withOpacity(0.10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 24 * 60, // 1440 pixels for 24 hours
                    child: Stack(
                      children: [
                        Column(
                          children: List.generate(24, (hour) => Stack(
                            children: [
                              Container(
                                height: hourHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
                                  ),
                                ),
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                  child: Text(
                                    TimeOfDay(hour: hour, minute: 0).format(context),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 60.0,
                                right: 0.0,
                                top: hourHeight * 0.25,
                                child: Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFCCCCCC),
                                        width: 1,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 60.0,
                                right: 0.0,
                                top: hourHeight * 0.5,
                                child: Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFCCCCCC),
                                        width: 1,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 60.0,
                                right: 0.0,
                                top: hourHeight * 0.75,
                                child: Container(
                                  height: 1,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFCCCCCC),
                                        width: 1,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )),
                        ),
                        ...overlappingGroups.expand((group) {
                          if (group.isEmpty) return [];
                          final firstTask = group.first;
                          final start = firstTask.scheduledTime!;
                          final startMinutes = start.hour * 60 + start.minute;
                          final top = startMinutes * pixelsPerMinute;
                          final height = firstTask.timeCostMinutes * pixelsPerMinute;
                          final cardMargin = 4.0;
                          final width = (taskAreaWidth - (2 + 1) * cardMargin) / 2; // Only show 2
                          final left = leftOffset + cardMargin;
                          List<Widget> widgets = [];
                          for (int i = 0; i < group.take(2).length; i++) {
                            final t = group[i];
                            widgets.add(Positioned(
                              top: top + i * 6, // slight vertical offset for stacking
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
                                onTap: () => showOverflowDialog(group, start),
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
              ),
            ),
            if (floatingTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Floating Tasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...floatingTasks.map((task) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TaskTile(task: task),
              )),
            ],
          ]),
        );
      },
    );
  }
} 