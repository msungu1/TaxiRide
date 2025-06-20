import 'package:flutter/material.dart';

class UserDetailsScreen extends StatelessWidget {
  const UserDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFF2d2b20),
      hintStyle: const TextStyle(color: Color(0xFFbbb8a0)),
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF5a563f)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF5a563f)),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1e1d15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e1d15),
        elevation: 0,
        title: const Text(
          'User Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 64,
              backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCVn37B9INz829-OkISbrXy9dCItVZcNlixLKf4HiWQ9imwuTmSzrW08us5jUmNTY9Bn-O_ZIx2ecjXH6L4kI1Y0Zt9dDLCOuZ3Vhot0RkeRkfYF0n1OCesDsotw3yjYD9xuuKZOkkgL1kpx1R3kxNpPHevojlfE7x0yag4GzJNj6JCQ23RIoim7kmZV9kTaJ5_YrCyoP3YyBnMamic7H4-rfI7STVPChHd-A_SNv2yqKoST3Xme3A5l6UaGCSZDpCCB4BPg5G17RzY',
              ),
            ),
            const SizedBox(height: 12),
            const Text('Allan', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('sizemoretaxi@email.com', style: TextStyle(color: Color(0xFFbbb8a0))),
            const Text('', style: TextStyle(color: Color(0xFFbbb8a0))),
            const SizedBox(height: 24),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: const [
                StatCard(label: 'Account Created', value: '01/15/2023'),
                StatCard(label: 'Total Ratings', value: '4.8 (120)'),
                StatCard(label: 'Total Trips', value: '500'),
                StatCard(label: 'Total Earnings', value: '\$10,000'),
              ],
            ),

            const SizedBox(height: 24),
            _buildInputField('Name', inputDecoration),
            _buildInputField('Email', inputDecoration),
            _buildInputField('Phone Number', inputDecoration),
            _buildInputField('Password', inputDecoration, obscureText: true),
            _buildInputField('Car Number', inputDecoration),
            _buildInputField('Car Type', inputDecoration),
            _buildInputField('Car Model', inputDecoration),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFF00), // Bright yellow
                  foregroundColor: const Color(0xFF1e1d15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () {},
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, InputDecoration decoration, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: decoration.copyWith(labelText: label, labelStyle: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;

  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5a563f)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
