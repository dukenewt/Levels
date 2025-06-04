import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/coin_economy_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/specialization_provider.dart';
import '../services/storage_service.dart';

/// Manages the initialization of all app providers in the correct order.
/// This class ensures that dependencies are initialized before the providers that need them,
/// preventing race conditions and ensuring reliable app startup.
class AppInitializationManager {
  // Private constructor to prevent external instantiation
  AppInitializationManager._();
  
  // Singleton instance - there should only be one initialization manager
  static final AppInitializationManager _instance = AppInitializationManager._();
  static AppInitializationManager get instance => _instance;
  
  // Track initialization state to prevent duplicate initialization
  bool _isInitializing = false;
  bool _isInitialized = false;
  
  // Store the initialized providers so they can be accessed later
  late final ThemeProvider themeProvider;
  late final SettingsProvider settingsProvider;
  late final UserProvider userProvider;
  late final SkillProvider skillProvider;
  late final SpecializationProvider specializationProvider;
  late final CoinEconomyProvider coinEconomyProvider;
  late final TaskProvider taskProvider;
  late final CalendarProvider calendarProvider;
  
  // Getters to check initialization state
  bool get isInitializing => _isInitializing;
  bool get isInitialized => _isInitialized;
  
  /// Initializes all app providers in the correct dependency order.
  /// This method is safe to call multiple times - it will only run once.
  Future<void> initializeApp(StorageService storageService) async {
    // Prevent multiple simultaneous initializations
    if (_isInitializing || _isInitialized) {
      debugPrint('AppInitializationManager: Already initializing or initialized, skipping...');
      return;
    }
    
    _isInitializing = true;
    debugPrint('🚀 AppInitializationManager: Starting app initialization...');
    
    try {
      // Phase 1: Initialize providers with no dependencies
      // These providers don't need any other providers to function
      await _initializeIndependentProviders();
      
      // Phase 2: Initialize providers that depend on Phase 1 providers
      // These providers need the basic services from Phase 1
      await _initializeDependentProviders(storageService);
      
      // Phase 3: Initialize complex providers that need multiple dependencies
      // These providers need data from multiple other providers
      await _initializeComplexProviders(storageService);
      
      _isInitialized = true;
      debugPrint('✅ AppInitializationManager: All providers initialized successfully!');
      
    } catch (error, stackTrace) {
      debugPrint('❌ AppInitializationManager: Initialization failed: $error');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow; // Re-throw so the app can show an error screen
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Phase 1: Initialize providers that have no dependencies on other providers.
  /// These are typically configuration and theme providers.
  Future<void> _initializeIndependentProviders() async {
    debugPrint('📋 Phase 1: Initializing independent providers...');
    
    // Theme provider manages app appearance and has no dependencies
    themeProvider = ThemeProvider();
    await themeProvider.init();
    debugPrint('✅ ThemeProvider initialized');
    
    // Settings provider manages user preferences and has no dependencies
    settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();
    debugPrint('✅ SettingsProvider initialized');
    
    // Specialization provider manages skill specializations and has no dependencies
    specializationProvider = SpecializationProvider();
    // Note: SpecializationProvider currently has no async initialization,
    // but we include it here for consistency and future extensibility
    debugPrint('✅ SpecializationProvider initialized');
  }
  
  /// Phase 2: Initialize providers that depend on Phase 1 providers.
  /// These providers need basic configuration before they can start.
  Future<void> _initializeDependentProviders(StorageService storageService) async {
    debugPrint('📋 Phase 2: Initializing dependent providers...');
    
    // User provider manages user data and might use settings for preferences
    userProvider = UserProvider();
    // UserProvider's initialization is handled internally, but we ensure it completes
    while (!userProvider.isInitialized && userProvider.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    debugPrint('✅ UserProvider initialized');
    
    // Skill provider manages skills and achievements
    skillProvider = SkillProvider();
    while (!skillProvider.isInitialized && skillProvider.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    debugPrint('✅ SkillProvider initialized');
    
    // Coin economy provider manages the in-app currency system
    coinEconomyProvider = CoinEconomyProvider(storage: storageService);
    // CoinEconomyProvider loads its data in the constructor, so we give it a moment
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('✅ CoinEconomyProvider initialized');
  }
  
  /// Phase 3: Initialize complex providers that need multiple dependencies.
  /// These providers require data from multiple other providers to function correctly.
  Future<void> _initializeComplexProviders(StorageService storageService) async {
    debugPrint('📋 Phase 3: Initializing complex providers...');
    
    // Task provider needs both user and skill providers to function
    taskProvider = TaskProvider(
      storage: storageService,
      userProvider: userProvider,
      skillProvider: skillProvider,
    );
    // TaskProvider should be ready immediately since its dependencies are initialized
    debugPrint('✅ TaskProvider initialized');
    
    // Calendar provider needs task provider to show tasks on calendar
    calendarProvider = CalendarProvider(storage: storageService);
    await calendarProvider.initialize(taskProvider);
    debugPrint('✅ CalendarProvider initialized');
  }
  
  /// Resets the initialization state. Useful for testing or app restart scenarios.
  /// In production, this should rarely be needed.
  void reset() {
    debugPrint('🔄 AppInitializationManager: Resetting initialization state...');
    _isInitializing = false;
    _isInitialized = false;
  }
}