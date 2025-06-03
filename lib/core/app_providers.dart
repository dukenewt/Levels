import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/coin_economy_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/specialization_provider.dart';
import '../providers/calendar_provider.dart';
import '../services/storage_service.dart';
import '../screens/loading_screen.dart';

class AppProviders extends StatelessWidget {
  final StorageService storageService;
  final Widget child;

  const AppProviders({
    Key? key,
    required this.storageService,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // PHASE 1: Independent providers (no dependencies)
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..init(), // Initialize immediately
        ),
        
        // Settings Provider with automatic initialization
        ChangeNotifierProvider(
          create: (context) {
            final settingsProvider = SettingsProvider();
            // Trigger initialization immediately after creation
            // Using Future.microtask to ensure it runs after the provider is fully set up
            Future.microtask(() async {
              debugPrint('🔧 Starting Settings Provider initialization...');
              try {
                await settingsProvider.loadSettings();
                debugPrint('✅ Settings Provider initialization completed!');
              } catch (e) {
                debugPrint('❌ Settings Provider initialization failed: $e');
              }
            });
            return settingsProvider;
          },
        ),
        
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SkillProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SpecializationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CoinEconomyProvider(storage: storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => CalendarProvider(storage: storageService),
        ),
        
        // PHASE 2: Dependent providers using ChangeNotifierProxyProvider
        ChangeNotifierProxyProvider3<UserProvider, SkillProvider, SettingsProvider, TaskProvider?>(
          create: (_) => null, // Start with null
          update: (context, userProvider, skillProvider, settingsProvider, previous) {
            // Only create TaskProvider when dependencies are ready
            if (userProvider.isInitialized && 
                skillProvider.isInitialized && 
                settingsProvider.isInitialized) {
              
              // If we don't have a TaskProvider yet, create one
              if (previous == null) {
                debugPrint('🎉 Creating TaskProvider - all dependencies ready!');
                return TaskProvider(
                  storage: storageService,
                  userProvider: userProvider,
                  skillProvider: skillProvider,
                );
              }
              
              // Return the existing TaskProvider
              return previous;
            }
            
            debugPrint('TaskProvider dependencies not ready yet:');
            debugPrint('  UserProvider: ${userProvider.isInitialized}');
            debugPrint('  SkillProvider: ${skillProvider.isInitialized}');
            debugPrint('  SettingsProvider: ${settingsProvider.isInitialized}');
            
            return previous; // Keep previous or null if not ready
          },
        ),
      ],
      // Now we always provide the child, and let the child handle loading states
      child: child,
    );
  }
}

// New wrapper that provides MaterialApp and handles initialization
class AppWithMaterialWrapper extends StatefulWidget {
  final StorageService storageService;
  final Widget appContent;

  const AppWithMaterialWrapper({
    Key? key,
    required this.storageService,
    required this.appContent,
  }) : super(key: key);

  @override
  State<AppWithMaterialWrapper> createState() => _AppWithMaterialWrapperState();
}

class _AppWithMaterialWrapperState extends State<AppWithMaterialWrapper> {
  bool _hasInitializedCalendar = false;

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      storageService: widget.storageService,
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          return MaterialApp(
            title: 'Daily XP',
            theme: themeProvider.currentThemeData,
            // The home will be determined by initialization status
            home: AppInitializationChecker(
              appContent: widget.appContent,
              onCalendarInit: () {
                if (!_hasInitializedCalendar) {
                  _hasInitializedCalendar = true;
                  debugPrint('Calendar initialization callback triggered');
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// This widget checks initialization status and shows appropriate screen
class AppInitializationChecker extends StatelessWidget {
  final Widget appContent;
  final VoidCallback onCalendarInit;

  const AppInitializationChecker({
    Key? key,
    required this.appContent,
    required this.onCalendarInit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer5<UserProvider, SkillProvider, SettingsProvider, TaskProvider?, CalendarProvider>(
      builder: (context, userProvider, skillProvider, settingsProvider, taskProvider, calendarProvider, _) {
        
        // Debug: Print the status of each provider
        debugPrint('=== PROVIDER STATUS CHECK ===');
        debugPrint('UserProvider initialized: ${userProvider.isInitialized}');
        debugPrint('SkillProvider initialized: ${skillProvider.isInitialized}');
        debugPrint('SettingsProvider initialized: ${settingsProvider.isInitialized}');
        debugPrint('TaskProvider exists: ${taskProvider != null}');
        debugPrint('CalendarProvider initialized: ${calendarProvider.isInitialized}');
        
        // Check if all required providers are initialized
        final bool coreProvidersReady = userProvider.isInitialized &&
                                       skillProvider.isInitialized &&
                                       settingsProvider.isInitialized &&
                                       taskProvider != null;

        debugPrint('Core providers ready: $coreProvidersReady');

        // Initialize calendar provider once core providers are ready
        if (coreProvidersReady && !calendarProvider.isInitialized) {
          debugPrint('Attempting to initialize CalendarProvider...');
          // Use addPostFrameCallback to avoid calling during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            debugPrint('Initializing CalendarProvider now');
            calendarProvider.initialize(taskProvider);
            onCalendarInit();
          });
        }

        final bool allReady = coreProvidersReady && calendarProvider.isInitialized;
        debugPrint('All providers ready: $allReady');
        debugPrint('=== END STATUS CHECK ===\n');

        // Show loading screen if not ready (but now it's inside MaterialApp!)
        if (!allReady) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text('Initializing your app...'),
                  const SizedBox(height: 16),
                  // Show which providers are ready
                  Column(
                    children: [
                      _buildProviderStatus('User Provider', userProvider.isInitialized),
                      _buildProviderStatus('Skill Provider', skillProvider.isInitialized),
                      _buildProviderStatus('Settings Provider', settingsProvider.isInitialized),
                      _buildProviderStatus('Task Provider', taskProvider != null),
                      _buildProviderStatus('Calendar Provider', calendarProvider.isInitialized),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        // All providers ready, show the actual app content
        debugPrint('🎉 All providers ready - showing main app!');
        return appContent;
      },
    );
  }
  
  Widget _buildProviderStatus(String name, bool isReady) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.hourglass_empty,
            color: isReady ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: isReady ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}