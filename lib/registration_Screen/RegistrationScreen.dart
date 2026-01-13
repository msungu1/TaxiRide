import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Add this line

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateAccountScreen();
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  String selectedRole = 'Passenger';
  bool isLoading = false;
  bool acceptedTerms = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final carModelController = TextEditingController();
  final carNumberController = TextEditingController();
  final carTypeController = TextEditingController();
  final licenseController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nationalIdController = TextEditingController();

  void showMessage(String msg, [Color color = Colors.red]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }


  Map<String, dynamic> createRequestBody() {
    final body = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim().toLowerCase(),
      "phone": phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
      "password": passwordController.text.trim(),
      "role": selectedRole == 'Passenger' ? 'rider' : 'driver',
    };
    if (selectedRole == 'Driver') {
      body.addAll({
        "nationalId": nationalIdController.text.trim(),
        "carModel": carModelController.text.trim(),
        "carNumber": carNumberController.text.trim(),
        "carType": carTypeController.text.trim(),
        "licenseNumber": licenseController.text.trim(),
      });
    }
    return body;
  }

// 1. Simplified Single API Call
// 1. Single API Call that waits for Render to wake up
  Future<void> _makeSingleApiCall(Map<String, dynamic> body) async {
    final url = Uri.parse("https://sizemoretaxi.onrender.com/api/auth/register");

    // Create a persistent client to prevent connection drops during Render spin-up
    final client = http.Client();

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Explicitly ask for JSON
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      // Check for both 200 (OK) and 201 (Created)
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;

        showMessage("Registration successful. OTP sent.", Colors.green);

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushNamed(
          context,
          '/login',
          arguments: {
            'email': emailController.text.trim(),
            'role': selectedRole == 'Passenger' ? 'rider' : 'driver',
          },
        );
      } else {
        // If the user already exists, the server SHOULD return 400 or 409
        final errorMessage = responseData['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // If it fails because the user was created "long ago" in a previous hang,
      // the error message from the server will likely be "User already exists".
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    } finally {
      client.close(); // Always close the client
    }
  }

  // 2. Updated Register Function
  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!acceptedTerms) {
      showMessage("Please accept terms and conditions");
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showMessage("Passwords don't match");
      return;
    }

    setState(() => isLoading = true);

    try {
      final body = createRequestBody();
      // This will now wait until the server responds
      await _makeSingleApiCall(body);
    } catch (e) {
      // Clear passwords on error so user can re-try safely
      passwordController.clear();
      confirmPasswordController.clear();
      showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      // Only stop loading if we are still on this screen
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define our new theme colors locally for easy editing
    const primaryCyan = Color(0xFF22D3EE);
    const deepBackground = Color(0xFF0F172A);
    const surfaceSlate = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: deepBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Header Section
                Text(
                  'Create Account',
                  style: GoogleFonts.spaceGrotesk( // Using a modern tech font if available
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the future of taxi services',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),

                const SizedBox(height: 30),

                // Logo with a subtle glow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryCyan.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Image.asset('assets/images/logo.png', height: 90),
                ),

                const SizedBox(height: 30),

                // Role Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: RoleSelector(
                    selectedRole: selectedRole,
                    onRoleChanged: (role) => setState(() => selectedRole = role),
                    // Note: Ensure your RoleSelector widget uses the new primaryCyan
                    // for its selected state background!
                  ),
                ),

                const SizedBox(height: 10),

                // Form Input Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      inputField("Full Name", nameController, icon: Icons.person_outline),
                      inputField("Email Address", emailController, icon: Icons.email_outlined),
                      inputField(
                        "Phone Number",
                        phoneController,
                        icon: Icons.phone_android_outlined,
                        helperText: "Format: 07xxxxxxxx",
                      ),

                      if (selectedRole == 'Driver') ...[
                        inputField("Car Model", carModelController, icon: Icons.directions_car_filled_outlined),
                        inputField("Car Number", carNumberController, icon: Icons.numbers_outlined),
                        inputField("Car Type", carTypeController, icon: Icons.category_outlined),
                        inputField("License Number", licenseController, icon: Icons.badge_outlined),
                      ],

                      inputField(
                        "National ID",
                        nationalIdController,
                        icon: Icons.assignment_ind_outlined,
                      ),

                      inputField(
                        "Password",
                        passwordController,
                        obscureText: obscurePassword,
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: primaryCyan.withOpacity(0.7),
                            size: 20,
                          ),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),

                      inputField(
                        "Confirm Password",
                        confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        icon: Icons.lock_reset_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: primaryCyan.withOpacity(0.7),
                            size: 20,
                          ),
                          onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                      ),
                    ],
                  ),
                ),

                // Terms and Conditions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Theme(
                        data: ThemeData(unselectedWidgetColor: Colors.white24),
                        child: Checkbox(
                          value: acceptedTerms,
                          activeColor: primaryCyan,
                          checkColor: deepBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: const TextStyle(
                                  color: primaryCyan,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.pushNamed(context, '/termsandcondition'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Submit Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [primaryCyan, primaryCyan.withBlue(255)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryCyan.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isLoading ? null : () => register(),
                      child: isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: deepBackground, strokeWidth: 2.5),
                      )
                          : const Text(
                        'GET STARTED',
                        style: TextStyle(
                          color: deepBackground,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
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


  Widget inputField(
      String label,
      TextEditingController controller, {
        bool obscureText = false,
        String? helperText,
        Widget? suffixIcon,
        IconData? icon, // New parameter for icons
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "  $label",
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF22D3EE).withOpacity(0.5), size: 20) : null,
              hintText: 'Your $label',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              helperText: helperText,
              helperStyle: const TextStyle(color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }


}

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // color: const Color(0xFF494A22),
        color: const Color(0xFFFFD700), //////////////////////////

        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: ['Passenger', 'Driver'].map((role) {
          final isSelected = selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => onRoleChanged(role),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF232310)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: Text(
                  role,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFcbcb90),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}