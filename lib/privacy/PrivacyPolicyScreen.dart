import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            "Privacy Policy",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            "At Sizemore Taxi, we value your privacy. This policy explains how we collect, use, and protect your personal information.",
          ),
          SizedBox(height: 12),
          Text(
            "1. Information We Collect\n- Name, email, and phone number\n- Ride history and payment details\n- Location data when booking rides",
          ),
          SizedBox(height: 12),
          Text(
            "2. How We Use Your Data\n- To provide and improve our services\n- To process payments\n- To ensure safety and prevent fraud",
          ),
          SizedBox(height: 12),
          Text(
            "3. Data Sharing\nWe may share information with trusted third parties (e.g., payment processors, Google Maps) strictly for service delivery.",
          ),
          SizedBox(height: 12),
          Text(
            "4. Your Rights\nYou can request data deletion or correction anytime by contacting support@sizemoretaxi.com.",
          ),
          SizedBox(height: 12),
          Text(
            "5. Security\nWe use industry-standard security measures to protect your data.",
          ),
          SizedBox(height: 12),
          Text(
            "6. Contact Us\nIf you have any questions, please email us at support@sizemoretaxi.com.",
          ),
        ],
      ),
    );
  }
}
