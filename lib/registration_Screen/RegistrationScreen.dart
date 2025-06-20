import 'dart:async';
import 'package:flutter/material.dart';

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

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // Added scroll support
          child: Column(
            children: [
              // Header with Back Arrow and Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 24), // Balancing space
                  ],
                ),
              ),

              // Logo Image
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Container(
                  width: double.infinity,
                  height: 130,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Input Fields
              const InputField(label: 'Name', hint: 'Enter your name'),
              const InputField(label: 'Email', hint: 'Enter your email'),
              const InputField(label: 'Phone Number', hint: 'Enter your phone number'),
              const InputField(label: 'Car Model', hint: 'e.g. Toyota Premio'),
              const InputField(label: 'Car Number', hint: 'e.g. KDB 123A'),
              const InputField(label: 'Car Type', hint: 'e.g. Sedan, SUV, etc'),
              const InputField(label: 'License Number', hint: 'Driver’s license number'),
              const InputField(label: 'Password', hint: 'Enter your password', obscureText: true),

              // Role Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFF494A22),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const RoleSelector(),
                ),
              ),

              // Create Button
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
                    onPressed: () {},
                    child: const Text(
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

              // Bottom Spacer
              Container(height: 20, color: const Color(0xFF232310)),
            ],
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
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
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
                height: 1,

              )

          ),
          const SizedBox(height: 17),
          TextField(
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFcbcb90)),
              filled: true,
              fillColor: const Color(0xFF494922),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
}

class RoleSelector extends StatefulWidget {
  const RoleSelector({super.key});

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector> {
  String _selectedRole = 'Passenger';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['Passenger', 'Driver'].map((role) {
        final selected = _selectedRole == role;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF232310) : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  )
                ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                role,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFcbcb90),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
