// ✅ Import necessary tools (like puzzle pieces for the app to work)
import 'dart:convert'; // For handling text/data conversions
import 'package:flutter/material.dart'; // Flutter's built-in tools
import 'package:http/http.dart' as http; // For making internet requests
import 'package:google_fonts/google_fonts.dart'; // For custom fonts
import 'package:shared_preferences/shared_preferences.dart'; // For saving small data locally (like memory)

// ✅ Provider (state management)
import 'package:provider/provider.dart'; // For sharing data across the app
import 'package:sizemore_taxi/UserProvider/UserProvider.dart'; // ✅ Our custom user provider

// ✅ Screens
import 'package:sizemore_taxi/ProfileScreen/ProfileScreen.dart'; // Profile screen
import 'package:sizemore_taxi/DriverProfile/DriverProfileScreen.dart';

// ✅ Services
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';

/// 🚖 LOGIN SCREEN - Where users sign in
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// 📱 Controllers for phone/email and password input fields
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // 👈 Tracks if login is in progress (shows spinner)

  /// 🔐 LOGIN FUNCTION - Sends data to server and handles response
  Future<void> loginUser() async {
    // ✅ Access user data manager (shared across the app)
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    /// Get what user typed (trim removes extra spaces)
    final identifier = phoneController.text.trim();
    final password = passwordController.text;

    /// ❌ Show error if fields are empty
    if (identifier.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    setState(() => isLoading = true); // Show loading spinner

    /// 🌐 Server URL for login
    final url = Uri.parse('https://sizemoretaxi.onrender.com/api/auth/login');

    try {
      // 📤 Send login request to server
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // Tell server we're sending JSON
        body: jsonEncode({
          "identifier": identifier,
          "password": password,
        }),
      );

      /// 📥 Decode server response
      final data = jsonDecode(res.body);
      print('Full response body: ${res.body}'); // Debugging

      /// ✅ Successful login
      if (res.statusCode == 200 && data['data'] != null) {
        final user = data['data']['user']; // 👤 User details from server
        final token = data['data']['accessToken']; // 🔑 Security key

        print('User from response: $user');
        print('Token: $token');

        /// ❌ Safety checks
        if (user == null) {
          showMessage("Invalid response: missing user");
          return;
        }
        if (token == null) {
          showMessage("Invalid response: missing token");
          return;
        }

        // ✅ Save user globally in the app
        userProvider.setUser({
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'phone': user['phone'],
          'role': user['role'],
        });

        // ✅ Save token securely
        await AdminApiService.saveToken(token);

        // 👤 Check user role (admin/driver/passenger)
        String role = (user['role'] ?? '').toString().trim().toLowerCase();
        print("🔐 Logging in with role: '$role'");

        /// 🗝️ Redirect based on role
        if (role == 'admin') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user['id']);
          await prefs.setString('role', role);
          await prefs.setString('email', user['email'] ?? '');

          Navigator.pushReplacementNamed(
            context,
            '/adminuser',
            arguments: {
              'email': user['email'] ?? '',
              'role': role,
            },
          );
        } else if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driverscreen', arguments: {
            'email': user['email'] ?? '',
            'role': role,
          });
        }
        else if (role == 'passenger' || role == 'rider' || role == 'user') {
          // ✅ Save passenger details locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user['id'].toString());
          await prefs.setString('name', user['name'] ?? '');
          await prefs.setString('email', user['email'] ?? '');
          await prefs.setString('phone', user['phone'] ?? '');
          await prefs.setString('role', role);

          // If backend sends profile picture:
          if (user['profilePic'] != null) {
            await prefs.setString('profilePic', user['profilePic']);
          }else {
            // fallback avatar image URL
            await prefs.setString(
              'profilePic',
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user['name'] ?? 'User')}&background=0D8ABC&color=fff',
            );
          }
          // ✅ Go to profile screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          /// ❌ Unknown role
          print("🚫 Unknown role detected: '$role'");
          showMessage("Unknown role: access denied.");
        }
      } else {
        // ❌ Login failed
        showMessage(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      /// 🌐 Network/server error
      print("Login error: $e");
      showMessage("Error: $e");
    } finally {
      setState(() => isLoading = false); // Hide loading spinner
    }
  }

  /// 🛑 Helper to show error messages
  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  /// 🎨 BUILD THE LOGIN SCREEN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F15),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back To',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Image.asset('assets/images/logo.png', height: 160),
                const SizedBox(height: 16),

                /// 📱 Phone/Email input field
                buildInput("Phone or Email", phoneController, false),

                /// 🔒 Password input field
                buildInput("Password", passwordController, true),

                const SizedBox(height: 24),

                /// 🟡 LOGIN BUTTON
                ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 16),

                /// 🔗 Forgot password link
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot');
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFFbebe0d),
                      fontSize: 20,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                /// 🔗 Sign up link
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFFbebe0d),
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🛠️ HELPER: Builds a styled input field
  Widget buildInput(String label, TextEditingController controller, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
