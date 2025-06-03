import 'package:flutter/material.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Task Reminders'),
            subtitle: Text('Get reminders for your scheduled tasks'),
            trailing: Switch(value: true, onChanged: null), // TODO: connect to settings
          ),
          ListTile(
            title: Text('Re-engagement Notifications'),
            subtitle: Text('Get notifications to come back to the app'),
            trailing: Switch(value: true, onChanged: null), // TODO: connect to settings
          ),
        ],
      ),
    );
  }
} 