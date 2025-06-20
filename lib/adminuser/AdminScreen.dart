import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2d2b20),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Bar at the top
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for a user',
                  hintStyle: const TextStyle(color: Color(0xFFbbb8a0)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFbbb8a0)),
                  filled: true,
                  fillColor: const Color(0xFF3f3d2c),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const Spacer(), // Your main content placeholder

            // Navigation Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF3f3d2c),
                    width: 1,
                  ),
                ),
                color: Color(0xFF2d2b20),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItemIcon(Icons.person, isActive: true),
                  _navItemIcon(Icons.directions_car),
                  _navItemIcon(Icons.location_on),
                  _navItemIcon(Icons.settings),
                ],
              ),
            ),

            Container(
              height: 20,
              color: const Color(0xFF2d2b20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String assetPath, {bool isActive = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            assetPath,
            width: 24,
            height: 24,
            color: isActive ? Colors.white : const Color(0xFFbbb8a0),
          ),
        ],
      ),
    );
  }
}

Widget _navItemImage(String assetPath, {bool isActive = false}) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: 24,
          height: 24,
          color: isActive ? Colors.white : const Color(0xFFbbb8a0),
        ),
      ],
    ),
  );
}

Widget _navItemIcon(IconData iconData, {bool isActive = false}) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          iconData,
          size: 24,
          color: isActive ? Colors.white : const Color(0xFFbbb8a0),
        ),
      ],
    ),
  );
}
