import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtpVerificationScreen extends StatefulWidget {
  final String userId;
  final String role;
  final String? email;   // optional - for display
  final String? phone;   // optional - for display

  const OtpVerificationScreen({
    super.key,
    required this.userId,
    required this.role,
    this.email,
    this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  int resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendCountdown > 0) {
        setState(() => resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  void showMessage(String msg, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();

    // 1. Validation
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      showMessage("Please enter a valid 6-digit code");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. API Call
      final response = await http.post(
        Uri.parse("https://sizemoretaxi-itpj.onrender.com/api/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": widget.userId, // This must be the Database ID from Registration
          "otp": otp,
        }),
      ).timeout(const Duration(seconds: 30));

      final result = jsonDecode(response.body);

      // 3. Handle Success
      if (response.statusCode == 200) {
        showMessage("Verified successfully!", color: Colors.green);

        // Small delay so user can see the success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navigate to login and CLEAR the navigation stack
        // This prevents the user from going "back" to the OTP screen
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      // 4. Handle Error
      else {
        showMessage(result['message'] ?? "Invalid or expired OTP");
      }
    } on TimeoutException {
      showMessage("Server is taking too long. Please try again.");
    } catch (e) {
      showMessage("Connection error. Please check your internet.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (resendCountdown > 0) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://sizemoretaxi-itpj.onrender.com/api/auth/resend-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": widget.userId}),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMessage("New code sent successfully!", color: Colors.green);
        _startResendTimer();
      } else {
        showMessage(result['message'] ?? "Failed to resend code");
      }
    } catch (e) {
      showMessage("Network error. Please check your connection.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  String get _sentToText {
    if (widget.email != null && widget.email!.isNotEmpty) return widget.email!;
    if (widget.phone != null && widget.phone!.isNotEmpty) return widget.phone!;
    return "your registered email/phone";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232310),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232310),
        elevation: 0,
        title: const Text("Verify Your Account"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.verified_user_rounded,
                  size: 72, color: Color(0xFFedee0a)),
              const SizedBox(height: 24),
              const Text(
                "Enter 6-Digit Code",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We sent a code to $_sentToText",
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // OTP Input
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "------",
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 36),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFedee0a),
                    foregroundColor: const Color(0xFF232310),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF232310),
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    "VERIFY",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              TextButton(
                onPressed: (isLoading || resendCountdown > 0) ? null : _resendOtp,
                child: Text(
                  resendCountdown > 0
                      ? "Resend in ${resendCountdown}s"
                      : "Didn't receive code? Resend",
                  style: TextStyle(
                    color: resendCountdown > 0 ? Colors.grey : const Color(0xFFedee0a),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}