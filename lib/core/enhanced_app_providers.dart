import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/secure_storage_service.dart';
import 'enhanced_app_initialization_manager.dart';
import '../providers/theme_provider.dart';

/// Enhanced provider setup that shows progress and handles errors gracefully.
/// This replaces your simple_app_providers.dart with a more robust version.
class EnhancedAppProviders extends StatelessWidget {
  final StorageService storageService;
  final SecureStorageService? secureStorageService;
  final Widget child;

  const EnhancedAppProviders({
    Key? key,
    required this.storageService,
    this.secureStorageService,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get our enhanced initialization manager
    final initManager = EnhancedAppInitializationManager.instance;
    
    return MultiProvider(
      providers: [
        // All providers are already initialized and ready to use
        // These are like electrical outlets - they're always there, 
        // but might not have power if initialization failed
        ChangeNotifierProvider.value(value: initManager.themeProvider),
        ChangeNotifierProvider.value(value: initManager.settingsProvider),
        ChangeNotifierProvider.value(value: initManager.secureUserProvider),
        
        // These might be null if initialization failed, so we use nullable providers
        if (initManager.secureTaskProvider != null)
          ChangeNotifierProvider.value(value: initManager.secureTaskProvider!),
        if (secureStorageService != null)
          Provider<SecureStorageService>.value(value: secureStorageService!),
      ],
      child: child,
    );
  }
}

/// The main app wrapper with enhanced initialization and beautiful progress UI.
/// This shows users what's happening during startup instead of a blank screen.
class AppWithEnhancedInitialization extends StatefulWidget {
  final StorageService storageService;
  final SecureStorageService? secureStorageService;
  final Widget appContent;

  const AppWithEnhancedInitialization({
    Key? key,
    required this.storageService,
    this.secureStorageService,
    required this.appContent,
  }) : super(key: key);

  @override
  State<AppWithEnhancedInitialization> createState() => _AppWithEnhancedInitializationState();
}

class _AppWithEnhancedInitializationState extends State<AppWithEnhancedInitialization>
    with TickerProviderStateMixin {
  bool _initializationComplete = false;
  String? _criticalError;
  List<String> _warnings = [];
  
  // Animation controllers for a smooth loading experience
  late AnimationController _progressController;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animations for smooth visual feedback
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _initializeApp();
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  /// Initialize the app using our enhanced system with progress tracking.
  Future<void> _initializeApp() async {
    final initManager = EnhancedAppInitializationManager.instance;
    
    // Set the secure storage service if provided
    if (widget.secureStorageService != null) {
      initManager.secureStorageService = widget.secureStorageService;
    }
    try {
      debugPrint('🚀 Starting enhanced app initialization...');
      
      // Start the initialization and track progress
      final result = await initManager.initializeApp(widget.storageService);
      
      if (result.isSuccess) {
        debugPrint('✅ Enhanced initialization complete!');
        
        // Collect any warnings to show the user
        _warnings = initManager.warnings;
        
        // Animate to completion
        await _progressController.forward();
        await _fadeController.forward();
        
        if (mounted) {
          setState(() {
            _initializationComplete = true;
          });
        }
      } else {
        // Handle critical initialization failure
        debugPrint('❌ Critical initialization failure: ${result.error?.message}');
        
        if (mounted) {
          setState(() {
            _criticalError = result.error?.userFriendlyMessage ?? 'Failed to start app';
          });
        }
      }
    } catch (error) {
      debugPrint('❌ Unexpected initialization error: $error');
      
      if (mounted) {
        setState(() {
          _criticalError = 'An unexpected error occurred while starting the app';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Show loading screen with progress while initializing
    if (!_initializationComplete && _criticalError == null) {
      return MaterialApp(
        title: 'Daily XP',
        home: _buildLoadingScreen(),
      );
    }
    
    // Show error screen if critical initialization failed
    if (_criticalError != null) {
      return MaterialApp(
        title: 'Daily XP',
        home: _buildErrorScreen(),
      );
    }
    
    // All initialized successfully - show the real app!
    // If there were warnings, we'll show them after the app loads
    return EnhancedAppProviders(
      storageService: widget.storageService,
      secureStorageService: widget.secureStorageService,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Daily XP',
            theme: themeProvider.currentThemeData,
            home: _warnings.isNotEmpty 
                ? _AppWithWarnings(
                    warnings: _warnings,
                    child: widget.appContent,
                  )
                : widget.appContent,
          );
        },
      ),
    );
  }
  
  /// Build a beautiful loading screen that shows progress.
  /// This is much better than a plain "Loading..." message!
  Widget _buildLoadingScreen() {
    final initManager = EnhancedAppInitializationManager.instance;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light, calming background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon area
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App name
              const Text(
                'Daily XP',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Progress indicator
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: initManager.initializationProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 8,
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress text that changes as we go through phases
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeController,
                    child: Text(
                      initManager.currentPhaseDescription,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Loading dots animation
              _buildLoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build an informative error screen with retry option.
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[400],
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _criticalError!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Retry button
              ElevatedButton.icon(
                onPressed: () {
                  // Reset and try again
                  setState(() {
                    _initializationComplete = false;
                    _criticalError = null;
                    _warnings.clear();
                  });
                  
                  // Reset the initialization manager
                  EnhancedAppInitializationManager.instance.reset();
                  
                  // Try again
                  _initializeApp();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Create animated loading dots for visual appeal.
  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_progressController.value + delay) % 1.0;
            final opacity = (animationValue < 0.5) 
                ? animationValue * 2 
                : (1.0 - animationValue) * 2;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// A wrapper that shows warnings to the user after successful initialization.
/// This lets users know if some features might not work properly.
class _AppWithWarnings extends StatefulWidget {
  final List<String> warnings;
  final Widget child;

  const _AppWithWarnings({
    required this.warnings,
    required this.child,
  });

  @override
  State<_AppWithWarnings> createState() => _AppWithWarningsState();
}

class _AppWithWarningsState extends State<_AppWithWarnings> {
  bool _warningsShown = false;

  @override
  void initState() {
    super.initState();
    // Show warnings after a brief delay so the app can settle
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_warningsShown) {
        _showWarningsDialog();
      }
    });
  }

  void _showWarningsDialog() {
    setState(() {
      _warningsShown = true;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber,
          color: Colors.orange[600],
          size: 48,
        ),
        title: const Text('Some Features May Be Limited'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your app started successfully, but some features may not work properly:',
            ),
            const SizedBox(height: 16),
            ...widget.warnings.map((warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(warning)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            const Text(
              'You can continue using the app, and these issues may resolve themselves when you restart.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 