import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizemore_taxi/emergency/EmergencyContactScreen.dart'; // 👈 import your EmergencyContactScreen

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // Your FAQs list
  final List<Map<String, String>> faqs = const [
    {
      "q": "How do I book a ride?",
      "a": "Open the app, enter your destination, choose a driver, and confirm."
    },
    {
      "q": "How can I cancel a ride?",
      "a": "Go to 'My Rides', select the ride, and tap 'Cancel'."
    },
    {
      "q": "What payment methods are accepted?",
      "a": "We accept M-Pesa, cash, and debit/credit cards."
    },
  ];

  // Phone launcher
  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+254700000000'); // replace with your number
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // Email launcher
  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@sizemoretaxi.com', // replace with your support email
      query: 'subject=App Support&body=Hello, I need help with...',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  // WhatsApp launcher
  void _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse("https://wa.me/254700000000?text=Hello%20Support"); // replace with WhatsApp number
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Generate FAQ ExpansionTiles from the list
          ...faqs.map((faq) => ExpansionTile(
            title: Text(faq["q"] ?? ""),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(faq["a"] ?? ""),
              ),
            ],
          )),

          const SizedBox(height: 20),
          const Text(
            "Contact Us",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text("Call Support"),
            onTap: _launchPhone,
          ),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.redAccent),
            title: const Text("Email Support"),
            onTap: _launchEmail,
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.teal),
            title: const Text("WhatsApp Support"),
            onTap: _launchWhatsApp,
          ),

          const SizedBox(height: 40),

          // 🚨 Emergency Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.warning, color: Colors.white),
            label: const Text(
              "Emergency",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencyContactScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
