import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// Service for handling all task-related notifications
class TaskNotificationService {
  static final TaskNotificationService _instance = TaskNotificationService._();
  static TaskNotificationService get instance => _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TaskNotificationService._();

  /// Initialize the notification service
  Future<void> initialize() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notificationsPlugin.initialize(settings);
    debugPrint('📢 TaskNotificationService: Initialized');
  }

  /// Schedule a reminder notification for a task
  Future<void> scheduleTaskReminder(BuildContext context, Task task) async {
    if (task.dueDate == null || task.scheduledTime == null) {
      return;
    }

    final dueDateTime = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      task.scheduledTime!.hour,
      task.scheduledTime!.minute,
    );

    if (dueDateTime.isBefore(DateTime.now())) {
      return; // Don't schedule past reminders
    }

    await _scheduleNotification(
      id: task.id.hashCode, // Use a hash of the unique task ID
      scheduledTime: dueDateTime,
      title: 'Task Reminder ⏰',
      body: '${task.title} is due soon!',
      payload: task.id,
    );

    debugPrint('📢 Scheduled reminder for "${task.title}" at $dueDateTime');
  }

  /// Show an immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'immediate_notifications',
      'Immediate Notifications',
      channelDescription: 'General immediate notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(presentSound: true);
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    HapticFeedback.selectionClick();
  }

  /// Cancel a specific task notification
  Future<void> cancelTaskNotification(String taskId) async {
    await _notificationsPlugin.cancel(taskId.hashCode);
    debugPrint('📢 Cancelled notification for task $taskId');
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(presentSound: true);

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Get notification permission status
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
