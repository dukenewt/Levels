import 'package:dailyxp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../task_dashboard_screen.dart';
import 'login_screen.dart';
import '../../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key, required this.mainApp}) : super(key: key);
  final Widget mainApp;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          return mainApp;
        }
        return const LoginScreen();
      },
    );
  }
}
