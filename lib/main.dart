import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/coin_economy_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'screens/task_dashboard_screen.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences in the background
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  
  runApp(MyApp(storageService: storageService));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({Key? key, required this.storageService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (_) => CoinEconomyProvider(storage: storageService),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(
            storage: storageService,
            userProvider: context.read<UserProvider>(),
            skillProvider: context.read<SkillProvider>(),
          ),
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          return MaterialApp(
            title: 'Daily XP',
            theme: themeProvider.currentThemeData,
            darkTheme: themeProvider.currentThemeData,
            themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Load settings in parallel
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      
      await Future.wait([
        themeProvider.init(),
      ]);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        settingsProvider.loadSettings();
      });

      // Set up user provider context for level up animations
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setContext(context);
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error initializing app: $e';
          _isInitialized = true; // Still set to true to show error UI
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const LoadingScreen();
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const TaskDashboardScreen();
  }
} 