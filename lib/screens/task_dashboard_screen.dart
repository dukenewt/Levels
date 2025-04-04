import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/level_progress_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_tasks_placeholder.dart';

class TaskDashboardScreen extends StatelessWidget {
  const TaskDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Up Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Level progress card
          LevelProgressCard(
            level: userProvider.user?.level ?? 1,
            currentXp: userProvider.user?.currentXp ?? 0,
            nextLevelXp: userProvider.getNextLevelThreshold(),
          ),
          
          // Tasks list
          Expanded(
            child: taskProvider.tasks.isEmpty
                ? const EmptyTasksPlaceholder()
                : ListView.builder(
                    itemCount: taskProvider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.tasks[index];
                      return TaskTile(
                        task: task,
                        onComplete: () => taskProvider.completeTask(task.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 