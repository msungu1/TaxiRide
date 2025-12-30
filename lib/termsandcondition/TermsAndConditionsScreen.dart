import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232310),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232310),
        elevation: 0,
        title: const Text("Terms and Conditions"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: TermsContent(),
        ),
      ),
    );
  }
}

class TermsContent extends StatelessWidget {
  const TermsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("1. Introduction", style: sectionTitleStyle),
        Text(
          "Welcome to Sizemore Taxi! By using our services, you agree to these Terms and Conditions. Please read them carefully.",
          style: textStyle,
        ),
        gap(),

        Text("2. User Responsibilities", style: sectionTitleStyle),
        Text(
          "You agree to use the app lawfully and not for any fraudulent activities. You must provide accurate information during registration.",
          style: textStyle,
        ),
        gap(),

        Text("3. Driver Responsibilities", style: sectionTitleStyle),
        Text(
          "Drivers must possess valid licenses, maintain vehicle hygiene, and comply with local transport laws.",
          style: textStyle,
        ),
        gap(),

        Text("4. Payments & Charges", style: sectionTitleStyle),
        Text(
          "All fares are calculated based on distance, time, and demand. Payment must be made via approved channels.",
          style: textStyle,
        ),
        gap(),

        Text("5. Cancellations & Refunds", style: sectionTitleStyle),
        Text(
          "Cancellations may be subject to a fee. Refunds are processed based on company policies.",
          style: textStyle,
        ),
        gap(),

        Text("6. Safety & Conduct", style: sectionTitleStyle),
        Text(
          "We prioritize safety. Misconduct, abuse, or violation of rules may result in account suspension or termination.",
          style: textStyle,
        ),
        gap(),

        Text("7. Data Privacy", style: sectionTitleStyle),
        Text(
          "We respect your privacy. Your data is stored securely and used only for service-related purposes.",
          style: textStyle,
        ),
        gap(),

        Text("8. Limitation of Liability", style: sectionTitleStyle),
        Text(
          "Sizemore Taxi is not liable for delays, accidents, or losses incurred during rides. Use the service at your own risk.",
          style: textStyle,
        ),
        gap(),

        Text("9. Contact Us", style: sectionTitleStyle),
        Text(
          "If you have any questions or concerns, contact our support team at support@sizemoretaxi.com.",
          style: textStyle,
        ),
        gap(height: 32),
        Center(
          child: Text(
            "© 2025 Sizemore Taxi. All rights reserved.",
            style: textStyle.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }

  SizedBox gap({double height = 16}) => SizedBox(height: height);

  TextStyle get sectionTitleStyle => const TextStyle(
    color: Color(0xFFedee0a),
    fontWeight: FontWeight.bold,
    fontSize: 16,
    height: 2,
  );
}
