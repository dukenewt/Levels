import 'package:dailyxp/core/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:dailyxp/core/error_handling.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._();
  static GlobalErrorHandler get instance => _instance;
  GlobalErrorHandler._();
  
  late final AppLogger _logger;
  BuildContext? _currentContext;
  
  void initialize(AppLogger logger) {
    _logger = logger;
    
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _logger.error('Flutter Error', details.exception, details.stack);
      _handleError(details.exception, details.stack, 'Flutter Framework');
    };
    
    // Catch async errors not handled by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.error('Platform Error', error, stack);
      _handleError(error, stack, 'Platform');
      return true;
    };
  }
  
  void setContext(BuildContext context) {
    _currentContext = context;
  }
  
  void _handleError(dynamic error, StackTrace? stack, String source) {
    // Determine error severity
    final severity = _categorizeError(error);
    
    if (severity == ErrorSeverity.critical) {
      _showCriticalErrorDialog(error);
    } else if (severity == ErrorSeverity.warning && _currentContext != null) {
      _showUserFriendlyError(error);
    }
    
    // Always log the error
    _logger.error('$source Error', error, stack);
  }
  
  ErrorSeverity _categorizeError(dynamic error) {
    if (error is OutOfMemoryError || error is StackOverflowError) {
      return ErrorSeverity.critical;
    }
    if (error is NetworkException || error is StorageException) {
      return ErrorSeverity.warning;
    }
    return ErrorSeverity.info;
  }
  
  void _showCriticalErrorDialog(dynamic error) {
    if (_currentContext == null) return;
    
    showDialog(
      context: _currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Application Error'),
        content: const Text(
          'The app encountered a critical error. Please restart the application. If this continues, contact support.'
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit App'),
          ),
        ],
      ),
    );
  }
  
  void _showUserFriendlyError(dynamic error) {
    if (_currentContext == null) return;
    
    ScaffoldMessenger.of(_currentContext!).showSnackBar(
      SnackBar(
        content: Text(_getErrorMessage(error)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(_currentContext!).hideCurrentSnackBar(),
        ),
      ),
    );
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'Network connection issue. Please check your internet.';
    }
    if (error is StorageException) {
      return 'Unable to save data. Please ensure you have sufficient storage.';
    }
    return 'Something went wrong. Please try again.';
  }
}

enum ErrorSeverity { info, warning, critical }