import 'package:flutter/material.dart';
import 'userPreferences.dart';
import 'login_page.dart';
import 'homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginState();
  }

  Future<void> checkLoginState() async {
    final user = await UserPreferences.getUser();
    final token = await UserPreferences.getToken();

    if (mounted) {
      if (user != null && token != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              userName: user.name,
              currentPhase: user.currentPhase,
              cycleDay: user.cycleDay,
              daysLeft: user.daysLeft,
              userId: user.userId, 
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}