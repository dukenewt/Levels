import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../task_tile.dart';

class MonthCalendarView extends StatelessWidget {
  final DateTime focusedDay;

  const MonthCalendarView({Key? key, required this.focusedDay}) : super(key: key);

  Future<Map<String, List<Task>>> _loadMonthTasks(TaskProvider taskProvider, DateTime focusedDay) async {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final allMonthTasks = <Task>[];
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      final day = firstDayOfMonth.add(Duration(days: i));
      final tasksForDay = await taskProvider.getTasksForDate(day);
      allMonthTasks.addAll(tasksForDay.where((task) => !task.isCompleted));
    }
    // Group tasks by date
    final Map<String, List<Task>> tasksByDate = {};
    for (final task in allMonthTasks) {
      if (task.dueDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(task.dueDate!);
        tasksByDate.putIfAbsent(dateKey, () => []).add(task);
      }
    }
    return tasksByDate;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    return FutureBuilder<Map<String, List<Task>>>(
      future: _loadMonthTasks(taskProvider, focusedDay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading tasks'));
        }
        final tasksByDate = snapshot.data ?? {};
        final sortedDateKeys = tasksByDate.keys.toList()..sort();

        void showOverflowDialog(List<Task> tasks, DateTime date) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Tasks on ${DateFormat('EEE, MMM d').format(date)}'),
              content: SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: tasks.map((task) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TaskTile(task: task, showTime: false, compact: false, superCompact: true),
                  )).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedDateKeys.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  DateFormat('MMMM yyyy').format(focusedDay),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }
            final dateKey = sortedDateKeys[index - 1];
            final date = DateTime.parse(dateKey);
            final tasks = tasksByDate[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    DateFormat('EEE, MMM d').format(date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ...tasks.take(2).map((task) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: TaskTile(task: task, showTime: false, compact: false, superCompact: true),
                )),
                if (tasks.length > 2)
                  GestureDetector(
                    onTap: () => showOverflowDialog(tasks, date),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: Text(
                        '+${tasks.length - 2} more',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
} 