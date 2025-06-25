import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;
  int resendCountdown = 0;
  Timer? countdownTimer;

  void sendOTP() {
    final identifier = identifierController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email or phone number")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Simulate sending OTP via API
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
        otpSent = true;
        resendCountdown = 30;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent to $identifier")),
      );

      startCountdown();
    });
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          resendCountdown--;
        });
      }
    });
  }

  void resetPassword() {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both password fields")),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Simulate reset
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successful")),
      );

      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    identifierController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Forgot Password", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reset your password",
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Enter your phone number or email to receive an OTP.",
              style: GoogleFonts.notoSans(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text("Phone or Email", style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: identifierController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 07... or email@example.com',
                hintStyle: const TextStyle(color: Color(0xFF909076)),
                fillColor: const Color(0xFF41402C),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : sendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Send OTP", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            if (otpSent)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: resendCountdown > 0 ? null : sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: resendCountdown > 0
                        ? const Color(0xFF8f8c2a) // dimmed yellow when disabled
                        : const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text(
                    resendCountdown > 0
                        ? "Resend OTP in $resendCountdown sec"
                        : "Resend OTP",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (otpSent) ...[
              const SizedBox(height: 30),
              Text("New Password", style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  hintStyle: const TextStyle(color: Color(0xFF909076)),
                  fillColor: const Color(0xFF41402C),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Confirm Password", style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Re-enter new password',
                  hintStyle: const TextStyle(color: Color(0xFF909076)),
                  fillColor: const Color(0xFF41402C),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("Reset Password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
