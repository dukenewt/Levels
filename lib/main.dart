import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_logger.dart';
import 'core/global_error_handler.dart';
import 'core/offline_manager.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/task_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/firestore_service.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/epic_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/task_dashboard_screen.dart';
import 'screens/epic_project_screen.dart';
import 'services/secure_storage_service.dart';
import 'services/app_talent_manager.dart';
import 'controllers/talent_perk_controller.dart';
import 'services/talent_trigger_service.dart';
import 'config/feature_flags.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize core systems first
  AppLogger.instance.initialize();
  GlobalErrorHandler.instance.initialize(AppLogger.instance);
  OfflineManager.instance.initialize();

  // Initialize notification service
  await TaskNotificationService.instance.initialize();

  try {
    final prefs = await SharedPreferences.getInstance();
    final secureStorageService = SecureStorageService(prefs);

    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>(
            create: (_) => AuthService(),
          ),
          Provider<FirestoreService>(
            create: (_) => FirestoreService(),
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider()..init(),
          ),
          ChangeNotifierProxyProvider2<AuthService, FirestoreService,
              UserProvider>(
            create: (context) => UserProvider(
              context.read<AuthService>(),
              context.read<FirestoreService>(),
            ),
            update: (context, authService, firestoreService, previous) =>
                UserProvider(authService, firestoreService)
                  ..updateDependencies(authService, firestoreService),
          ),
          ChangeNotifierProxyProvider<UserProvider, TaskProvider>(
            create: (context) => TaskProvider(
              storage: secureStorageService,
              userProvider: context.read<UserProvider>(),
            ),
            update: (context, userProvider, previous) =>
                previous!..updateUserProvider(userProvider),
          ),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(
            create: (_) => EpicProvider(storage: secureStorageService),
          ),
          // NEW: TalentPerkController - added alongside existing providers
          ChangeNotifierProvider(
            create: (_) => TalentPerkController(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (error, stackTrace) {
    AppLogger.instance.error('Failed to initialize app', error, stackTrace);
    runApp(const ErrorApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    final service = TaskNotificationService.instance;
    final hasPermission = await service.hasNotificationPermission();
    if (!hasPermission) {
      await service.requestNotificationPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Daily XP',
          theme: themeProvider.currentThemeData,
          home: const AuthWrapper(
            mainApp: MainTabScaffold(),
          ),
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Daily XP',
          theme: themeProvider.currentThemeData,
          home: Scaffold(
            body: Center(
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
                    'Failed to Start App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not initialize basic services.\nPlease restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({Key? key}) : super(key: key);

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _selectedIndex = 0;
  bool _talentManagerInitialized = false;

  List<Widget> _getScreens(bool hasProjectManagement) {
    if (hasProjectManagement) {
      return [
        TaskDashboardScreen(),
        EpicProjectScreen(),
        StatsScreen(),
        ProfileScreen(),
      ];
    } else {
      return [
        TaskDashboardScreen(),
        StatsScreen(),
        ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(bool hasProjectManagement) {
    if (hasProjectManagement) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.rocket_launch),
          label: 'Epics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTalentManager();
  }

  void _initializeTalentManager() {
    if (_talentManagerInitialized) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Always initialize the new talent trigger service (it can monitor for user changes)
    if (FeatureFlags.shouldUseNewTalentSystem()) {
      final talentPerkController =
          Provider.of<TalentPerkController>(context, listen: false);
      TalentTriggerService.instance.initialize(context, talentPerkController);
    }

    if (userProvider.user != null) {
      AppTalentManager.instance.initialize(context, userProvider);
      _talentManagerInitialized = true;

      // Check for pending talent choices
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (FeatureFlags.shouldUseNewTalentSystem()) {
          // Use new system
          TalentTriggerService.instance.checkPendingTalentChoices();
        } else {
          // Use old system
          AppTalentManager.instance.checkPendingTalentChoices();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final hasProjectManagement =
            user?.hasProjectManagementTalent() ?? false;
        final screens = _getScreens(hasProjectManagement);
        final navItems = _getNavItems(hasProjectManagement);

        // Adjust selected index if navigation structure changed
        if (_selectedIndex >= screens.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            items: navItems,
          ),
        );
      },
    );
  }
}
