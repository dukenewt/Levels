import 'package:flutter/material.dart';
import 'task_creation_dialog.dart';

class EmptyTasksPlaceholder extends StatelessWidget {
  const EmptyTasksPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradientColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary ?? theme.colorScheme.primaryContainer,
    ];
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Tasks Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by adding your first task. Tap the + button below to get started!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white.withOpacity(0.85) : Colors.black54,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => TaskCreationDialog(),
                  );
                },
                icon: Icon(Icons.add, color: theme.colorScheme.primary),
                label: Text(
                  'Add Your First Task',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.grey[100],
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  textStyle: theme.textTheme.titleMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 