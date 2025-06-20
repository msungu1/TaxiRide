import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      Navigator.pushReplacementNamed(context, '/tripdetails'
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e1e15),
      body: Center(
        child: Image.asset(
          'assets/images/logo.png', // replace with your image path
          // fit: BoxFit.contain, // Makes the image cover the whole screen

          width: double.infinity,

          height: double.infinity,

          // width: 180,
          // height: 180,
        ),
        ),

    );
  }
}
