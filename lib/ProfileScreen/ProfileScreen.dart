import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/Editprofile/EditProfileScreen.dart';
import 'package:sizemore_taxi/changeemail/ChangeEmailScreen.dart';
import 'package:sizemore_taxi/changepassword/ChangePasswordScreen.dart';
import 'package:sizemore_taxi/changephone/ChangePhoneScreen.dart';
import 'package:sizemore_taxi/help/HelpSupportScreen.dart';
import 'package:sizemore_taxi/privacy/PrivacyPolicyScreen.dart';
import 'package:sizemore_taxi/login_screen/LoginScreen.dart';
import 'package:sizemore_taxi/requestride/RequestRideScreen.dart';
import 'package:sizemore_taxi/triphistory/TripHostryScreen.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps; 
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await StitchApp.create());
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier(bool initialDarkMode) : _isDarkMode = initialDarkMode;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveTheme(isDark);
    notifyListeners();
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
  }
}

class StitchApp extends StatelessWidget {
  final bool initialDarkMode;

  const StitchApp({super.key, this.initialDarkMode = false});

  static Future<StitchApp> create() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('darkMode') ?? false;
    return StitchApp(initialDarkMode: isDark);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(initialDarkMode),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: 'Stitch Design',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              primarySwatch: Colors.green,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              scaffoldBackgroundColor: Colors.black,
              primarySwatch: Colors.green,
              brightness: Brightness.dark,
            ),
            themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const ProfileScreen(),
          );
        },
      ),
    );
  }
}

class Ride {
  final String place;
  final String dateTime;
  final String fare;
  final bool cancelled;

  Ride({
    required this.place,
    required this.dateTime,
    required this.fare,
    this.cancelled = false,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? name;
  String? email;
  String? phone;
  String? profilePic;

  final TextEditingController _whereToController = TextEditingController();
  List<String> recentPlaces = [];

  // 🔹 Mock ride history
  List<Ride> rideHistory = [
    Ride(place: "Ena Coach Booking", dateTime: "22 Apr, 7:22", fare: "Ksh 100"),
    Ride(place: "Maringo Ecohome", dateTime: "20 Apr, 9:19", fare: "Ksh 170"),
    Ride(place: "Modern Christian", dateTime: "4 Apr, 16:30", fare: "Ksh 0", cancelled: true),
    Ride(place: "Modern Christian", dateTime: "4 Apr, 16:16", fare: "Ksh 0", cancelled: true),
    Ride(place: "Modern Christian", dateTime: "4 Apr, 16:14", fare: "Ksh 0", cancelled: true),
    Ride(place: "Modern Christian", dateTime: "4 Apr, 16:01", fare: "Ksh 0", cancelled: true),
  ];

  // Map-related variables
  Position? _currentPosition;
  Completer<gmaps.GoogleMapController> _mapController = Completer();
  gmaps.CameraPosition _initialCameraPosition = const gmaps.CameraPosition(
    target: gmaps.LatLng(0, 0),
    zoom: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadRecentPlaces();
    _loadUserData();
    _getCurrentLocation();
  }

  /// 🔹 Loads only recent places
  Future<void> _loadRecentPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentPlaces = prefs.getStringList('recentPlaces') ?? [];
    });
  }

  /// 🔹 Loads user details
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'Guest';
      email = prefs.getString('email') ?? 'Not set';
      phone = prefs.getString('phone') ?? '';
      profilePic = prefs.getString('profilePic');
    });
  }

  /// Get current location with permission handling
  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _initialCameraPosition = gmaps.CameraPosition(
            target: gmaps.LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: 14,
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    }
  }

  /// 🔹 Saves a recent place (max 5)
  Future<void> _addRecentPlace(String place) async {
    if (place.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!recentPlaces.contains(place)) {
        recentPlaces.insert(0, place);
      }
      if (recentPlaces.length > 5) {
        recentPlaces = recentPlaces.sublist(0, 5);
      }
      prefs.setStringList('recentPlaces', recentPlaces);
    });
  }

  void _openScheduleModal() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = pickedDate;
          selectedTime = pickedTime;
        });

        if (_whereToController.text.isNotEmpty) {
          _addRecentPlace(_whereToController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Scheduled for: ${pickedDate.toLocal().toString().split(' ')[0]} at ${pickedTime.format(context)}",
            ),
          ),
        );
      }
    }
  }

  // 🏠 Home Tab with interactive Google Map
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 380,
            child: _currentPosition != null
                ? gmaps.GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (gmaps.GoogleMapController controller) {
                _mapController.complete(controller);
              },
              markers: {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('current_location'),
                  position: gmaps.LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  infoWindow: const gmaps.InfoWindow(title: 'You are here'),
                ),
              },
            )
                : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Getting your location..."),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 600,
            child: RequestRideScreen(),
          ),
        ],
      ),
    );
  }
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have been logged out")),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const TripHistoryScreen();
      case 2:
        return _buildAccountTab();
      default:
        return const SizedBox();
    }
  }

  // 👤 Account Tab
  Widget _buildAccountTab() {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return ListView(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: profilePic != null && profilePic!.isNotEmpty
                        ? NetworkImage(profilePic!)
                        : const AssetImage("assets/default_avatar.png") as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name ?? "Guest",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email ?? "",
                    style: const TextStyle(
                      fontSize: 19,
                    ),
                  ),
                  Text(
                    phone ?? "",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            _SettingsTile(title: 'Edit Profile', icon: Icons.edit, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            }),
            _SettingsTile(title: 'Change Email', icon: Icons.email, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangeEmailScreen()),
              );
            }),
            _SettingsTile(title: 'Change Phone', icon: Icons.phone, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePhoneScreen()),
              );
            }),
            _SettingsTile(title: 'Change Password', icon: Icons.lock, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            }),
            SwitchListTile(
              activeColor: Colors.green,
              title: const Text("Notifications"),
              secondary: const Icon(Icons.notifications),
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() {
                  _notificationsEnabled = val;
                });
              },
            ),
            SwitchListTile(
              activeColor: Colors.green,
              title: const Text("Dark Mode"),
              secondary: const Icon(Icons.dark_mode),
              value: themeNotifier.isDarkMode,
              onChanged: (val) {
                themeNotifier.toggleTheme(val);
              },
            ),
            _SettingsTile(
              title: 'Language',
              icon: Icons.language,
              onTap: () {},
            ),
            _SettingsTile(
              title: 'Help & Support',
              icon: Icons.help_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                );
              },
            ),
            _SettingsTile(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),
            _SettingsTile(
              title: 'Logout',
              icon: Icons.logout,
              onTap: () => _logout(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      drawer: Drawer(
        child: _buildAccountTab(),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month, size: 28), label: 'My Rides'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28), label: 'Account'),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent, size: 26),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}