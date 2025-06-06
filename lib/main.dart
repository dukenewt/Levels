import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_initialization_manager.dart';
import 'core/simple_app_providers.dart';
import 'core/enhanced_app_providers.dart';
import 'core/offline_storage_service.dart';
import 'services/storage_service.dart';
import 'services/secure_storage_service.dart';
import 'screens/task_dashboard_screen.dart';
import 'core/app_logger.dart';
import 'core/global_error_handler.dart';
import 'core/offline_manager.dart';

const bool USE_ENHANCED_ARCHITECTURE = true; // Toggle this for testing

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core systems first
  AppLogger.instance.initialize();
  GlobalErrorHandler.instance.initialize(AppLogger.instance);
  OfflineManager.instance.initialize();
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final storageService = OfflineCapableStorageService(prefs);
    final secureStorageService = SecureStorageService(prefs);

    runApp(
      USE_ENHANCED_ARCHITECTURE
        ? AppWithEnhancedInitialization(
            storageService: storageService,
            secureStorageService: secureStorageService,
            appContent: const TaskDashboardScreen(),
          )
        : AppWithInitialization(
            storageService: storageService,
            appContent: const TaskDashboardScreen(),
          ),
    );
  } catch (error, stackTrace) {
    AppLogger.instance.error('Failed to initialize app', error, stackTrace);
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily XP',
      home: architectureBanner(
        Scaffold(
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
      ),
    );
  }
}

Widget architectureBanner(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Banner(
      message: USE_ENHANCED_ARCHITECTURE ? "Enhanced" : "Legacy (Safe Mode)",
      location: BannerLocation.topEnd,
      color: USE_ENHANCED_ARCHITECTURE ? Colors.green : Colors.red,
      child: child,
    ),
  );
}