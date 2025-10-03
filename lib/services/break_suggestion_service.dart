import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BreakType {
  walk,
  stretch,
  rest,
  longBreak;

  String get displayName {
    switch (this) {
      case BreakType.walk:
        return 'Take a Walk';
      case BreakType.stretch:
        return 'Stretch Break';
      case BreakType.rest:
        return 'Rest & Recharge';
      case BreakType.longBreak:
        return 'Extended Break';
    }
  }

  String get description {
    switch (this) {
      case BreakType.walk:
        return 'Get up and move around for 5-10 minutes';
      case BreakType.stretch:
        return 'Stretch your body for 3-5 minutes';
      case BreakType.rest:
        return 'Close your eyes and rest for 5 minutes';
      case BreakType.longBreak:
        return 'Take a longer break to fully recharge (15-20 minutes)';
    }
  }

  Duration get suggestedDuration {
    switch (this) {
      case BreakType.walk:
        return const Duration(minutes: 10);
      case BreakType.stretch:
        return const Duration(minutes: 5);
      case BreakType.rest:
        return const Duration(minutes: 5);
      case BreakType.longBreak:
        return const Duration(minutes: 20);
    }
  }
}

class BreakSuggestionService extends ChangeNotifier {
  static const String _stateKey = 'break_suggestion_state';

  // Default: suggest break after 50 minutes of work
  static const Duration defaultWorkDuration = Duration(minutes: 50);

  bool _isTracking = false;
  DateTime? _workStartTime;
  DateTime? _lastBreakTime;
  int _consecutiveWorkSessions = 0;
  Timer? _checkTimer;
  bool _breakSuggested = false;

  // Callbacks
  Function(BreakType)? onBreakSuggested;
  Function()? onBreakCompleted;

  BreakSuggestionService() {
    _loadState();
  }

  // Getters
  bool get isTracking => _isTracking;
  DateTime? get workStartTime => _workStartTime;
  DateTime? get lastBreakTime => _lastBreakTime;
  bool get breakSuggested => _breakSuggested;
  int get consecutiveWorkSessions => _consecutiveWorkSessions;

  Duration? get currentWorkDuration {
    if (!_isTracking || _workStartTime == null) return null;
    return DateTime.now().difference(_workStartTime!);
  }

  String get currentWorkDurationFormatted {
    final duration = currentWorkDuration;
    if (duration == null) return '--:--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool get shouldSuggestBreak {
    if (!_isTracking || _workStartTime == null) return false;
    final workDuration = currentWorkDuration!;
    return workDuration >= defaultWorkDuration && !_breakSuggested;
  }

  BreakType get suggestedBreakType {
    // Suggest longer breaks after multiple work sessions
    if (_consecutiveWorkSessions >= 3) {
      return BreakType.longBreak;
    }

    // Rotate through break types based on session count
    switch (_consecutiveWorkSessions % 3) {
      case 0:
        return BreakType.walk;
      case 1:
        return BreakType.stretch;
      default:
        return BreakType.rest;
    }
  }

  // State management
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateData = prefs.getString(_stateKey);

      if (stateData != null) {
        final data = json.decode(stateData);
        _isTracking = data['isTracking'] as bool? ?? false;
        _consecutiveWorkSessions = data['consecutiveWorkSessions'] as int? ?? 0;
        _breakSuggested = data['breakSuggested'] as bool? ?? false;

        if (data['workStartTime'] != null) {
          _workStartTime = DateTime.parse(data['workStartTime'] as String);
        }

        if (data['lastBreakTime'] != null) {
          _lastBreakTime = DateTime.parse(data['lastBreakTime'] as String);
        }

        // Don't restore tracking state - user must manually start
        if (_isTracking) {
          _isTracking = false;
          _workStartTime = null;
        }
      }
    } catch (e) {
      debugPrint('Error loading break suggestion state: $e');
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'isTracking': _isTracking,
        'workStartTime': _workStartTime?.toIso8601String(),
        'lastBreakTime': _lastBreakTime?.toIso8601String(),
        'consecutiveWorkSessions': _consecutiveWorkSessions,
        'breakSuggested': _breakSuggested,
      };
      await prefs.setString(_stateKey, json.encode(data));
    } catch (e) {
      debugPrint('Error saving break suggestion state: $e');
    }
  }

  // Control methods
  void startTracking() {
    _isTracking = true;
    _workStartTime = DateTime.now();
    _breakSuggested = false;
    _startCheckTimer();
    _saveState();
    notifyListeners();
    debugPrint('⏱️ Break tracking started');
  }

  void stopTracking() {
    _isTracking = false;
    _workStartTime = null;
    _breakSuggested = false;
    _stopCheckTimer();
    _saveState();
    notifyListeners();
    debugPrint('⏱️ Break tracking stopped');
  }

  void takeBreak(BreakType? type) {
    final breakType = type ?? suggestedBreakType;
    _lastBreakTime = DateTime.now();
    _consecutiveWorkSessions++;
    _breakSuggested = false;

    // Stop current tracking
    _isTracking = false;
    _workStartTime = null;
    _stopCheckTimer();

    _saveState();
    notifyListeners();

    debugPrint('🚶 Taking ${breakType.displayName}');
    onBreakCompleted?.call();
  }

  void dismissBreakSuggestion() {
    _breakSuggested = false;
    _saveState();
    notifyListeners();
    debugPrint('⏭️ Break suggestion dismissed');
  }

  void resetSessions() {
    _consecutiveWorkSessions = 0;
    _lastBreakTime = null;
    _saveState();
    notifyListeners();
  }

  void _startCheckTimer() {
    _stopCheckTimer();
    // Check every minute if we should suggest a break
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (shouldSuggestBreak) {
        _suggestBreak();
      }
      notifyListeners(); // Update UI with current work duration
    });
  }

  void _stopCheckTimer() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  void _suggestBreak() {
    if (_breakSuggested) return;

    _breakSuggested = true;
    final breakType = suggestedBreakType;

    onBreakSuggested?.call(breakType);
    _saveState();
    notifyListeners();

    debugPrint('💡 Suggesting break: ${breakType.displayName}');
  }

  // Helper to get time since last break
  String? getTimeSinceLastBreak() {
    if (_lastBreakTime == null) return null;

    final duration = DateTime.now().difference(_lastBreakTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hours ago';
    } else if (minutes > 0) {
      return '$minutes minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _stopCheckTimer();
    super.dispose();
  }
}
