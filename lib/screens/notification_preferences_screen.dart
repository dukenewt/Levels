import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header description
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.notifications_active,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Stay on Track',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Customize your notifications to stay motivated and never miss important tasks.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Task Notifications Section
                Text(
                  'Task Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildNotificationTile(
                        context,
                        'Task Reminders',
                        'Get reminded about your scheduled tasks',
                        Icons.alarm,
                        settings.enableTaskReminders,
                        (value) => settings.setEnableTaskReminders(value),
                      ),
                      _buildDivider(),
                      _buildNotificationTile(
                        context,
                        'Due Date Alerts',
                        'Notifications when tasks are due today',
                        Icons.today,
                        settings.enableDueDateNotifications,
                        (value) => settings.setEnableDueDateNotifications(value),
                      ),
                      _buildDivider(),
                      _buildNotificationTile(
                        context,
                        'Overdue Reminders',
                        'Get notified about overdue tasks',
                        Icons.warning,
                        settings.enableOverdueNotifications,
                        (value) => settings.setEnableOverdueNotifications(value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Celebration & Motivation Section
                Text(
                  'Celebration & Motivation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildNotificationTile(
                        context,
                        'Completion Celebrations',
                        'Celebrate when you complete tasks',
                        Icons.celebration,
                        settings.enableCompletionCelebrations,
                        (value) => settings.setEnableCompletionCelebrations(value),
                      ),
                      _buildDivider(),
                      _buildNotificationTile(
                        context,
                        'Streak Reminders',
                        'Motivational reminders about your streaks',
                        Icons.local_fire_department,
                        settings.enableStreakReminders,
                        (value) => settings.setEnableStreakReminders(value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Re-engagement Section
                Text(
                  'Re-engagement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildNotificationTile(
                        context,
                        'Re-engagement Notifications',
                        'Gentle reminders to come back to the app',
                        Icons.favorite,
                        settings.enableReEngagementNotifications,
                        (value) => settings.setEnableReEngagementNotifications(value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Timing Settings Section
                Text(
                  'Notification Timing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Reminder Timing',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'How many minutes before a task\'s due time should you be reminded?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: settings.reminderMinutesBefore,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [5, 15, 30, 60, 120, 240]
                              .map((minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text(_formatReminderTime(minutes)),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settings.setReminderMinutesBefore(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Note about permissions
                Card(
                  elevation: 1,
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Make sure to allow notifications in your device settings for the best experience.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 68);
  }

  String _formatReminderTime(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes before';
    } else {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour before' : '$hours hours before';
    }
  }
} 