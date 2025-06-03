import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'theme_selection_screen.dart';
import 'debug_screen.dart';
import 'notification_preferences_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings Section
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
                    'Theme Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('App Theme'),
                    subtitle: Text(themeProvider.currentTheme.name),
                    leading: Icon(
                      Icons.palette,
                      color: theme.colorScheme.primary,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  // Debug Tools Navigation
                  ListTile(
                    title: const Text('Debug Tools'),
                    subtitle: const Text('Test coins and skill points'),
                    leading: Icon(
                      Icons.bug_report,
                      color: theme.colorScheme.primary,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use system theme settings'),
                    value: settingsProvider.isDarkMode,
                    onChanged: (value) {
                      settingsProvider.setDarkMode(value);
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
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
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPreferencesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
} 