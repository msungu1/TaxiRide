import 'dart:async';
import 'package:flutter/material.dart';

/// This is the splash screen that shows your app logo
/// for a few seconds when the app starts.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    /// Wait for 2 seconds before moving to the login screen
    Timer(const Duration(seconds: 2), () {
      // Navigate to the login screen after splash
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color of the splash screen
      backgroundColor: const Color(0xFF1e1e15),

      // Show your logo in the center
      body: Center(
        child: Image.asset(
          'assets/images/logo.png', // Make sure this logo exists
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover, // Make it stretch to fill screen
        ),
      ),
    );
  }
}
