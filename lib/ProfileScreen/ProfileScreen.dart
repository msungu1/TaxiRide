import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const StitchApp());
}

class StitchApp extends StatelessWidget {
  const StitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stitch Design',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1e1d15),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFFbbb8a0);
    const borderColor = Color(0xFF3f3d2c);
    const bgTileColor = Color(0xFF2d2b20);


    return Scaffold(
      backgroundColor: const Color(0xFF1d1d15),

      appBar: AppBar(
        backgroundColor: const Color((0xFF1d115)),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: const Color(0xFF1d1d15),
          statusBarIconBrightness: Brightness.light,
        ),

        actions: [

          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Move icon from edge
            child: IconButton(
              icon: const Icon(
                Icons.close,
                size: 32, // Increase icon size
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Or your desired close action
              },
            ),
          ),

        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            // color: const Color(0xFF1d1d15), // Apply dark background here
            child: Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 64,
                    backgroundImage: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDKgVY1m3_XYMUE104wEdbW2ond1Ziy71ecKotNgwtfSAUudRIk5TJ37tPBVWm573uIfP-cnsrDzEixaURram4Mwbv2lCQmvG5GHaVwiuo7uvQKUcM0w16dsOq-Y3erQvVMJenlwzsqxM58KKUQ4yAOD3H6ZlGZOEPoNgV7QoMx_hMcohUVpu1LIrQIeHBgrB0uATmLChKzBWoLaHLtnsCvwoozolmK9rvk0RBqF8YdKXO7pSx4nWAjHwHCV81Km5Wlc6qjce9jtrvV',
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Ethan Carter',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),

                  const Text(
                    'sizemoretaxi@gmail.com',
                    style: TextStyle(color: Color(0xFFbbb8a0),
                    fontSize: 19,
                    ),
                  ),


                  const Text(
                    '+254 743708135',
                    style: TextStyle(color: Color(0xFFbbb8a0)),
                  ),


                  const SizedBox(height: 12),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 25),
                  //   child: ElevatedButton(
                  //     onPressed: () {},
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xFF3f3d2c),
                  //       foregroundColor: Colors.white,
                  //       minimumSize: const Size.fromHeight(50),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(50),
                  //       ),
                  //     ),
                  //
                  //     child: const Text(
                  //       'Edit',
                  //       style: TextStyle(
                  //         fontSize: 20, // Increased font size
                  //         fontWeight: FontWeight.bold, // Increased font weight
                  //       ),
                  //     ),                    ),
                  // ),

                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFF3f3d2c)),
          const _SettingsTile(title: 'Change Email'),
          const _SettingsTile(title: 'Change Phone'),
          const _SettingsTile(title: 'Change Password'),
          const _SettingsTile(title: 'Logout'),

      ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2d2b20),
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFFbbb8a0),
        currentIndex: 0, // Assuming this is the profile screen
        onTap: (index) {
          // Handle navigation logic here if needed
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: '',
          ),
        ],
      ),


    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;

  const _SettingsTile({required this.title});

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFFbbb8a0);
    const tileColor = Color(0xFF1e1d15);

    return ListTile(
      tileColor: tileColor,
      title: Text(
          title,
          style: const TextStyle(
              color: textColor,
          fontSize: 18,
            fontWeight:FontWeight.w600,
          ),
      ),
      trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white,
          size: 28,
      ),
      onTap: () {},
    );
  }
}
