import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dailyxp/core/app_logger.dart';
import 'package:dailyxp/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';

class OfflineManager extends ChangeNotifier {
  static final OfflineManager _instance = OfflineManager._();
  static OfflineManager get instance => _instance;
  OfflineManager._();
  
  bool _isOnline = true;
  final Queue<OfflineAction> _pendingActions = Queue();
  Timer? _connectivityTimer;
  
  bool get isOnline => _isOnline;
  bool get hasOfflineData => _pendingActions.isNotEmpty;
  
  void initialize() {
    _startConnectivityMonitoring();
    _loadPendingActions();
  }
  
  void _startConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }
  
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (!wasOnline && _isOnline) {
        AppLogger.instance.info('Connection restored, syncing offline data');
        await _syncPendingActions();
      } else if (wasOnline && !_isOnline) {
        AppLogger.instance.warning('Connection lost, entering offline mode');
      }
      
      notifyListeners();
    } catch (e) {
      if (_isOnline) {
        _isOnline = false;
        AppLogger.instance.warning('Network connectivity lost', e);
        notifyListeners();
      }
    }
  }
  
  // Queue actions to be performed when online
  void queueAction(OfflineAction action) {
    _pendingActions.add(action);
    _savePendingActions();
    
    if (_isOnline) {
      _syncPendingActions();
    }
  }
  
  Future<void> _syncPendingActions() async {
    while (_pendingActions.isNotEmpty && _isOnline) {
      final action = _pendingActions.removeFirst();
      try {
        await action.execute();
        AppLogger.instance.info('Synced offline action: ${action.type}');
      } catch (e) {
        AppLogger.instance.error('Failed to sync action: ${action.type}', e);
        // Re-queue failed action
        _pendingActions.addFirst(action);
        break;
      }
    }
    _savePendingActions();
  }
  
  Future<void> _loadPendingActions() async {
    // Load from secure storage
    final prefs = await SharedPreferences.getInstance();
    final actionsJson = prefs.getString('pending_offline_actions');
    if (actionsJson != null) {
      // Deserialize and populate _pendingActions
    }
  }
  
  Future<void> _savePendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    // Serialize _pendingActions and save
    await prefs.setString('pending_offline_actions', jsonEncode(_pendingActions.map((a) => a.toJson()).toList()));
  }
  
  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }
}

abstract class OfflineAction {
  String get type;
  Map<String, dynamic> toJson();
  Future<void> execute();
}

// Example offline action for task creation
class CreateTaskOfflineAction extends OfflineAction {
  final Task task;
  
  CreateTaskOfflineAction(this.task);
  
  @override
  String get type => 'create_task';
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'task': task.toJson(),
  };
  
  @override
  Future<void> execute() async {
    // Sync with server when online
    // For now, just ensure it's saved locally
  }
}