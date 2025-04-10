import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Task Filter Settings Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Filter Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Today's Tasks Toggle
                  SwitchListTile(
                    title: const Text('Show Today\'s Tasks'),
                    subtitle: const Text('Display tasks due today'),
                    value: settingsProvider.showTodayTasks,
                    onChanged: (value) {
                      settingsProvider.updateShowTodayTasks(value);
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  const Divider(),
                  // Tomorrow's Tasks Toggle
                  SwitchListTile(
                    title: const Text('Show Tomorrow\'s Tasks'),
                    subtitle: const Text('Display tasks due tomorrow'),
                    value: settingsProvider.showTomorrowTasks,
                    onChanged: (value) {
                      settingsProvider.updateShowTomorrowTasks(value);
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                  const Divider(),
                  // This Week's Tasks Toggle
                  SwitchListTile(
                    title: const Text('Show This Week\'s Tasks'),
                    subtitle: const Text('Display tasks due this week'),
                    value: settingsProvider.showThisWeekTasks,
                    onChanged: (value) {
                      settingsProvider.updateShowThisWeekTasks(value);
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App Info Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    leading: Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 