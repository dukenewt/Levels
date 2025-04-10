import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'screens/task_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        Provider<StorageService>.value(
          value: storageService,
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider2<UserProvider, SkillProvider, TaskProvider>(
          create: (context) => TaskProvider(
            context.read<UserProvider>(),
            context.read<SkillProvider>(),
            context.read<StorageService>(),
          ),
          update: (context, userProvider, skillProvider, previous) => TaskProvider(
            userProvider,
            skillProvider,
            context.read<StorageService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Level Up Tasks',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF78A1E8),
            primary: const Color(0xFF78A1E8),
            secondary: const Color(0xFFF5AC3D),
            background: const Color(0xFFD7CFC6),
            surface: const Color(0xFFD7CFC6),
            brightness: Brightness.light,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF78A1E8),
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF78A1E8)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFFF5AC3D),
              foregroundColor: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFF5AC3D),
            foregroundColor: Colors.white,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
            headlineMedium: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            titleLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF78A1E8),
            primary: const Color(0xFF78A1E8),
            secondary: const Color(0xFFF5AC3D),
            background: const Color(0xFF2C2C2C),
            surface: const Color(0xFF2C2C2C),
            brightness: Brightness.dark,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFF3D3D3D),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF78A1E8),
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF3D3D3D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF78A1E8)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFFF5AC3D),
              foregroundColor: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFF5AC3D),
            foregroundColor: Colors.white,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
            headlineMedium: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            titleLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const AppInitializer(),
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
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the next frame to ensure the widget tree is built
    await Future.microtask(() {});
    
    if (!mounted) return;
    
    // Load settings
    await Provider.of<SettingsProvider>(context, listen: false).loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return const TaskDashboardScreen();
  }
} 