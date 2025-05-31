import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'package:flutter/foundation.dart';

// Abstract interface for task storage
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<void> saveTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Future<void> saveTasks(List<Task> tasks);
}

// Local storage implementation
class LocalTaskRepository implements TaskRepository {
  final SharedPreferences _prefs;
  static const String _tasksKey = 'tasks';

  LocalTaskRepository(this._prefs);

  @override
  Future<void> saveTask(Task task) async {
    try {
      final tasks = await getTasks();
      final index = tasks.indexWhere((t) => t.id == task.id);
      
      if (index != -1) {
        tasks[index] = task;
      } else {
        tasks.add(task);
      }
      
      await saveTasks(tasks);
    } catch (e) {
      debugPrint('Error saving task: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      final tasks = await getTasks();
      final index = tasks.indexWhere((t) => t.id == task.id);
      
      if (index != -1) {
        tasks[index] = task;
        await saveTasks(tasks);
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      final tasks = await getTasks();
      tasks.removeWhere((task) => task.id == taskId);
      await saveTasks(tasks);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  @override
  Future<List<Task>> getTasks() async {
    try {
      final tasksJson = _prefs.getString(_tasksKey);
      if (tasksJson == null) return [];

      final List<dynamic> decodedTasks = json.decode(tasksJson);
      return decodedTasks.map((taskJson) => Task.fromJson(taskJson)).toList();
    } catch (e) {
      debugPrint('Error getting tasks: $e');
      return [];
    }
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
      await _prefs.setString(_tasksKey, tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
      rethrow;
    }
  }
}

// Abstract interface for user storage
abstract class UserRepository {
  Future<Map<String, dynamic>> getUserData();
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<void> updateUserData(Map<String, dynamic> userData);
  Future<void> deleteUserData();
}

// Local storage implementation for user data
class LocalUserRepository implements UserRepository {
  final SharedPreferences _prefs;
  static const String _userDataKey = 'user_data';

  LocalUserRepository(this._prefs);

  @override
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final userDataJson = _prefs.getString(_userDataKey);
      if (userDataJson == null) return {};
      return json.decode(userDataJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return {};
    }
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final userDataJson = json.encode(userData);
      await _prefs.setString(_userDataKey, userDataJson);
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      final currentData = await getUserData();
      currentData.addAll(userData);
      await saveUserData(currentData);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUserData() async {
    try {
      await _prefs.remove(_userDataKey);
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow;
    }
  }
}

class StorageService {
  final SharedPreferences _prefs;
  static const String _settingsKey = 'app_settings';
  static const String _skillsKey = 'skills';
  static const String _achievementsKey = 'achievements';

  late final TaskRepository taskRepository;
  late final UserRepository userRepository;

  StorageService(this._prefs) {
    taskRepository = LocalTaskRepository(_prefs);
    userRepository = LocalUserRepository(_prefs);
  }

  // Save any type of data
  Future<void> saveData(String key, dynamic value) async {
    try {
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await _prefs.setStringList(key, value);
      } else {
        await _prefs.setString(key, json.encode(value));
      }
    } catch (e) {
      debugPrint('Error saving data for key $key: $e');
      rethrow;
    }
  }

  // Get data of any type
  Future<dynamic> getData(String key, {dynamic defaultValue}) async {
    try {
      final value = _prefs.get(key);
      if (value == null) return defaultValue;

      if (value is String) {
        try {
          if (value.startsWith('{') || value.startsWith('[')) {
            return json.decode(value);
          }
          return value;
        } catch (e) {
          return value;
        }
      }
      return value;
    } catch (e) {
      debugPrint('Error getting data for key $key: $e');
      return defaultValue;
    }
  }

  // Delete data
  Future<void> deleteData(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e) {
      debugPrint('Error deleting data for key $key: $e');
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      await _prefs.clear();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      rethrow;
    }
  }

  // Check if key exists
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
} 