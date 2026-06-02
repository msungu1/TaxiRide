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
  bool _isPasswordVisible = false;
  bool _startAnimation = false;


  @override
  void initState() {
    super.initState();
    // Start the animation slightly after the page loads
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _startAnimation = true);
    });
  }
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


  Future<void> loginUser() async {
    final identifier = phoneController.text.trim();
    final password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);
    final url = Uri.parse('https://sizemoretaxi-itpj.onrender.com/api/auth/login');

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

        // ✅ STEP 1: Check Verification Status (UNCOMMENTED)
        // Note: Using 'isEmailVerified' to match your backend model
        // final bool isVerified = user['isEmailVerified'] ?? false;
        //
        // if (!isVerified) {
        //   if (!mounted) return;
        //   showMessage("Please verify your account", Colors.orange);
        //
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => OtpVerificationScreen(
        //         userId: userId,
        //         role: user['role'] ?? 'rider',
        //         email: user['email'] ?? '',
        //       ),
        //     ),
        //   );
        //   return;
        // }


        // ✅ STEP 2: Normal Login flow (Proceeds if isEmailVerified is true)
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
        // This handles the 401 error if the backend blocks unverified users
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
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1F1F15),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0), // Old UI Padding
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),
// // The sliding and fading header
//                 AnimatedPadding(
//                   duration: const Duration(milliseconds: 1000),
//                   curve: Curves.easeOutQuart,
//                   padding: EdgeInsets.only(top: _startAnimation ? 40 : 80), // Slides up
//                   child: AnimatedOpacity(
//                     duration: const Duration(milliseconds: 1000),
//                     opacity: _startAnimation ? 1.0 : 0.0, // Fades in
//                     child: Column(
//                       children: [
//                         Text(
//                           'Welcome Back To',
//                           style: GoogleFonts.inter(
//                             color: Colors.white.withOpacity(0.7),
//                             fontSize: 16,
//                             fontWeight: FontWeight.w300,
//                             letterSpacing: 2.0,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Column(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(15),
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: const Color(0xFFFBC02D).withOpacity(0.1),
//                                 border: Border.all(
//                                     color: const Color(0xFFFBC02D).withOpacity(0.3),
//                                     width: 1),
//                               ),
//                               child: const Icon(
//                                 Icons.local_taxi_rounded,
//                                 size: 50,
//                                 color: Color(0xFFFBC02D),
//                               ),
//                             ),
//                             const SizedBox(height: 15),
//                             Text(
//                               'SIZEMORETAXI',
//                               style: GoogleFonts.montserrat(
//                                 color: Colors.white,
//                                 fontSize: 26,
//                                 fontWeight: FontWeight.w900,
//                                 letterSpacing: 5.0,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Container(
//                               height: 3,
//                               width: 30,
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFFBC02D),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 40),
//                 buildInput("Phone or Email", phoneController, false),
//                 buildInput("Password", passwordController, true),
//                 const SizedBox(height: 24),
//
//                 ElevatedButton(
//                   onPressed: isLoading ? null : loginUser,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFFFD700),
//                     foregroundColor: Colors.black,
//                     elevation: 8,
//                     shadowColor: const Color(0xFFFFD700).withOpacity(0.5), // Yellow glow
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ), // Old UI rounded style
//                     minimumSize: const Size(double.infinity, 56),
//                   ),
//                   child: isLoading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.black,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Text(
//                           'Login',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                 ),
//
//
//
//                 const SizedBox(height: 10),
//                 TextButton(
//                   onPressed: () => Navigator.pushNamed(context, '/forgot'),
//                   child: const Text(
//                     'Forgot Password?',
//                     style: TextStyle(color: Color(0xFFbebe0d), fontSize: 18),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.pushNamed(context, '/register'),
//                   child: const Text(
//                     'Sign Up',
//                     style: TextStyle(color: Color(0xFFbebe0d), fontSize: 18),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

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
                // The sliding and fading header
                AnimatedPadding(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutQuart,
                  padding: EdgeInsets.only(top: _startAnimation ? 40 : 80),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1000),
                    opacity: _startAnimation ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        Text(
                          'Welcome Back To',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            // ✅ NEW: Circular Logo with Teal Background
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF008080), // Teal background from reference
                                border: Border.all(
                                  color: const Color(0xFFFBC02D).withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF008080).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Padding(
                                  padding: const EdgeInsets.all(15), // Padding for the logo asset
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.domain_rounded,
                                      size: 40,
                                      color: Color(0xFFFBC02D),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'SIZEMORETAXI',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 5.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 3,
                              width: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBC02D),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                buildInput("Phone or Email", phoneController, false),
                buildInput("Password", passwordController, true),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    elevation: 8,
                    shadowColor: const Color(0xFFFFD700).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 56),
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
            obscureText: isPassword ? !_isPasswordVisible : false,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: const TextStyle(color: Color(0xFF909076)),
              fillColor: const Color(0xFF41402C), // Old UI input color
              filled: true,
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFFBC02D),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
                  : null,
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
