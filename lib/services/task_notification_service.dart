import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';

/// Service for handling all task-related notifications
class TaskNotificationService {
  static final TaskNotificationService _instance = TaskNotificationService._();
  static TaskNotificationService get instance => _instance;
  TaskNotificationService._();
  
  // Keep track of scheduled notifications
  final Set<String> _scheduledNotifications = {};
  
  /// Initialize the notification service
  Future<void> initialize() async {
    // In a real app, you would initialize platform-specific notification channels here
    debugPrint('📢 TaskNotificationService: Initialized');
  }
  
  /// Schedule a reminder notification for a task
  Future<void> scheduleTaskReminder(
    BuildContext context,
    Task task,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!settings.enableTaskReminders || task.dueDate == null || task.scheduledTime == null) {
      return;
    }
    
    final dueDateTime = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      task.scheduledTime!.hour,
      task.scheduledTime!.minute,
    );
    
    final reminderTime = dueDateTime.subtract(
      Duration(minutes: settings.reminderMinutesBefore),
    );
    
    final now = DateTime.now();
    if (reminderTime.isBefore(now)) {
      return; // Don't schedule past reminders
    }
    
    final notificationId = 'reminder_${task.id}';
    
    // Schedule the notification
    await _scheduleNotification(
      id: notificationId,
      scheduledTime: reminderTime,
      title: 'Task Reminder ⏰',
      body: '${task.title} is due in ${settings.reminderMinutesBefore} minutes',
      payload: task.id,
    );
    
    debugPrint('📢 Scheduled reminder for "${task.title}" at $reminderTime');
  }
  
  /// Check for and notify about due tasks
  Future<void> checkDueTasks(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (!settings.enableDueDateNotifications) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get tasks due today
    final dueTasks = taskProvider.tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      
      final taskDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      
      return taskDate.isAtSameMomentAs(today);
    }).toList();
    
    if (dueTasks.isNotEmpty) {
      await _showImmediateNotification(
        title: 'Tasks Due Today 📅',
        body: '${dueTasks.length} task${dueTasks.length > 1 ? 's' : ''} due today',
        payload: 'due_tasks',
      );
    }
  }
  
  /// Check for and notify about overdue tasks
  Future<void> checkOverdueTasks(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (!settings.enableOverdueNotifications) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get overdue tasks
    final overdueTasks = taskProvider.tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      
      final taskDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      
      return taskDate.isBefore(today);
    }).toList();
    
    if (overdueTasks.isNotEmpty) {
      await _showImmediateNotification(
        title: 'Overdue Tasks ⚠️',
        body: '${overdueTasks.length} task${overdueTasks.length > 1 ? 's are' : ' is'} overdue',
        payload: 'overdue_tasks',
      );
    }
  }
  
  /// Show a completion celebration notification
  Future<void> showCompletionCelebration(
    BuildContext context,
    Task task,
    int xpGained,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!settings.enableCompletionCelebrations) return;
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    await _showImmediateNotification(
      title: 'Task Completed! 🎉',
      body: '${task.title} completed! +$xpGained XP',
      payload: 'completion_${task.id}',
    );
    
    debugPrint('📢 Showed completion celebration for "${task.title}"');
  }
  
  /// Send streak reminder notifications
  Future<void> showStreakReminder(
    BuildContext context,
    String category,
    int streakDays,
  ) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!settings.enableStreakReminders) return;
    
    final emoji = _getStreakEmoji(streakDays);
    
    await _showImmediateNotification(
      title: 'Streak Alert! $emoji',
      body: '$streakDays day streak in $category! Keep it going!',
      payload: 'streak_$category',
    );
    
    debugPrint('📢 Showed streak reminder for $category ($streakDays days)');
  }
  
  /// Send re-engagement notification
  Future<void> showReEngagementNotification(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!settings.enableReEngagementNotifications) return;
    
    final messages = [
      'Missing you! Come back and level up! 💪',
      'Your tasks are waiting for you! 📝',
      'Time to earn some XP! ⭐',
      'Keep your streaks alive! 🔥',
      'Ready for your next challenge? 🎯',
    ];
    
    final randomMessage = messages[DateTime.now().millisecond % messages.length];
    
    await _showImmediateNotification(
      title: 'Daily XP',
      body: randomMessage,
      payload: 're_engagement',
    );
    
    debugPrint('📢 Showed re-engagement notification');
  }
  
  /// Schedule notifications for all active tasks
  Future<void> scheduleAllTaskNotifications(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Clear existing scheduled notifications
    await _clearAllScheduledNotifications();
    
    // Schedule new notifications for all active tasks
    for (final task in taskProvider.activeTasks) {
      await scheduleTaskReminder(context, task);
    }
    
    debugPrint('📢 Scheduled notifications for ${taskProvider.activeTasks.length} active tasks');
  }
  
  /// Cancel a specific task notification
  Future<void> cancelTaskNotification(String taskId) async {
    final notificationId = 'reminder_$taskId';
    await _cancelNotification(notificationId);
    _scheduledNotifications.remove(notificationId);
    debugPrint('📢 Cancelled notification for task $taskId');
  }
  
  /// Update notifications when task is completed
  Future<void> onTaskCompleted(BuildContext context, Task task, int xpGained) async {
    // Cancel any pending reminders for this task
    await cancelTaskNotification(task.id);
    
    // Show completion celebration
    await showCompletionCelebration(context, task, xpGained);
  }
  
  // Private helper methods
  
  Future<void> _scheduleNotification({
    required String id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    // In a real app, you would use a plugin like flutter_local_notifications
    // For now, we'll simulate scheduling and show immediate notifications for demo
    
    _scheduledNotifications.add(id);
    
    // For demo purposes, show immediate notification if scheduled time is very soon
    final now = DateTime.now();
    final timeDiff = scheduledTime.difference(now).inMinutes;
    
    if (timeDiff <= 1) {
      await _showImmediateNotification(
        title: title,
        body: body,
        payload: payload,
      );
    }
  }
  
  Future<void> _showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // In a real app, you would use flutter_local_notifications plugin
    // For now, we'll just log the notification
    debugPrint('📢 NOTIFICATION: $title - $body');
    
    // Add haptic feedback for immediate notifications
    HapticFeedback.selectionClick();
  }
  
  Future<void> _cancelNotification(String id) async {
    // In a real app, you would cancel the notification using the plugin
    debugPrint('📢 Cancelled notification: $id');
  }
  
  Future<void> _clearAllScheduledNotifications() async {
    // In a real app, you would clear all notifications using the plugin
    _scheduledNotifications.clear();
    debugPrint('📢 Cleared all scheduled notifications');
  }
  
  String _getStreakEmoji(int days) {
    if (days >= 30) return '🏆';
    if (days >= 14) return '🔥';
    if (days >= 7) return '⚡';
    if (days >= 3) return '💪';
    return '🎯';
  }
  
  /// Get notification permission status
  Future<bool> hasNotificationPermission() async {
    // In a real app, you would check actual notification permissions
    // For now, return true for demo purposes
    return true;
  }
  
  /// Request notification permissions
  Future<bool> requestNotificationPermission() async {
    // In a real app, you would request notification permissions
    // For now, return true for demo purposes
    return true;
  }
  
  /// Get scheduled notification count for debugging
  int get scheduledNotificationCount => _scheduledNotifications.length;
  
  /// Check if notifications are supported on this platform
  bool get isSupported {
    // In a real app, you would check platform support
    return true;
  }
} 