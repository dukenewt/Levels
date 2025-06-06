import 'package:flutter/foundation.dart';
// Create: lib/core/app_logger.dart
class AppLogger {
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;
  AppLogger._();
  
  final List<LogEntry> _logs = [];
  late final bool _isDebugMode;
  
  void initialize({bool debugMode = kDebugMode}) {
    _isDebugMode = debugMode;
  }
  
  void info(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.info, message, null, null, context);
  }
  
  void warning(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context]) {
    _log(LogLevel.warning, message, error, stackTrace, context);
  }
  
  void error(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context]) {
    _log(LogLevel.error, message, error, stackTrace, context);
  }
  
  void _log(LogLevel level, String message, dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
    
    _logs.add(entry);
    
    // Keep only last 1000 logs to prevent memory issues
    if (_logs.length > 1000) {
      _logs.removeRange(0, _logs.length - 1000);
    }
    
    // Print to console in debug mode
    if (_isDebugMode) {
      _printToConsole(entry);
    }
    
    // In production, send critical errors to crash reporting service
    if (level == LogLevel.error && !_isDebugMode) {
      _sendToCrashReporting(entry);
    }
  }
  
  void _printToConsole(LogEntry entry) {
    final emoji = _getEmojiForLevel(entry.level);
    final timeString = entry.timestamp.toString().substring(11, 19);
    
    print('$emoji [$timeString] ${entry.message}');
    if (entry.error != null) {
      print('  Error: ${entry.error}');
    }
    if (entry.stackTrace != null && entry.level == LogLevel.error) {
      print('  Stack: ${entry.stackTrace.toString().split('\n').take(3).join('\n')}');
    }
  }
  
  String _getEmojiForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info: return '📋';
      case LogLevel.warning: return '⚠️';
      case LogLevel.error: return '❌';
    }
  }
  
  Future<void> _sendToCrashReporting(LogEntry entry) async {
    // Implement Firebase Crashlytics or similar service here
    // For now, just store locally for debugging
  }
  
  // Export logs for debugging
  Future<String> exportLogs() async {
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln('${log.timestamp}: [${log.level.name.toUpperCase()}] ${log.message}');
      if (log.error != null) buffer.writeln('  Error: ${log.error}');
      if (log.context != null) buffer.writeln('  Context: ${log.context}');
    }
    return buffer.toString();
  }
  
  List<LogEntry> getRecentErrors() {
    return _logs.where((log) => log.level == LogLevel.error).take(20).toList();
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
  });
}

enum LogLevel { info, warning, error }