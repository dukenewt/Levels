import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroState {
  stopped,
  workSession,
  shortBreak,
  longBreak,
  paused,
}

class PomodoroTimerService extends ChangeNotifier {
  static const String _stateKey = 'pomodoro_state';
  static const String _sessionCountKey = 'pomodoro_sessions';

  // Default durations in seconds
  static const int workDuration = 25 * 60; // 25 minutes
  static const int shortBreakDuration = 5 * 60; // 5 minutes
  static const int longBreakDuration = 15 * 60; // 15 minutes
  static const int sessionsBeforeLongBreak = 4;

  PomodoroState _state = PomodoroState.stopped;
  int _remainingSeconds = workDuration;
  int _sessionsCompleted = 0;
  Timer? _timer;
  DateTime? _pausedAt;

  // Callbacks
  Function()? onWorkSessionComplete;
  Function()? onBreakComplete;
  Function(PomodoroState)? onStateChange;

  PomodoroTimerService() {
    _loadState();
  }

  // Getters
  PomodoroState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get remainingMinutes => (_remainingSeconds / 60).ceil();
  int get sessionsCompleted => _sessionsCompleted;
  bool get isRunning => _timer != null && _timer!.isActive;
  bool get isPaused => _state == PomodoroState.paused;
  bool get isWorking => _state == PomodoroState.workSession;
  bool get isOnBreak =>
      _state == PomodoroState.shortBreak || _state == PomodoroState.longBreak;

  int get currentDuration {
    switch (_state) {
      case PomodoroState.workSession:
        return workDuration;
      case PomodoroState.shortBreak:
        return shortBreakDuration;
      case PomodoroState.longBreak:
        return longBreakDuration;
      case PomodoroState.stopped:
      case PomodoroState.paused:
        return workDuration;
    }
  }

  double get progress {
    if (_remainingSeconds == 0) return 1.0;
    return 1.0 - (_remainingSeconds / currentDuration);
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // State management
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateData = prefs.getString(_stateKey);
      _sessionsCompleted = prefs.getInt(_sessionCountKey) ?? 0;

      if (stateData != null) {
        final data = json.decode(stateData);
        final stateIndex = data['state'] as int? ?? 0;
        _state = PomodoroState.values[stateIndex];
        _remainingSeconds = data['remainingSeconds'] as int? ?? workDuration;

        // Don't restore running state - always start stopped
        if (_state != PomodoroState.stopped && _state != PomodoroState.paused) {
          _state = PomodoroState.stopped;
          _remainingSeconds = workDuration;
        }
      }
    } catch (e) {
      debugPrint('Error loading pomodoro state: $e');
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'state': _state.index,
        'remainingSeconds': _remainingSeconds,
      };
      await prefs.setString(_stateKey, json.encode(data));
      await prefs.setInt(_sessionCountKey, _sessionsCompleted);
    } catch (e) {
      debugPrint('Error saving pomodoro state: $e');
    }
  }

  // Timer control
  void startWorkSession() {
    _cancelTimer();
    _state = PomodoroState.workSession;
    _remainingSeconds = workDuration;
    _startTimer();
    onStateChange?.call(_state);
    _saveState();
    notifyListeners();
  }

  void startBreak() {
    _cancelTimer();

    // Determine if it's time for a long break
    final shouldTakeLongBreak = _sessionsCompleted > 0 &&
        _sessionsCompleted % sessionsBeforeLongBreak == 0;

    if (shouldTakeLongBreak) {
      _state = PomodoroState.longBreak;
      _remainingSeconds = longBreakDuration;
    } else {
      _state = PomodoroState.shortBreak;
      _remainingSeconds = shortBreakDuration;
    }

    _startTimer();
    onStateChange?.call(_state);
    _saveState();
    notifyListeners();
  }

  void pause() {
    if (_state == PomodoroState.stopped || _state == PomodoroState.paused)
      return;

    _cancelTimer();
    _state = PomodoroState.paused;
    _pausedAt = DateTime.now();
    onStateChange?.call(_state);
    _saveState();
    notifyListeners();
  }

  void resume() {
    if (_state != PomodoroState.paused) return;

    // Restore previous state (work or break)
    if (_remainingSeconds > 0) {
      _state = _remainingSeconds > shortBreakDuration
          ? PomodoroState.workSession
          : PomodoroState.shortBreak;
      _startTimer();
      onStateChange?.call(_state);
      _saveState();
      notifyListeners();
    }
  }

  void stop() {
    _cancelTimer();
    _state = PomodoroState.stopped;
    _remainingSeconds = workDuration;
    _pausedAt = null;
    onStateChange?.call(_state);
    _saveState();
    notifyListeners();
  }

  void reset() {
    _cancelTimer();
    _state = PomodoroState.stopped;
    _remainingSeconds = workDuration;
    _sessionsCompleted = 0;
    _pausedAt = null;
    _saveState();
    notifyListeners();
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTimerComplete() {
    _cancelTimer();

    if (_state == PomodoroState.workSession) {
      _sessionsCompleted++;
      onWorkSessionComplete?.call();
      // Auto-transition to break
      startBreak();
    } else if (_state == PomodoroState.shortBreak ||
        _state == PomodoroState.longBreak) {
      onBreakComplete?.call();
      // Stop after break - user must manually start next session
      stop();
    }

    _saveState();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
