import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const RegistrationScreen());
}

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stitch Design',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF232310),
        fontFamily: 'SpaceGrotesk',
      ),
      home: const CreateAccountScreen(),
    );
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

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final carModelController = TextEditingController();
  final carNumberController = TextEditingController();
  final carTypeController = TextEditingController();
  final licenseController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void showMessage(String msg, [Color color = Colors.red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final Map<String, dynamic> body = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "password": passwordController.text.trim(),
      "role": selectedRole.toLowerCase(),
    };

    if (selectedRole == 'Driver') {
      body.addAll({
        "carModel": carModelController.text.trim(),
        "carNumber": carNumberController.text.trim(),
        "carType": carTypeController.text.trim(),
        "licenseNumber": licenseController.text.trim(),
      });
    }

    final url = Uri.parse("https://sizemoretaxi.onrender.com/api/auth/register");

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        showMessage("Registration successful. OTP sent.", Colors.green);
        // Navigate or show OTP screen here
      } else {
        showMessage(data['message'] ?? "Registration failed");
      }
    } catch (e) {
      showMessage("Network error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget inputField(String label, TextEditingController controller,
      {bool obscureText = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1)),
          const SizedBox(height: 17),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            validator: (val) {
              if (required && (val == null || val.trim().isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: const TextStyle(color: Color(0xFFcbcb90)),
              filled: true,
              fillColor: const Color(0xFF494922),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                inputField("Phone Number", phoneController),

                if (selectedRole == 'Driver') ...[
                  inputField("Car Model", carModelController),
                  inputField("Car Number", carNumberController),
                  inputField("Car Type", carTypeController),
                  inputField("License Number", licenseController),
                ],

                inputField("Password", passwordController, obscureText: true),

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
                      onPressed: isLoading ? null : register,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
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
        color: const Color(0xFF494A22),
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
