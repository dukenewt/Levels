import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A Result type that can represent either success or failure.
/// This is like a box that either contains your data OR an error message,
/// but never both. It forces us to handle both success and failure cases.
class Result<T> {
  final T? _data;
  final AppException? _error;
  final bool isSuccess;

  // Private constructor to ensure we only create Results through the factory methods
  Result._(this._data, this._error, this.isSuccess);

  /// Creates a successful result containing data
  factory Result.success(T data) {
    return Result._(data, null, true);
  }

  /// Creates a failed result containing an error
  factory Result.failure(AppException error) {
    return Result._(null, error, false);
  }

  /// Get the data if successful, or throw if failed
  /// Only use this when you're sure the result is successful
  T get data {
    if (!isSuccess) {
      throw StateError('Tried to get data from a failed result: [31m[1m[4m${_error?.message}[0m');
    }
    return _data!;
  }

  /// Get the error if failed, or null if successful
  AppException? get error => _error;

  /// Transform the data if successful, or pass through the error if failed
  /// This is useful for chaining operations that might fail
  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      try {
        return Result.success(transform(_data!));
      } catch (error) {
        return Result.failure(AppException('Transform failed', originalError: error));
      }
    } else {
      return Result.failure(_error!);
    }
  }
}

/// A custom exception class that provides better error information.
/// Think of this as a detailed error report instead of just "something went wrong"
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }

  /// Create a user-friendly error message
  String get userFriendlyMessage {
    // You can customize these messages based on error codes
    switch (code) {
      case 'STORAGE_ERROR':
        return 'There was a problem saving your data. Your progress is safe, but some features might not work properly.';
      case 'NETWORK_ERROR':
        return 'Please check your internet connection and try again.';
      case 'INITIALIZATION_ERROR':
        return 'The app is starting up with limited features. Some functions may not be available.';
      default:
        return message;
    }
  }
}

/// Exception for validation errors (invalid input, missing fields, etc.)
class ValidationException extends AppException {
  ValidationException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, code: 'VALIDATION_ERROR', originalError: originalError, stackTrace: stackTrace);
}

/// Exception for storage errors (read/write failures, corruption, etc.)
class StorageException extends AppException {
  StorageException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, code: 'STORAGE_ERROR', originalError: originalError, stackTrace: stackTrace);
}

/// Exception for network errors (connectivity, timeouts, etc.)
class NetworkException extends AppException {
  NetworkException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, code: 'NETWORK_ERROR', originalError: originalError, stackTrace: stackTrace);
}

/// A service to handle and log errors consistently throughout the app.
/// This is like having a dedicated error detective that records what went wrong
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._();
  ErrorHandlingService._();
  factory ErrorHandlingService() => _instance;

  final List<AppException> _errorHistory = [];

  /// Log an error for debugging and potential user reporting
  void logError(AppException error, {StackTrace? stackTrace}) {
    _errorHistory.add(error);
    
    // In debug mode, print detailed error info
    if (kDebugMode) {
      debugPrint('🚨 AppException: ${error.message}');
      if (error.code != null) debugPrint('   Code: ${error.code}');
      if (error.originalError != null) debugPrint('   Original: ${error.originalError}');
      if (stackTrace != null) debugPrint('   Stack: $stackTrace');
    }
    
    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics or Sentry
  }

  /// Get recent errors for debugging
  List<AppException> get recentErrors => List.unmodifiable(_errorHistory.take(10));

  /// Clear error history (useful for testing)
  void clearHistory() {
    _errorHistory.clear();
  }

  /// Show an error to the user using a SnackBar
  /// This centralizes how errors are displayed throughout the app
  void showError(BuildContext context, AppException error) {
    logError(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Something went wrong\n${error.userFriendlyMessage}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
} 