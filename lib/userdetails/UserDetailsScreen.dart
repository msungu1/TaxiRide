import 'package:flutter/material.dart';
import '../usermodel/UserModel.dart'; // Update path as needed
import '../adminapiservice/admin_api_service.dart'; // Update path as needed

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final passwordController = TextEditingController();
    final carNumberController = TextEditingController();
    final carTypeController = TextEditingController();
    final carModelController = TextEditingController();

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 64,
              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? NetworkImage(user.photoUrl!)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(color: Color(0xFFbbb8a0))),
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
            _buildInputField('Name', inputDecoration, controller: nameController),
            _buildInputField('Email', inputDecoration, controller: emailController),
            _buildInputField('Phone Number', inputDecoration, controller: phoneController),
            _buildInputField('Password', inputDecoration, controller: passwordController, obscureText: true),
            _buildInputField('Car Number', inputDecoration, controller: carNumberController),
            _buildInputField('Car Type', inputDecoration, controller: carTypeController),
            _buildInputField('Car Model', inputDecoration, controller: carModelController),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFF00),
                  foregroundColor: const Color(0xFF1e1d15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () async {
                  try {
                    final updatedData = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'phone': phoneController.text,
                      if (passwordController.text.isNotEmpty) 'password': passwordController.text,
                      'carNumber': carNumberController.text,
                      'carType': carTypeController.text,
                      'carModel': carModelController.text,
                    };

                    await AdminApiService.updateUser(user.id, updatedData);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User updated successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update user: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, InputDecoration decoration,
      {bool obscureText = false, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: decoration.copyWith(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
        ),
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
