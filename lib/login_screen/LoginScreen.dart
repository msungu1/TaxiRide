import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../UserProvider/UserProvider.dart';


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const StitchLoginApp());
}

class StitchLoginApp extends StatelessWidget {
  const StitchLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
       scaffoldBackgroundColor:Color(0xFF40402b),

        textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: Colors.red,
          displayColor: Colors.black,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF41402b),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.blue),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
// =======================

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F15),
      resizeToAvoidBottomInset: true, // Ensures space when keyboard appears

      // Add this line to apply the olive black background

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            // Top bar with question icon

            padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children:[
                  Row(

                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      onPressed: () {},

                  ),
              ),

            ],
            ),

            // Welcome Text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Welcome Back To',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:Colors.white,

                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),

              ),
            ),

            // 👇 Add this image widget right below the text
            // Padding(
            //   padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            //   child: Image.asset(
            //     'assets/images/logo.png',
            //     // width: double.infinity,
            //     // width: 500, // <-- Set width to 100
            //
            //     height: 140,
            //     fit: BoxFit.fitWidth, // properly assigned
            //
            //     // fit: BoxFit.contain,
            //   ),
            // ),


                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),







                  const SizedBox(height: 8),

            // Phone Number Field
            const InputField(
              label: 'Phone Number',
              hint: 'Enter your phone number',
              obscureText: false,


            ),



            // Password Field
            const InputField(
              label: 'Password',
              hint: 'Enter your password',
              obscureText: true,
            ),


                  const SizedBox(height: 24),

            // Login Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700), // Gold
                    // foregroundColor: const Color(0xFF1f1f14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ),
            ),

            // Forgot Password and Sign Up
            TextButton(
              onPressed: () {},
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFFbebe0d),
                  fontSize: 20,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),


            TextButton(
              onPressed: () {},
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: Color(0xFFbebe0d),
                  fontSize: 18,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 20),


        ],
        ),
       ),
       ),

      ),
    );
  }
}

class InputField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscureText;

  const InputField({
    super.key,
    required this.label,
    required this.hint,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              // backgroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
            hintText: hint,
            filled: true,
              hintStyle: const TextStyle(
                color: Color(0xFF909076), // ✅ hint color here
              ),
              fillColor: const Color(0xFF41402C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), // adjust radius here
                borderSide: BorderSide.none, // remove default border line
              ),
            ),

          ),
        ],
      ),
    );
  }
}
