import 'dart:convert';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import 'app_logger.dart';
import 'offline_manager.dart';

class OfflineCapableStorageService extends StorageService {
  final OfflineManager _offlineManager = OfflineManager.instance;
  
  OfflineCapableStorageService(SharedPreferences prefs) : super(prefs);
  
  @override
  Future<void> saveData(String key, dynamic value) async {
    try {
      // Always save locally first for immediate availability
      await super.saveData(key, value);
      
      // Queue for remote sync if offline
      if (!_offlineManager.isOnline) {
        _offlineManager.queueAction(
          SyncDataOfflineAction(key, value),
        );
        AppLogger.instance.info('Queued offline action for key: $key');
      }
    } catch (e) {
      AppLogger.instance.error('Failed to save data for key: $key', e);
      rethrow;
    }
  }
  
  @override
  Future<dynamic> getData(String key, {dynamic defaultValue}) async {
    try {
      // Always try local storage first for performance
      final result = await super.getData(key, defaultValue: defaultValue);
      
      if (result != null || !_offlineManager.isOnline) {
        return result;
      }
      
      // Only attempt remote fetch if local returns null and we're online
      return await _attemptRemoteFetch(key, defaultValue);
    } catch (e) {
      AppLogger.instance.warning('Failed to get data for key: $key', e);
      return defaultValue;
    }
  }
  
  Future<dynamic> _attemptRemoteFetch(String key, dynamic defaultValue) async {
    try {
      // Placeholder for future remote data fetching
      // Currently returns local result as fallback
      return await super.getData(key, defaultValue: defaultValue);
    } catch (e) {
      AppLogger.instance.warning('Remote fetch failed for key: $key', e);
      return defaultValue;
    }
  }
}

// Supporting class for offline functionality
class SyncDataOfflineAction extends OfflineAction {
  final String key;
  final dynamic value;
  
  SyncDataOfflineAction(this.key, this.value);
  
  @override
  String get type => 'sync_data';
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'key': key,
    'value': value,
  };
  
  @override
  Future<void> execute() async {
    // Implementation for remote sync when connection is restored
    AppLogger.instance.info('Syncing data for key: $key');
  }
} 