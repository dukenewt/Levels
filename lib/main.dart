import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_initialization_manager.dart';
import 'core/simple_app_providers.dart';
import 'services/storage_service.dart';
import 'screens/task_dashboard_screen.dart';

void main() async {
  // Ensure Flutter is ready before we start initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize SharedPreferences - this is the only setup we need to do in main()
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    
    // Start the app with our new, clean initialization system
    runApp(MyApp(storageService: storageService));
  } catch (error) {
    // If we can't even get SharedPreferences, show a basic error
    debugPrint('Failed to initialize basic services: $error');
    runApp(const ErrorApp());
  }
}

/// The main app widget - much simpler than before!
class MyApp extends StatelessWidget {
  final StorageService storageService;
  
  const MyApp({Key? key, required this.storageService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This single widget handles all initialization and provider setup
    return AppWithInitialization(
      storageService: storageService,
      appContent: const TaskDashboardScreen(),
    );
  }
}

/// Fallback app if basic initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily XP',
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
  }
}