// import 'package:flutter/material.dart';
// import '../ProfileScreen/ProfileScreen.dart';
// import '../registration_Screen/RegistrationScreen.dart';
// import '../onetimescreen/OnetimeScreen.dart';
//
// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});
//
//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }
//
// class _MainScreenState extends State<MainScreen> {
//   int _currentIndex = 0;
//
//   final List<Widget> _screens = [
//     RegistrationScreen(),  // Home/Account creation
//     OnetimeScreen(),        // Change Email
//     ProfileScreen(),        // Profile page
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _screens,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: const Color(0xFF2d2b20),
//         selectedItemColor: Colors.white,
//         unselectedItemColor: const Color(0xFFbbb8a0),
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() => _currentIndex = index);
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home, size: 30),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.email, size: 30),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person, size: 30),
//             label: '',
//           ),
//         ],
//       ),
//     );
//   }
// }
