/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'app_initialization_manager.dart';
import '../providers/theme_provider.dart';

/// Simplified provider setup that uses the AppInitializationManager
/// to ensure all providers are initialized in the correct order.
/// This replaces the complex dependency chain approach.
class SimpleAppProviders extends StatelessWidget {
  final StorageService storageService;
  final Widget child;

  const SimpleAppProviders({
    Key? key,
    required this.storageService,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Since all providers are already initialized by AppInitializationManager,
    // we can provide them directly without complex dependency chains
    final initManager = AppInitializationManager.instance;
    
    return MultiProvider(
      providers: [
        // All providers are already initialized and ready to use
        ChangeNotifierProvider.value(value: initManager.themeProvider),
        ChangeNotifierProvider.value(value: initManager.settingsProvider),
        ChangeNotifierProvider.value(value: initManager.skillProvider),
        ChangeNotifierProvider.value(value: initManager.specializationProvider),
        ChangeNotifierProvider.value(value: initManager.coinEconomyProvider),
        ChangeNotifierProvider.value(value: initManager.taskProvider),
        ChangeNotifierProvider.value(value: initManager.calendarProvider),
      ],
      child: child,
    );
  }
}

/// The main app wrapper that handles initialization and provides the MaterialApp.
/// This replaces the complex AppWithMaterialWrapper approach.
class AppWithInitialization extends StatefulWidget {
  final StorageService storageService;
  final Widget appContent;

  const AppWithInitialization({
    Key? key,
    required this.storageService,
    required this.appContent,
  }) : super(key: key);

  @override
  State<AppWithInitialization> createState() => _AppWithInitializationState();
}

class _AppWithInitializationState extends State<AppWithInitialization> {
  bool _initializationComplete = false;
  String? _initializationError;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  /// Initialize the app using our centralized initialization manager.
  /// This method is much simpler than the complex dependency checking we had before.
  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Starting app initialization...');
      
      // This single call handles all the complex provider coordination
      await AppInitializationManager.instance.initializeApp(widget.storageService);
      
      debugPrint('✅ App initialization complete!');
      
      // Only update UI after everything is truly ready
      if (mounted) {
        setState(() {
          _initializationComplete = true;
        });
      }
    } catch (error) {
      debugPrint('❌ App initialization failed: $error');
      
      // Show user-friendly error instead of crashing
      if (mounted) {
        setState(() {
          _initializationError = 'Failed to start app: $error';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_initializationComplete && _initializationError == null) {
      return MaterialApp(
        title: 'Daily XP',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Starting Daily XP...'),
                const SizedBox(height: 16),
                Text(
                  'Initializing your data...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show error screen if initialization failed
    if (_initializationError != null) {
      return MaterialApp(
        title: 'Daily XP',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _initializationError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Reset and try again
                      setState(() {
                        _initializationComplete = false;
                        _initializationError = null;
                      });
                      AppInitializationManager.instance.reset();
                      _initializeApp();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    // All initialized successfully - show the real app!
    // Now we can safely provide all the initialized providers
    return SimpleAppProviders(
      storageService: widget.storageService,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Daily XP',
            theme: themeProvider.currentThemeData,
            home: widget.appContent,
          );
        },
      ),
    );
  }
}
*/