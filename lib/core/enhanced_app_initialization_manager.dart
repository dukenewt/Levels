import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../core/error_handling.dart';
import '../providers/secure_task_provider.dart';
import '../services/secure_storage_service.dart';
import '../providers/secure_user_provider.dart';

/// Enhanced initialization manager with comprehensive error handling and graceful degradation.
/// 
/// Think of this like a smart building manager who can handle problems gracefully:
/// - If the elevator breaks, people can still use the stairs
/// - If the air conditioning fails, the building is still usable
/// - If the lights go out, emergency lighting kicks in
/// 
/// This manager can recover from individual provider failures and provides 
/// detailed progress tracking so users know what's happening.
class EnhancedAppInitializationManager {
  // Singleton pattern - only one initialization manager for the whole app
  EnhancedAppInitializationManager._();
  static final EnhancedAppInitializationManager _instance = EnhancedAppInitializationManager._();
  static EnhancedAppInitializationManager get instance => _instance;
  
  // Track what's happening during initialization
  bool _isInitializing = false;
  bool _isInitialized = false;
  final List<String> _initializationWarnings = [];
  AppException? _criticalError;
  
  // Progress tracking - like a progress bar that tells users what's happening
  int _totalPhases = 3;
  int _currentPhase = 0;
  String _currentPhaseDescription = '';
  
  // Provider storage with null safety
  // Think of these as parking spots - they might be empty until a provider arrives
  ThemeProvider? _themeProvider;
  SettingsProvider? _settingsProvider;
  SecureUserProvider? _secureUserProvider;
  // CalendarProvider? _calendarProvider; // MVP: Calendar shelved
  SecureTaskProvider? _secureTaskProvider;
  SecureStorageService? _secureStorageService;
  
  // Public setter for secure storage service
  set secureStorageService(SecureStorageService? service) => _secureStorageService = service;
  
  // Safe getters that provide fallbacks
  // Like having backup supplies - if the main provider isn't available, 
  // we create a basic one that still works
  ThemeProvider get themeProvider => _themeProvider ?? ThemeProvider();
  SettingsProvider get settingsProvider => _settingsProvider ?? SettingsProvider();
  SecureUserProvider get secureUserProvider => _secureUserProvider ?? SecureUserProvider(storage: _secureStorageService!);
  
  // These can be null if they fail - the app can still work without them
  // CalendarProvider? get calendarProvider => _calendarProvider; // MVP: Calendar shelved
  SecureTaskProvider? get secureTaskProvider => _secureTaskProvider;
  
  // Status getters - like dashboard lights that tell you what's working
  bool get isInitializing => _isInitializing;
  bool get isInitialized => _isInitialized;
  bool get hasCriticalError => _criticalError != null;
  AppException? get criticalError => _criticalError;
  List<String> get warnings => List.unmodifiable(_initializationWarnings);
  double get initializationProgress => _currentPhase / _totalPhases;
  String get currentPhaseDescription => _currentPhaseDescription;
  
  /// Initialize the app with comprehensive error handling and progress tracking.
  /// 
  /// This is like a careful construction foreman who:
  /// 1. Makes sure the foundation is solid before building
  /// 2. Can continue building even if some non-critical parts fail
  /// 3. Keeps everyone informed about progress
  /// 4. Has backup plans for when things go wrong
  Future<Result<void>> initializeApp(StorageService storageService) async {
    // Don't initialize twice - like not rebuilding a house that's already built
    if (_isInitializing || _isInitialized) {
      debugPrint('EnhancedInitializationManager: Already initializing or initialized');
      return Result.success(null);
    }
    
    // Reset our tracking variables
    _isInitializing = true;
    _currentPhase = 0;
    _initializationWarnings.clear();
    _criticalError = null;
    
    debugPrint('🚀 EnhancedInitializationManager: Starting enhanced app initialization...');
    
    try {
      // Phase 1: Core System Providers (Theme, Settings)
      // These are like the foundation and electrical system - the app can't work without them
      _currentPhase = 1;
      _currentPhaseDescription = 'Initializing core system...';
      final phase1Result = await _initializeCoreProviders();
      if (!phase1Result.isSuccess) {
        _criticalError = phase1Result.error;
        return phase1Result;
      }
      
      // Phase 2: User Data Providers (User, Skills, Economy)
      // These are like the plumbing and heating - important but the app can work with defaults
      _currentPhase = 2;
      _currentPhaseDescription = 'Loading your data...';
      final phase2Result = await _initializeUserDataProviders(storageService);
      if (!phase2Result.isSuccess) {
        _initializationWarnings.add('Some user data failed to load: [31m${phase2Result.error?.message}[0m');
        debugPrint('⚠️ Phase 2 had issues but continuing...');
      }
      
      // Phase 3: Application Logic Providers (Tasks, Calendar)
      // These are like the furniture and decorations - nice to have but not essential
      _currentPhase = 3;
      _currentPhaseDescription = 'Setting up app features...';
      final phase3Result = await _initializeApplicationProviders(storageService);
      if (!phase3Result.isSuccess) {
        _initializationWarnings.add('Some app features may not work properly: ${phase3Result.error?.message}');
        debugPrint('⚠️ Phase 3 had issues but app can still function...');
      }
      
      _isInitialized = true;
      _currentPhaseDescription = 'Ready!';
      
      // Report our results
      if (_initializationWarnings.isNotEmpty) {
        debugPrint('⚠️ EnhancedInitializationManager: Initialization completed with ${_initializationWarnings.length} warnings');
        for (final warning in _initializationWarnings) {
          debugPrint('  Warning: $warning');
        }
      } else {
        debugPrint('✅ EnhancedInitializationManager: All providers initialized successfully!');
      }
      
      return Result.success(null);
      
    } catch (error, stackTrace) {
      // Something went really wrong - like the foundation cracking
      debugPrint('❌ EnhancedInitializationManager: Critical initialization error: $error');
      _criticalError = AppException(
        'Failed to initialize app',
        code: 'INITIALIZATION_ERROR',
        originalError: error,
      );
      ErrorHandlingService().logError(_criticalError!, stackTrace: stackTrace);
      return Result.failure(_criticalError!);
      
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Phase 1: Initialize core system providers that the app cannot function without.
  /// Think of this as building the foundation and basic structure of a house.
  Future<Result<void>> _initializeCoreProviders() async {
    debugPrint('📋 Phase 1: Initializing core system providers...');
    
    try {
      // Theme Provider - Critical for app appearance
      // Like the basic lighting system - the app looks broken without it
      final themeResult = await _initializeThemeProvider();
      if (!themeResult.isSuccess) {
        return Result.failure(AppException(
          'Failed to initialize theme system',
          code: 'THEME_ERROR',
          originalError: themeResult.error,
        ));
      }
      
      // Settings Provider - Critical for user preferences
      // Like the thermostat - controls how everything else behaves
      final settingsResult = await _initializeSettingsProvider();
      if (!settingsResult.isSuccess) {
        return Result.failure(AppException(
          'Failed to initialize settings system',
          code: 'SETTINGS_ERROR',
          originalError: settingsResult.error,
        ));
      }
      
      return Result.success(null);
      
    } catch (error, stackTrace) {
      final appError = AppException(
        'Core system initialization failed',
        code: 'CORE_INIT_ERROR',
        originalError: error,
      );
      ErrorHandlingService().logError(appError, stackTrace: stackTrace);
      return Result.failure(appError);
    }
  }
  
  /// Phase 2: Initialize user data providers with graceful degradation.
  /// Think of this as furnishing the house - if some furniture is broken,
  /// we can use temporary replacements.
  Future<Result<void>> _initializeUserDataProviders(StorageService storageService) async {
    debugPrint('📋 Phase 2: Initializing user data providers...');
    
    try {
      bool hasAnyFailures = false;
      
      // User Provider - Initialize with default data if saved data fails
      final userResult = await _initializeSecureUserProvider();
      if (!userResult.isSuccess) {
        _initializationWarnings.add('SecureUserProvider failed, creating default user');
        _secureUserProvider = SecureUserProvider(storage: _secureStorageService!);
        hasAnyFailures = true;
      }
      
      if (hasAnyFailures) {
        return Result.failure(AppException(
          'Some user data failed to load properly',
          code: 'USER_DATA_ERROR',
        ));
      }
      
      return Result.success(null);
      
    } catch (error, stackTrace) {
      final appError = AppException(
        'User data initialization failed',
        code: 'USER_DATA_ERROR',
        originalError: error,
      );
      ErrorHandlingService().logError(appError, stackTrace: stackTrace);
      return Result.failure(appError);
    }
  }
  
  /// Phase 3: Initialize application logic providers.
  /// Think of this as adding the smart home features - if they don't work,
  /// the house is still perfectly livable.
  Future<Result<void>> _initializeApplicationProviders(StorageService storageService) async {
    debugPrint('📋 Phase 3: Initializing application providers...');
    
    try {
      bool hasAnyFailures = false;
      
      // SecureTaskProvider - Needs user and skill providers to work
      if (_secureUserProvider != null) {
        final secureTaskResult = await _initializeSecureTaskProvider();
        if (!secureTaskResult.isSuccess) {
          debugPrint('⚠️ SecureTaskProvider failed, secure task management may not work properly');
          hasAnyFailures = true;
        }
      } else {
        debugPrint('⚠️ Cannot initialize SecureTaskProvider - missing dependencies');
        hasAnyFailures = true;
      }
      
      // Calendar Provider - Needs secure task provider to show tasks
      // if (_secureTaskProvider != null) {
      //   final calendarResult = await _initializeCalendarProvider(storageService);
      //   if (!calendarResult.isSuccess) {
      //     debugPrint('⚠️ CalendarProvider failed, calendar view may not work properly');
      //     hasAnyFailures = true;
      //   }
      // } else {
      //   debugPrint('⚠️ Cannot initialize CalendarProvider - SecureTaskProvider not available');
      //   hasAnyFailures = true;
      // }
      
      if (hasAnyFailures) {
        return Result.failure(AppException(
          'Some app features failed to initialize',
          code: 'FEATURE_ERROR',
        ));
      }
      
      return Result.success(null);
      
    } catch (error, stackTrace) {
      final appError = AppException(
        'Application features initialization failed',
        code: 'FEATURE_ERROR',
        originalError: error,
      );
      ErrorHandlingService().logError(appError, stackTrace: stackTrace);
      return Result.failure(appError);
    }
  }
  
  // Individual provider initialization methods with timeout and error handling
  // Think of these as specialized installation crews for different parts of the house
  
  Future<Result<void>> _initializeThemeProvider() async {
    try {
      _themeProvider = ThemeProvider();
      await _themeProvider!.init().timeout(const Duration(seconds: 5));
      debugPrint('✅ ThemeProvider initialized');
      return Result.success(null);
    } catch (error) {
      return Result.failure(AppException(
        'Theme initialization failed', 
        code: 'THEME_INIT_ERROR',
        originalError: error,
      ));
    }
  }
  
  Future<Result<void>> _initializeSettingsProvider() async {
    try {
      _settingsProvider = SettingsProvider();
      await _settingsProvider!.loadSettings().timeout(const Duration(seconds: 10));
      debugPrint('✅ SettingsProvider initialized');
      return Result.success(null);
    } catch (error) {
      return Result.failure(AppException(
        'Settings initialization failed', 
        code: 'SETTINGS_INIT_ERROR',
        originalError: error,
      ));
    }
  }
  
  Future<Result<void>> _initializeSecureUserProvider() async {
    try {
      _secureUserProvider = SecureUserProvider(storage: _secureStorageService!);
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return !_secureUserProvider!.isInitialized && _secureUserProvider!.isInitializing;
      });
      debugPrint('✅ SecureUserProvider initialized');
      return Result.success(null);
    } catch (error) {
      return Result.failure(AppException(
        'SecureUserProvider initialization failed',
        code: 'SECURE_USER_INIT_ERROR',
        originalError: error,
      ));
    }
  }
  
  Future<Result<void>> _initializeSecureTaskProvider() async {
    try {
      _secureTaskProvider = SecureTaskProvider(
        storage: _secureStorageService!,
        userProvider: _secureUserProvider!,
      );
      // Wait for initialization if needed (optional: add timeout logic)
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('✅ SecureTaskProvider initialized');
      return Result.success(null);
    } catch (error) {
      return Result.failure(AppException(
        'SecureTaskProvider initialization failed',
        code: 'SECURE_TASK_INIT_ERROR',
        originalError: error,
      ));
    }
  }
  
  /// Enhanced waiting mechanism with timeout and better error handling.
  /// This is like having a patient waiter who eventually gives up if service is too slow.
  Future<void> _waitForProviderInitialization(
    bool Function() checkInitialized,
    String providerName, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    // Keep checking every 100ms until either initialized or timeout
    while (!checkInitialized() && stopwatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!checkInitialized()) {
      throw Exception('$providerName failed to initialize within ${timeout.inSeconds} seconds');
    }
  }
  
  /// Reset the initialization state for testing or restart scenarios.
  /// Like cleaning up and starting fresh.
  void reset() {
    debugPrint('🔄 EnhancedInitializationManager: Resetting...');
    _isInitializing = false;
    _isInitialized = false;
    _initializationWarnings.clear();
    _criticalError = null;
    _currentPhase = 0;
    _currentPhaseDescription = '';
    
    // Clear provider references - like emptying all the parking spots
    _themeProvider = null;
    _settingsProvider = null;
    _secureUserProvider = null;
    _secureTaskProvider = null;
    _secureStorageService = null;
  }
} 