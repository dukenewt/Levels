import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuietModeService extends ChangeNotifier {
  static const String _quietModeKey = 'quiet_mode_state';

  bool _isActive = false;
  DateTime? _startTime;
  DateTime? _endTime;
  Timer? _expirationTimer;

  // Callbacks
  Function()? onQuietModeEnabled;
  Function()? onQuietModeDisabled;

  QuietModeService() {
    _loadState();
  }

  // Getters
  bool get isActive => _isActive;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;

  Duration? get remainingDuration {
    if (!_isActive || _endTime == null) return null;
    final now = DateTime.now();
    if (_endTime!.isBefore(now)) return Duration.zero;
    return _endTime!.difference(now);
  }

  String get remainingTimeFormatted {
    final duration = remainingDuration;
    if (duration == null) return '--:--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // State management
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateData = prefs.getString(_quietModeKey);

      if (stateData != null) {
        final data = json.decode(stateData);
        _isActive = data['isActive'] as bool? ?? false;

        if (data['startTime'] != null) {
          _startTime = DateTime.parse(data['startTime'] as String);
        }

        if (data['endTime'] != null) {
          _endTime = DateTime.parse(data['endTime'] as String);
        }

        // Check if quiet mode should still be active
        if (_isActive && _endTime != null) {
          final now = DateTime.now();
          if (_endTime!.isBefore(now)) {
            // Expired - disable it
            await disable();
          } else {
            // Still active - set up expiration timer
            _scheduleExpirationTimer();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading quiet mode state: $e');
      _isActive = false;
      _startTime = null;
      _endTime = null;
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'isActive': _isActive,
        'startTime': _startTime?.toIso8601String(),
        'endTime': _endTime?.toIso8601String(),
      };
      await prefs.setString(_quietModeKey, json.encode(data));
    } catch (e) {
      debugPrint('Error saving quiet mode state: $e');
    }
  }

  // Control methods
  Future<void> enable({Duration? duration}) async {
    _isActive = true;
    _startTime = DateTime.now();

    if (duration != null) {
      _endTime = _startTime!.add(duration);
      _scheduleExpirationTimer();
    } else {
      _endTime = null;
      _cancelExpirationTimer();
    }

    await _saveState();
    onQuietModeEnabled?.call();
    notifyListeners();

    debugPrint(
        '🔕 Quiet Mode enabled${duration != null ? ' for ${duration.inMinutes} minutes' : ' indefinitely'}');
  }

  Future<void> disable() async {
    _isActive = false;
    _startTime = null;
    _endTime = null;
    _cancelExpirationTimer();

    await _saveState();
    onQuietModeDisabled?.call();
    notifyListeners();

    debugPrint('🔔 Quiet Mode disabled');
  }

  Future<void> toggle({Duration? duration}) async {
    if (_isActive) {
      await disable();
    } else {
      await enable(duration: duration);
    }
  }

  Future<void> extendDuration(Duration additionalTime) async {
    if (!_isActive) return;

    if (_endTime != null) {
      _endTime = _endTime!.add(additionalTime);
      _scheduleExpirationTimer();
      await _saveState();
      notifyListeners();
      debugPrint(
          '🔕 Quiet Mode extended by ${additionalTime.inMinutes} minutes');
    }
  }

  void _scheduleExpirationTimer() {
    _cancelExpirationTimer();

    if (_endTime == null) return;

    final duration = _endTime!.difference(DateTime.now());
    if (duration.isNegative) {
      // Already expired
      disable();
      return;
    }

    _expirationTimer = Timer(duration, () {
      disable();
    });
  }

  void _cancelExpirationTimer() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }

  // Helper method for notification services to check if they should show notifications
  bool shouldBlockNotification() {
    return _isActive;
  }

  // Preset durations for common use cases
  static const Duration duration15Minutes = Duration(minutes: 15);
  static const Duration duration25Minutes = Duration(minutes: 25);
  static const Duration duration45Minutes = Duration(minutes: 45);
  static const Duration duration1Hour = Duration(hours: 1);
  static const Duration duration2Hours = Duration(hours: 2);

  @override
  void dispose() {
    _cancelExpirationTimer();
    super.dispose();
  }
}
