import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// ✅ Imports
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/ProfileScreen/ProfileScreen.dart';
import 'package:sizemore_taxi/DriverProfile/DriverProfileScreen.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginUser() async {
    final identifier = phoneController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('https://sizemoretaxi.onrender.com/api/auth/login');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "identifier": identifier,
          "password": password,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['data'] != null) {
        final user = data['data']['user'];
        final token = data['data']['accessToken'];

        if (user == null || token == null) {
          showMessage("Invalid response from server");
          return;
        }

        // ✅ IMPORTANT: Use data['data']['user']['_id'] because MongoDB uses underscores
        final String userId = user['_id'] ?? user['id'] ?? '';
        final String role = (user['role'] ?? '').toString().trim().toLowerCase();

        // ✅ Save to UserProvider (State Management)
        if (!mounted) return;
        Provider.of<UserProvider>(context, listen: false).setUser({
          'id': userId,
          'name': user['name'] ?? '',
          'email': user['email'] ?? '',
          'phone': user['phone'] ?? '',
          'role': role,
        });

        // ✅ Save token securely
        await AdminApiService.saveToken(token);

        // ✅ Save to SharedPreferences (Persistence)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('role', role);
        await prefs.setString('name', user['name'] ?? '');
        await prefs.setString('email', user['email'] ?? '');

        if (!mounted) return;

        /// 🗝️ Role-Based Navigation
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/adminuser', arguments: {
            'email': user['email'] ?? '',
            'role': role,
          });
        } else if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driverscreen', arguments: {
            'email': user['email'] ?? '',
            'role': role,
          });
        } else if (role == 'passenger' || role == 'rider' || role == 'user') {
          // Set profile pic for passenger
          String profilePic = user['profilePic'] ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user['name'] ?? 'User')}&background=FFD700&color=000';
          await prefs.setString('profilePic', profilePic);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          showMessage("Role '$role' not recognized. Please contact support.");
        }
      } else {
        showMessage(data['message'] ?? 'Login failed. Please check credentials.');
      }
    } catch (e) {
      print("Login error: $e");
      showMessage("Connection error. Is the server running?");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ... (buildInput and build method remain exactly as they were in your UI)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F15),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('Welcome Back To', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Image.asset('assets/images/logo.png', height: 160),
                const SizedBox(height: 16),
                buildInput("Phone or Email", phoneController, false),
                buildInput("Password", passwordController, true),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
                // ... (links omitted for brevity, stay the same)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/forgot'),
                  child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFbebe0d), fontSize: 18)),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Sign Up', style: TextStyle(color: Color(0xFFbebe0d), fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInput(String label, TextEditingController controller, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: const TextStyle(color: Color(0xFF909076)),
              fillColor: const Color(0xFF41402C),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}