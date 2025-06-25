import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // If user is logged in, go to profile, otherwise to login
      if (userProvider.phone != null && userProvider.phone!.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        Navigator.pushReplacementNamed(context, '/register');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e1e15),
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
