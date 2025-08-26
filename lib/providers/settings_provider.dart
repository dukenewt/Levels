import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Task filter settings
  bool _showTodayTasks = true;
  bool _showTomorrowTasks = true;
  bool _showThisWeekTasks = true;
  bool _isInitialized = false;
  SharedPreferences? _prefs;
  bool _isLoading = false;

  // Task category settings
  bool _showWorkTasks = true;
  bool _showSchoolTasks = true;
  bool _showExerciseTasks = true;
  bool _isDarkMode = false;

  // Notification settings
  bool _enableTaskReminders = true;
  bool _enableDueDateNotifications = true;
  bool _enableOverdueNotifications = true;
  bool _enableCompletionCelebrations = true;
  bool _enableStreakReminders = true;
  bool _enableReEngagementNotifications = true;
  int _reminderMinutesBefore = 30; // Default 30 minutes before due time

  // Accessibility
  bool _reducedMotion = false;

  // Getters
  bool get showTodayTasks => _showTodayTasks;
  bool get showTomorrowTasks => _showTomorrowTasks;
  bool get showThisWeekTasks => _showThisWeekTasks;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get showWorkTasks => _showWorkTasks;
  bool get showSchoolTasks => _showSchoolTasks;
  bool get showExerciseTasks => _showExerciseTasks;
  bool get isDarkMode => _isDarkMode;

  // Notification getters
  bool get enableTaskReminders => _enableTaskReminders;
  bool get enableDueDateNotifications => _enableDueDateNotifications;
  bool get enableOverdueNotifications => _enableOverdueNotifications;
  bool get enableCompletionCelebrations => _enableCompletionCelebrations;
  bool get enableStreakReminders => _enableStreakReminders;
  bool get enableReEngagementNotifications => _enableReEngagementNotifications;
  int get reminderMinutesBefore => _reminderMinutesBefore;
  bool get reducedMotion => _reducedMotion;

  // Initialize settings from SharedPreferences
  Future<void> loadSettings() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();

      _showTodayTasks = _prefs?.getBool('showTodayTasks') ?? true;
      _showTomorrowTasks = _prefs?.getBool('showTomorrowTasks') ?? true;
      _showThisWeekTasks = _prefs?.getBool('showThisWeekTasks') ?? true;
      _showWorkTasks = _prefs?.getBool('showWorkTasks') ?? true;
      _showSchoolTasks = _prefs?.getBool('showSchoolTasks') ?? true;
      _showExerciseTasks = _prefs?.getBool('showExerciseTasks') ?? true;
      _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
      _reducedMotion = _prefs?.getBool('reducedMotion') ?? false;

      _enableTaskReminders = _prefs?.getBool('enableTaskReminders') ?? true;
      _enableDueDateNotifications =
          _prefs?.getBool('enableDueDateNotifications') ?? true;
      _enableOverdueNotifications =
          _prefs?.getBool('enableOverdueNotifications') ?? true;
      _enableCompletionCelebrations =
          _prefs?.getBool('enableCompletionCelebrations') ?? true;
      _enableStreakReminders = _prefs?.getBool('enableStreakReminders') ?? true;
      _enableReEngagementNotifications =
          _prefs?.getBool('enableReEngagementNotifications') ?? true;
      _reminderMinutesBefore = _prefs?.getInt('reminderMinutesBefore') ?? 30;

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // Keep default values if loading fails
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await loadSettings();
    }
  }

  // Update settings and save to SharedPreferences
  Future<void> updateShowTodayTasks(bool value) async {
    await _ensureInitialized();
    _showTodayTasks = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('showTodayTasks', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving showTodayTasks setting: $e');
    }
  }

  Future<void> updateShowTomorrowTasks(bool value) async {
    await _ensureInitialized();
    _showTomorrowTasks = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('showTomorrowTasks', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving showTomorrowTasks setting: $e');
    }
  }

  Future<void> updateShowThisWeekTasks(bool value) async {
    await _ensureInitialized();
    _showThisWeekTasks = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('showThisWeekTasks', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving showThisWeekTasks setting: $e');
    }
  }

  Future<void> setShowWorkTasks(bool value) async {
    await _ensureInitialized();
    _showWorkTasks = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('showWorkTasks', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving showWorkTasks setting: $e');
    }
  }

  Future<void> setShowSchoolTasks(bool value) async {
    await _ensureInitialized();
    _showSchoolTasks = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('showSchoolTasks', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving showSchoolTasks setting: $e');
    }
  }

  Future<void> setShowExerciseTasks(bool value) async {
    await _ensureInitialized();
    _showExerciseTasks = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('showExerciseTasks', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving showExerciseTasks setting: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    await _ensureInitialized();
    _isDarkMode = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('isDarkMode', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving isDarkMode setting: $e');
    }
  }

  Future<void> setReducedMotion(bool value) async {
    await _ensureInitialized();
    _reducedMotion = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('reducedMotion', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving reducedMotion setting: $e');
    }
  }

  // Notification setting methods
  Future<void> setEnableTaskReminders(bool value) async {
    await _ensureInitialized();
    _enableTaskReminders = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('enableTaskReminders', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving enableTaskReminders setting: $e');
    }
  }

  Future<void> setEnableDueDateNotifications(bool value) async {
    await _ensureInitialized();
    _enableDueDateNotifications = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('enableDueDateNotifications', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving enableDueDateNotifications setting: $e');
    }
  }

  Future<void> setEnableOverdueNotifications(bool value) async {
    await _ensureInitialized();
    _enableOverdueNotifications = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('enableOverdueNotifications', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving enableOverdueNotifications setting: $e');
    }
  }

  Future<void> setEnableCompletionCelebrations(bool value) async {
    await _ensureInitialized();
    _enableCompletionCelebrations = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('enableCompletionCelebrations', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving enableCompletionCelebrations setting: $e');
    }
  }

  Future<void> setEnableStreakReminders(bool value) async {
    await _ensureInitialized();
    _enableStreakReminders = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('enableStreakReminders', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving enableStreakReminders setting: $e');
    }
  }

  Future<void> setEnableReEngagementNotifications(bool value) async {
    await _ensureInitialized();
    _enableReEngagementNotifications = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setBool('enableReEngagementNotifications', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving enableReEngagementNotifications setting: $e');
    }
  }

  Future<void> setReminderMinutesBefore(int value) async {
    await _ensureInitialized();
    _reminderMinutesBefore = value;
    try {
      if (_prefs == null) {
        _prefs = await SharedPreferences.getInstance();
      }
      await _prefs?.setInt('reminderMinutesBefore', value);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving reminderMinutesBefore setting: $e');
    }
  }
}
