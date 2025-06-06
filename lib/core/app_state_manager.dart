// Create a new file: lib/core/app_state_manager.dart
class AppStateManager extends ChangeNotifier {
  // Core state that all providers need
  bool _isInitialized = false;
  bool _isOffline = false;
  final Map<String, dynamic> _sharedState = {};
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOffline => _isOffline;
  
  // Central method to update shared state
  void updateSharedState(String key, dynamic value) {
    _sharedState[key] = value;
    notifyListeners();
  }
  
  T? getSharedState<T>(String key) => _sharedState[key] as T?;
  
  // Initialize core app state
  Future<void> initialize() async {
    try {
      // Initialize only the most essential state here
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to initialize app state', e);
      rethrow;
    }
  }
  
  void setOfflineMode(bool offline) {
    _isOffline = offline;
    notifyListeners();
  }
}