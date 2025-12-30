import 'package:attendance_tracker_frontend/screens/app_shell.dart';
import 'package:attendance_tracker_frontend/screens/login_screen.dart';
import 'package:attendance_tracker_frontend/screens/parent/parent_app_shell.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final pref = await SharedPreferences.getInstance();
    final token = pref.getString('jwt_token');
    final userType = pref.getString('user_type');

    if (token != null && token.isNotEmpty) {
      // Logged in already
      if (userType == 'parent') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ParentAppShell()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      }
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(),
    );
  }
}
