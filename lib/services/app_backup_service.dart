import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../core/storage_keys.dart';
import '../models/export_config.dart';
import '../models/task.dart';

class AppBackupService {
  static Future<Map<String, dynamic>> createFullBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final backup = <String, dynamic>{
      'metadata': {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      },
      'user': _extractUserData(prefs),
      'tasks': _extractTaskData(prefs),
      'skills': _extractSkillData(prefs),
      'settings': _extractSettingsData(prefs),
      'themes': _extractThemeData(prefs),
      'economy': _extractEconomyData(prefs),
    };
    return backup;
  }

  static Map<String, dynamic> _extractUserData(SharedPreferences prefs) {
    try {
      final userJson = prefs.getString('user_data_v1');
      if (userJson != null) {
        return json.decode(userJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting user data: $e');
    }
    return {};
  }

  static List<dynamic> _extractTaskData(SharedPreferences prefs) {
    try {
      final tasksJson = prefs.getString('tasks_data_v1');
      if (tasksJson != null) {
        return json.decode(tasksJson) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting task data: $e');
    }
    return [];
  }

  static List<dynamic> _extractSkillData(SharedPreferences prefs) {
    try {
      final skillsJson = prefs.getString('skills_data_v1');
      if (skillsJson != null) {
        return json.decode(skillsJson) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting skill data: $e');
    }
    return [];
  }

  static Map<String, dynamic> _extractSettingsData(SharedPreferences prefs) {
    try {
      final settingsJson = prefs.getString('settings_data_v1');
      if (settingsJson != null) {
        return json.decode(settingsJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting settings data: $e');
    }
    return {};
  }

  static Map<String, dynamic> _extractThemeData(SharedPreferences prefs) {
    try {
      final themeJson = prefs.getString('theme_data_v1');
      if (themeJson != null) {
        return json.decode(themeJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting theme data: $e');
    }
    return {};
  }

  static Map<String, dynamic> _extractEconomyData(SharedPreferences prefs) {
    try {
      final economyJson = prefs.getString('economy_data_v1');
      if (economyJson != null) {
        return json.decode(economyJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting economy data: $e');
    }
    return {};
  }

  static Future<String?> exportBackupToDownloads({ExportConfig config = ExportConfig.backup}) async {
    try {
      final backup = await exportAllData(config: config);
      final jsonString = json.encode(backup);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dailyxp_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      debugPrint('Backup export failed: $e');
      return null;
    }
  }

  static Future<bool> importBackupFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return false;
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backup = json.decode(jsonString) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      // Restore each section
      if (backup['user'] != null) {
        prefs.setString('user_data_v1', json.encode(backup['user']));
      }
      if (backup['tasks'] != null) {
        prefs.setString('tasks_data_v1', json.encode(backup['tasks']));
      }
      if (backup['skills'] != null) {
        prefs.setString('skills_data_v1', json.encode(backup['skills']));
      }
      if (backup['settings'] != null) {
        prefs.setString('settings_data_v1', json.encode(backup['settings']));
      }
      if (backup['themes'] != null) {
        prefs.setString('theme_data_v1', json.encode(backup['themes']));
      }
      if (backup['economy'] != null) {
        prefs.setString('economy_data_v1', json.encode(backup['economy']));
      }
      return true;
    } catch (e) {
      debugPrint('Backup import failed: $e');
      return false;
    }
  }

  /// Debug: Print all SharedPreferences keys and their values
  static Future<void> printAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('--- SharedPreferences Contents ---');
    for (var key in prefs.getKeys()) {
      debugPrint('$key: \\${prefs.get(key)}');
    }
    debugPrint('--- End SharedPreferences ---');
  }

  static Future<Map<String, dynamic>> exportAllData({ExportConfig config = ExportConfig.backup}) async {
    final prefs = await SharedPreferences.getInstance();
    // Get all tasks
    final tasksJson = prefs.getString('tasks_data_v1');
    final List<Task> allTasks = tasksJson != null
        ? (List<Map<String, dynamic>>.from(json.decode(tasksJson)).map((e) => Task.fromJson(e)).toList())
        : [];
    // Apply intelligent filtering
    final filteredTasks = _filterTasks(allTasks, config);
    // Filtering summary
    final filteringSummary = {
      'total_tasks_found': allTasks.length,
      'tasks_included': filteredTasks.length,
      'filtering_criteria': {
        'completed_tasks_days_limit': config.completedTasksDaysLimit,
        'include_test_data': config.includeTestData,
        'export_purpose': config.purpose.toString(),
      },
      'tasks_excluded': allTasks.length - filteredTasks.length,
    };
    return {
      'metadata': {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'export_purpose': config.purpose.toString(),
        'filtering_summary': filteringSummary,
      },
      'user': _extractUserData(prefs),
      'tasks': filteredTasks.map((task) => task.toJson()).toList(),
      'skills': _extractSkillData(prefs),
      'settings': _extractSettingsData(prefs),
      'themes': _extractThemeData(prefs),
      'economy': _extractEconomyData(prefs),
      'skillAchievements': prefs.getString('skill_achievements') != null ? json.decode(prefs.getString('skill_achievements')!) : {},
    };
  }

  static List<Task> _filterTasks(List<Task> allTasks, ExportConfig config) {
    final now = DateTime.now();
    return allTasks.where((task) {
      // Always include active (uncompleted) tasks
      if (!task.isCompleted) return true;
      // Filter completed tasks by date if limit is set
      if (config.completedTasksDaysLimit != null && task.completedAt != null) {
        final cutoffDate = now.subtract(Duration(days: config.completedTasksDaysLimit!));
        if (task.completedAt!.isBefore(cutoffDate)) {
          return false; // Too old, exclude it
        }
      }
      // Filter out obvious test data unless explicitly requested
      if (!config.includeTestData) {
        final isTestTask = _isLikelyTestTask(task);
        if (isTestTask) return false;
      }
      return true;
    }).toList();
  }

  static bool _isLikelyTestTask(Task task) {
    final testIndicators = [
      'test', 'sup', 'spe', 'aaa', 'asdf', 'debug', 'temp',
      'xxx', '123', 'sample', 'demo'
    ];
    final titleLower = (task.title ?? '').toLowerCase();
    final hasTestTitle = testIndicators.any((indicator) => titleLower.contains(indicator));
    final hasVeryShortTitle = (task.title ?? '').length <= 3;
    final hasEmptyDescription = (task.description ?? '').trim().isEmpty;
    return hasTestTitle || (hasVeryShortTitle && hasEmptyDescription);
  }

  /// Debug: Print all SharedPreferences keys, types, and value previews
  static Future<void> debugStorageContents() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().toList()..sort();
    debugPrint('=== STORAGE DEBUG ===');
    debugPrint('Total keys found: \\${allKeys.length}');
    for (final key in allKeys) {
      final value = prefs.get(key);
      final valueType = value.runtimeType;
      final valuePreview = value.toString().length > 100 
          ? '\\${value.toString().substring(0, 100)}...'
          : value.toString();
      debugPrint('Key: "$key" | Type: $valueType | Value: $valuePreview');
    }
    debugPrint('=== END DEBUG ===');
  }
} 