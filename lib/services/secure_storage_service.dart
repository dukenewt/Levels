// lib/services/secure_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../core/error_handling.dart';

/// Enhanced storage service with comprehensive error handling
class SecureStorageService {
  final SharedPreferences _prefs;
  late final SecureTaskRepository taskRepository;
  late final SecureUserRepository userRepository;
  
  SecureStorageService(this._prefs) {
    taskRepository = SecureTaskRepository(_prefs);
    userRepository = SecureUserRepository(_prefs);
  }
  
  /// Save any type of data with full error handling
  Future<Result<void>> saveData(String key, dynamic value) async {
    try {
      // Validate inputs first
      if (key.isEmpty) {
        return Result.failure(ValidationException('Storage key cannot be empty'));
      }
      
      bool success = false;
      
      // Handle different data types safely
      if (value is String) {
        success = await _prefs.setString(key, value);
      } else if (value is bool) {
        success = await _prefs.setBool(key, value);
      } else if (value is int) {
        success = await _prefs.setInt(key, value);
      } else if (value is double) {
        success = await _prefs.setDouble(key, value);
      } else if (value is List<String>) {
        success = await _prefs.setStringList(key, value);
      } else {
        // For complex objects, serialize to JSON
        try {
          final jsonString = json.encode(value);
          success = await _prefs.setString(key, jsonString);
        } catch (jsonError) {
          return Result.failure(StorageException(
            'Failed to serialize data for key "$key"',
            originalError: jsonError,
          ));
        }
      }
      
      if (!success) {
        return Result.failure(StorageException(
          'Failed to save data for key "$key". Storage operation returned false.',
        ));
      }
      
      return Result.success(null);
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Unexpected error saving data for key "$key"',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
    }
  }
  
  /// Get data with fallback and validation
  Future<Result<T>> getData<T>(
    String key, {
    T? defaultValue,
    T Function(dynamic)? deserializer,
  }) async {
    try {
      if (key.isEmpty) {
        return Result.failure(ValidationException('Storage key cannot be empty'));
      }
      
      final rawValue = _prefs.get(key);
      
      // Return default if no value found
      if (rawValue == null) {
        if (defaultValue != null) {
          return Result.success(defaultValue);
        } else {
          return Result.failure(StorageException('No data found for key "$key"'));
        }
      }
      
      // Try to convert the raw value to the expected type
      try {
        T? processedValue;
        
        if (deserializer != null) {
          // Use custom deserializer if provided
          processedValue = deserializer(rawValue);
        } else if (rawValue is String && (rawValue.startsWith('{') || rawValue.startsWith('['))) {
          // Try to parse JSON
          final decoded = json.decode(rawValue);
          processedValue = decoded as T;
        } else {
          // Direct type casting
          processedValue = rawValue as T;
        }
        
        if (processedValue != null) {
          return Result.success(processedValue);
        } else {
          throw Exception('Processed value is null');
        }
        
      } catch (conversionError) {
        // If conversion fails, try to return default value
        if (defaultValue != null) {
          debugPrint('Warning: Failed to convert stored data for key "$key", using default value');
          return Result.success(defaultValue);
        } else {
          return Result.failure(StorageException(
            'Failed to convert stored data for key "$key"',
            originalError: conversionError,
          ));
        }
      }
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Unexpected error retrieving data for key "$key"',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      
      // Try to return default value even in case of unexpected errors
      if (defaultValue != null) {
        return Result.success(defaultValue);
      } else {
        return Result.failure(error);
      }
    }
  }
  
  /// Delete data with confirmation
  Future<Result<bool>> deleteData(String key) async {
    try {
      if (key.isEmpty) {
        return Result.failure(ValidationException('Storage key cannot be empty'));
      }
      
      final success = await _prefs.remove(key);
      return Result.success(success);
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Failed to delete data for key "$key"',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
    }
  }
  
  /// Clear all data with safety checks
  Future<Result<void>> clearAll({bool skipBackup = false}) async {
    try {
      if (!skipBackup) {
        // Create a backup before clearing (optional safety feature)
        final allKeys = _prefs.getKeys();
        final backup = <String, dynamic>{};
        
        for (final key in allKeys) {
          backup[key] = _prefs.get(key);
        }
        
        // Save backup with timestamp
        final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
        await _prefs.setString(backupKey, json.encode(backup));
      }
      
      final success = await _prefs.clear();
      if (!success) {
        return Result.failure(StorageException('Failed to clear storage'));
      }
      
      return Result.success(null);
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Failed to clear storage',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
    }
  }
  
  /// Check if key exists safely
  Result<bool> hasKey(String key) {
    try {
      if (key.isEmpty) {
        return Result.failure(ValidationException('Storage key cannot be empty'));
      }
      
      return Result.success(_prefs.containsKey(key));
    } catch (e) {
      return Result.failure(StorageException(
        'Failed to check existence of key "$key"',
        originalError: e,
      ));
    }
  }
  
  /// Get all keys safely
  Result<Set<String>> getKeys() {
    try {
      return Result.success(_prefs.getKeys());
    } catch (e) {
      return Result.failure(StorageException(
        'Failed to retrieve storage keys',
        originalError: e,
      ));
    }
  }
}

/// Enhanced Task Repository with bulletproof error handling
class SecureTaskRepository {
  final SharedPreferences _prefs;
  static const String _tasksKey = 'tasks_v1'; // Version your keys for future migrations
  static const String _backupKey = 'tasks_backup';
  
  SecureTaskRepository(this._prefs);
  
  /// Get all tasks with comprehensive error handling
  Future<Result<List<Task>>> getTasks() async {
    try {
      final tasksJson = _prefs.getString(_tasksKey);
      
      if (tasksJson == null || tasksJson.isEmpty) {
        // No tasks found - this is normal for new users
        return Result.success(<Task>[]);
      }
      
      try {
        final List<dynamic> decodedTasks = json.decode(tasksJson);
        final tasks = <Task>[];
        
        // Parse each task individually to handle partial corruption
        for (int i = 0; i < decodedTasks.length; i++) {
          try {
            final task = Task.fromJson(decodedTasks[i] as Map<String, dynamic>);
            tasks.add(task);
          } catch (taskError) {
            debugPrint('Warning: Skipped corrupted task at index $i: $taskError');
            // Continue processing other tasks instead of failing completely
          }
        }
        
        return Result.success(tasks);
        
      } catch (parseError) {
        // JSON parsing failed - try to restore from backup
        debugPrint('Task parsing failed, attempting backup restore: $parseError');
        
        final backupResult = await _restoreFromBackup();
        if (backupResult.isSuccess) {
          return backupResult;
        }
        
        // Both primary and backup failed - return empty list to prevent crash
        return Result.success(<Task>[]);
      }
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Failed to retrieve tasks',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      
      // Return empty list as fallback to keep app functional
      return Result.success(<Task>[]);
    }
  }
  
  /// Save tasks with backup and verification
  Future<Result<void>> saveTasks(List<Task> tasks) async {
    try {
      // Validate input
      if (tasks.any((task) => task.id.isEmpty)) {
        return Result.failure(ValidationException('All tasks must have valid IDs'));
      }
      
      // Create backup of current data before overwriting
      final currentTasks = await getTasks();
      if (currentTasks.isSuccess && currentTasks.data!.isNotEmpty) {
        await _createBackup(currentTasks.data!);
      }
      
      // Serialize tasks
      final tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
      
      // Save new data
      final success = await _prefs.setString(_tasksKey, tasksJson);
      
      if (!success) {
        return Result.failure(StorageException('Failed to save tasks to storage'));
      }
      
      // Verify the save worked by reading it back
      final verification = await getTasks();
      if (verification.isSuccess && verification.data!.length == tasks.length) {
        return Result.success(null);
      } else {
        return Result.failure(StorageException('Task save verification failed'));
      }
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Failed to save tasks',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
    }
  }
  
  /// Save individual task (safer for single operations)
  Future<Result<void>> saveTask(Task task) async {
    final allTasksResult = await getTasks();
    if (!allTasksResult.isSuccess) {
      return Result.failure(allTasksResult.error!);
    }
    
    final tasks = allTasksResult.data!;
    final existingIndex = tasks.indexWhere((t) => t.id == task.id);
    
    if (existingIndex != -1) {
      tasks[existingIndex] = task;
    } else {
      tasks.add(task);
    }
    
    return await saveTasks(tasks);
  }
  
  /// Update existing task
  Future<Result<void>> updateTask(Task task) async {
    final allTasksResult = await getTasks();
    if (!allTasksResult.isSuccess) {
      return Result.failure(allTasksResult.error!);
    }
    
    final tasks = allTasksResult.data!;
    final existingIndex = tasks.indexWhere((t) => t.id == task.id);
    
    if (existingIndex == -1) {
      return Result.failure(ValidationException('Task with ID ${task.id} not found'));
    }
    
    tasks[existingIndex] = task;
    return await saveTasks(tasks);
  }
  
  /// Delete task
  Future<Result<void>> deleteTask(String taskId) async {
    if (taskId.isEmpty) {
      return Result.failure(ValidationException('Task ID cannot be empty'));
    }
    
    final allTasksResult = await getTasks();
    if (!allTasksResult.isSuccess) {
      return Result.failure(allTasksResult.error!);
    }
    
    final tasks = allTasksResult.data!;
    final originalLength = tasks.length;
    tasks.removeWhere((task) => task.id == taskId);
    
    if (tasks.length == originalLength) {
      return Result.failure(ValidationException('Task with ID $taskId not found'));
    }
    
    return await saveTasks(tasks);
  }
  
  /// Create backup of current tasks
  Future<void> _createBackup(List<Task> tasks) async {
    try {
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
      };
      await _prefs.setString(_backupKey, json.encode(backupData));
    } catch (e) {
      debugPrint('Warning: Failed to create task backup: $e');
      // Don't fail the main operation if backup fails
    }
  }
  
  /// Restore tasks from backup
  Future<Result<List<Task>>> _restoreFromBackup() async {
    try {
      final backupJson = _prefs.getString(_backupKey);
      if (backupJson == null) {
        return Result.failure(StorageException('No backup available'));
      }
      
      final backupData = json.decode(backupJson) as Map<String, dynamic>;
      final tasksList = backupData['tasks'] as List<dynamic>;
      
      final tasks = tasksList
          .map((taskJson) => Task.fromJson(taskJson as Map<String, dynamic>))
          .toList();
      
      debugPrint('Successfully restored ${tasks.length} tasks from backup');
      return Result.success(tasks);
      
    } catch (e) {
      return Result.failure(StorageException(
        'Failed to restore from backup',
        originalError: e,
      ));
    }
  }
}

/// Enhanced User Repository (similar pattern)
class SecureUserRepository {
  final SharedPreferences _prefs;
  static const String _userDataKey = 'user_data_v1';
  
  SecureUserRepository(this._prefs);
  
  Future<Result<Map<String, dynamic>>> getUserData() async {
    try {
      final userDataJson = _prefs.getString(_userDataKey);
      if (userDataJson == null) {
        return Result.success(<String, dynamic>{});
      }
      
      final userData = json.decode(userDataJson) as Map<String, dynamic>;
      return Result.success(userData);
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Failed to retrieve user data',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.success(<String, dynamic>{}); // Return empty data as fallback
    }
  }
  
  Future<Result<void>> saveUserData(Map<String, dynamic> userData) async {
    try {
      final userDataJson = json.encode(userData);
      final success = await _prefs.setString(_userDataKey, userDataJson);
      
      if (!success) {
        return Result.failure(StorageException('Failed to save user data'));
      }
      
      return Result.success(null);
      
    } catch (e, stackTrace) {
      final error = StorageException(
        'Failed to save user data',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
    }
  }
  
  Future<Result<void>> updateUserData(Map<String, dynamic> userData) async {
    final currentDataResult = await getUserData();
    if (!currentDataResult.isSuccess) {
      return Result.failure(currentDataResult.error!);
    }
    
    final currentData = currentDataResult.data!;
    currentData.addAll(userData);
    return await saveUserData(currentData);
  }
  
  Future<Result<void>> deleteUserData() async {
    try {
      final success = await _prefs.remove(_userDataKey);
      if (!success) {
        return Result.failure(StorageException('Failed to delete user data'));
      }
      return Result.success(null);
    } catch (e, stackTrace) {
      final error = StorageException(
        'Failed to delete user data',
        originalError: e,
      );
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      return Result.failure(error);
    }
  }
}
 