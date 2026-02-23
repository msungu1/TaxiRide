import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

// ✅ Logic & Service Imports
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/ProfileScreen/ProfileScreen.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:sizemore_taxi/otpverification/OtpVerificationScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  /// Logic: Helper to get current location for socket initialization
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint("Error fetching location: $e");
      return null;
    }
  }

  /// Logic: The updated login flow with Socket Init
  // Future<void> loginUser() async {
  //   final identifier = phoneController.text.trim();
  //   final password = passwordController.text;
  //
  //   if (identifier.isEmpty || password.isEmpty) {
  //     showMessage("Please fill all fields");
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   final url = Uri.parse('https://sizemoretaxi.onrender.com/api/auth/login');
  //
  //   try {
  //     final res = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({"identifier": identifier, "password": password}),
  //     );
  //
  //     final data = jsonDecode(res.body);
  //
  //     if (res.statusCode == 200 && data['data'] != null) {
  //       final user = data['data']['user'];
  //       final token = data['data']['accessToken'];
  //
  //       final String userId = (user['_id'] ?? user['id'] ?? '').toString();
  //       final String rawRole = (user['role'] ?? '')
  //           .toString()
  //           .trim()
  //           .toLowerCase();
  //
  //       // Normalize role
  //       String role = rawRole;
  //       if (rawRole == 'passenger' || rawRole == 'user') role = 'rider';
  //
  //       // 1. Save to Provider (State Management)
  //       if (!mounted) return;
  //       Provider.of<UserProvider>(context, listen: false).setUser({
  //         'id': userId,
  //         'name': user['name'] ?? '',
  //         'email': user['email'] ?? '',
  //         'phone': user['phone'] ?? '',
  //         'role': role,
  //       });
  //
  //       // 2. Save Locally (Persistence)
  //       await AdminApiService.saveToken(token);
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('token', token);
  //       await prefs.setString('userId', userId);
  //       await prefs.setString('role', role);
  //       await prefs.setString('name', user['name'] ?? '');
  //
  //       // 3. ---------------- SOCKET INIT (Latest Logic) ----------------
  //       Position? pos = await _getCurrentLocation();
  //       SocketService.instance.disconnect();
  //       debugPrint("🔌 Initializing socket for $role: $userId");
  //       SocketService.instance.init(
  //         userId: userId,
  //         lat: pos?.latitude ?? -1.2633,
  //         lng: pos?.longitude ?? 36.8087,
  //         role: role == 'driver' ? 'driver' : 'rider',
  //       );
  //
  //       // 4. Role-Based Navigation
  //       if (!mounted) return;
  //
  //       if (role == 'admin') {
  //         Navigator.pushReplacementNamed(context, '/adminuser');
  //       } else if (role == 'driver') {
  //         Navigator.pushReplacementNamed(context, '/driverscreen');
  //       } else if (role == 'rider') {
  //         String profilePic =
  //             user['profilePic'] ??
  //             'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user['name'] ?? 'User')}&background=FFD700&color=000';
  //         await prefs.setString('profilePic', profilePic);
  //         Navigator.pushReplacementNamed(context, '/rider');
  //       }
  //     } else {
  //       showMessage(data['message'] ?? 'Login failed.');
  //     }
  //   } catch (e) {
  //     debugPrint("Login error: $e");
  //     showMessage("Connection error. Please try again.");
  //   } finally {
  //     if (mounted) setState(() => isLoading = false);
  //   }
  // }
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
        body: jsonEncode({"identifier": identifier, "password": password}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['data'] != null) {
        final user = data['data']['user'];
        final String userId = (user['_id'] ?? user['id'] ?? '').toString();

        // ✅ STEP 1: Check Verification Status
        // If the backend returns isVerified as false, go to OTP screen
        final bool isVerified = user['isVerified'] ?? false;

        if (!isVerified) {
          if (!mounted) return;
          showMessage("Please verify your account", Colors.orange);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                userId: userId,           // Pass as named argument
                role: user['role'] ?? 'rider',
                email: user['email'],      // Pass as named argument
              ),
            ),
          );
          return;
        }

        // ✅ STEP 2: Normal Login flow (Only if verified)
        final token = data['data']['accessToken'];
        final String rawRole = (user['role'] ?? '').toString().trim().toLowerCase();
        String role = rawRole == 'passenger' || rawRole == 'user' ? 'rider' : rawRole;

        if (!mounted) return;
        Provider.of<UserProvider>(context, listen: false).setUser({
          'id': userId,
          'name': user['name'] ?? '',
          'email': user['email'] ?? '',
          'phone': user['phone'] ?? '',
          'role': role,
        });

        await AdminApiService.saveToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);
        await prefs.setString('role', role);
        await prefs.setString('name', user['name'] ?? '');

        Position? pos = await _getCurrentLocation();
        SocketService.instance.disconnect();
        SocketService.instance.init(
          userId: userId,
          lat: pos?.latitude ?? -1.2633,
          lng: pos?.longitude ?? 36.8087,
          role: role == 'driver' ? 'driver' : 'rider',
        );

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/adminuser');
        } else if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driverscreen');
        } else {
          String profilePic = user['profilePic'] ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user['name'] ?? 'User')}';
          await prefs.setString('profilePic', profilePic);
          Navigator.pushReplacementNamed(context, '/rider');
        }
      } else {
        showMessage(data['message'] ?? 'Login failed.');
      }
    } catch (e) {
      showMessage("Connection error. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  void showMessage(String msg, [Color color = Colors.red]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F15),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Old UI Padding
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
                Image.asset(
                  'assets/images/logo.png',
                  height: 160,
                ), // Old UI Image Height
                const SizedBox(height: 16),
                buildInput("Phone or Email", phoneController, false),
                buildInput("Password", passwordController, true),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ), // Old UI rounded style
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/forgot'),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFFbebe0d), fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(color: Color(0xFFbebe0d), fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInput(
    String label,
    TextEditingController controller,
    bool isPassword,
  ) {
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
              fillColor: const Color(0xFF41402C), // Old UI input color
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
