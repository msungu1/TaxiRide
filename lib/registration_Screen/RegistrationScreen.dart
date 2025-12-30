import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http.head(
        Uri.parse('https://sizemoretaxi.onrender.com/api/auth/register'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
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

  Future<void> _makeApiCallWithRetry(Map<String, dynamic> body) async {
    const maxRetries = 2;
    const initialTimeout = Duration(seconds: 15);
    const retryDelay = Duration(seconds: 3);
    final url = Uri.parse("https://sizemoretaxi.onrender.com/api/auth/register");

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
            .timeout(initialTimeout);

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          showMessage("Registration successful. OTP sent.", Colors.green);
          Navigator.pushNamed(context, '/login', arguments: {
            'email': emailController.text.trim(),
            'role': selectedRole == 'Passenger' ? 'rider' : 'driver',
          });
        } else {
          final errorMessage =
              responseData['message'] ?? 'Registration failed (${response.statusCode})';
          throw Exception(errorMessage);
        }
      } on TimeoutException {
        if (attempt == maxRetries - 1) {
          throw Exception("Server is taking too long to respond. Try again later.");
        }
        await Future.delayed(retryDelay);
      } on http.ClientException catch (e) {
        throw Exception("Connection error: ${e.message}");
      } catch (e) {
        rethrow;
      }
    }
  }

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
      if (!(await checkConnection())) {
        showMessage("No internet connection or server unavailable");
        return;
      }

      final body = createRequestBody();
      await _makeApiCallWithRetry(body);
    } catch (e) {
      passwordController.clear();
      confirmPasswordController.clear();
      showMessage(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF282614),

      /////////////////////
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Create Account',
                  style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Image.asset('assets/images/logo.png', height: 100),
                inputField("Name", nameController),
                inputField("Email", emailController),
                inputField("Phone Number", phoneController,
                    helperText: "Enter digits only (e.g., 0712345678)"),
                if (selectedRole == 'Driver') ...[
                  inputField("Car Model", carModelController),
                  inputField("Car Number", carNumberController),
                  inputField("Car Type", carTypeController),
                  inputField("License Number", licenseController),
                ],
                inputField("National ID", nationalIdController,
                    helperText: "Your Kenyan national ID number"),
                inputField("Password", passwordController,  ///////////////////

                    obscureText: obscurePassword,
                    // helperText: "Minimum 8 characters",
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey),
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                    )),
                inputField("Confirm Password", confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey),
                      onPressed: () =>
                          setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                    )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: acceptedTerms,
                        onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) => acceptedTerms ? const Color(0xFFedee0a) : Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: const TextStyle(color: Colors.white),
                            children: [
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: const TextStyle(
                                  color: Color(0xFFedee0a),
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(context, '/termsandcondition');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: RoleSelector(
                    selectedRole: selectedRole,
                    onRoleChanged: (role) => setState(() => selectedRole = role),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 49,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFedee0a),
                        foregroundColor: const Color(0xFF232310),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: isLoading ? null : () => register(),
                      child: isLoading
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          ),
                          SizedBox(width: 10),
                          Text("Creating Account...")
                        ],
                      )
                          : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 16,
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
        bool required = true,
        String? helperText,
        Widget? suffixIcon,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1)),
          const SizedBox(height: 8),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                helperText,
                style: const TextStyle(color: Color(0xFFcbcb90), fontSize: 12),
              ),
            ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            keyboardType: label == "Phone Number" || label == "National ID"
                ? TextInputType.number
                : TextInputType.text,
            validator: (val) {
              if (required && (val == null || val.trim().isEmpty)) {
                return 'This field is required';
              }
              if (label == "Email" && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val!)) {
                return 'Enter a valid email address';
              }
              if (label == "Phone Number") {
                final phone = val!.trim().replaceAll(RegExp(r'[^0-9]'), '');
                if (phone.length < 10) return 'Enter a valid phone number';
              }
              if (label == "National ID") {
                final id = val!.trim();
                if (!RegExp(r'^\d{7,9}$').hasMatch(id)) {
                  return 'Enter a valid 8-digit ID number(7-9 digits)';
                }
              }
              if (label == "Password" && val!.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: const TextStyle(color: Color(0xFFcbcb90)),
              filled: true,
              fillColor: const Color(0xFF494922),  /////////////////////

              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
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
          color: const Color(0xFFFFD700),  //////////////////////////

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
                  color: isSelected ? const Color(0xFF232310) : Colors.transparent,
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
