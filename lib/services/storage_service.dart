import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> updateTask(Task task) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await _saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks(tasks);
  }

  Future<List<Task>> getTasks() async {
    final tasksJson = _prefs.getStringList(_tasksKey) ?? [];
    return tasksJson
        .map((json) => Task.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final tasksJson = tasks
        .map((task) => jsonEncode(task.toJson()))
        .toList();
    await _prefs.setStringList(_tasksKey, tasksJson);
  }
} 