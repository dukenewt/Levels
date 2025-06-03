import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_providers.dart';
import 'services/storage_service.dart';
import 'screens/task_dashboard_screen.dart';
import 'providers/user_provider.dart';

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
    // Use the new wrapper that ensures MaterialApp is always present
    return AppWithMaterialWrapper(
      storageService: storageService,
      // This is the actual content that will be shown once initialization is complete
      appContent: const AppInitializer(),
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
    try {
      // Set context for UserProvider if needed
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setContext(context);
      }
    } catch (e) {
      debugPrint('Error in app initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This will be shown once all providers are initialized
    return const TaskDashboardScreen();
  }
}