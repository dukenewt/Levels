import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/secure_user_provider.dart';
import '../providers/secure_task_provider.dart';
import '../services/smart_suggestions_service.dart';
import '../models/task.dart';

class SmartSuggestionsWidget extends StatelessWidget {
  const SmartSuggestionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<SecureUserProvider>(context);
    if (!userProvider.hasPerk('smart_suggestions')) {
      return const SizedBox.shrink();
    }
    return Consumer<SecureTaskProvider>(
      builder: (context, taskProvider, child) {
        final suggestionsService = SmartSuggestionsService(
          userTasks: taskProvider.tasks,
        );
        final suggestions = suggestionsService.generateSuggestions();
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bound Suggestions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PERK',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...suggestions.map((suggestion) => _buildSuggestionCard(
                  context,
                  suggestion,
                  taskProvider,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    TaskSuggestion suggestion,
    SecureTaskProvider taskProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${suggestion.xpReward} XP',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                onPressed: () => _acceptSuggestion(context, suggestion, taskProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _acceptSuggestion(
    BuildContext context,
    TaskSuggestion suggestion,
    SecureTaskProvider taskProvider,
  ) async {
    final newTask = Task(
      id: UniqueKey().toString(),
      title: suggestion.title,
      description: suggestion.reason,
      category: suggestion.category,
      xpReward: suggestion.xpReward,
      createdAt: DateTime.now(),
      isCompleted: false,
      // Add other required fields as needed
    );
    await taskProvider.createTask(newTask);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${suggestion.title}" to your tasks!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
} 