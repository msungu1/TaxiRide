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
import 'package:sizemore_taxi/PassengerRideDetailScreen/PassengerRideDetailScreen.dart';
import 'dart:convert'; // Fixes: 'jsonDecode' isn't defined
import 'package:http/http.dart' as http; // Fixes: Undefined name 'http'
import 'package:sizemore_taxi/UserProvider/UserProvider.dart'; // Fixes: 'UserProvider' isn't a type
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:sizemore_taxi/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(isDark),
      child: const StitchApp(),
    ),
  );
}


class StitchApp extends StatelessWidget {
  const StitchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Now Consumer is inside MaterialApp's scope,
    // and the Provider is ABOVE MaterialApp.
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Stitch Design',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            scaffoldBackgroundColor: Colors.black,
            brightness: Brightness.dark,
          ),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const ProfileScreen(),
        );
      },
    );
  }
}

class Ride {

  final String id;
  final String place;
  final String dateTime;
  final String fare;
  final String driverName;
  final String driverPhone;
  final String carDetails;
  final double lat;
  final double lng;
  final bool cancelled;

  Ride({
    required this.id,
    required this.place,
    required this.dateTime,
    required this.fare,
    required this.driverName,
    required this.driverPhone,
    required this.carDetails,
    required this.lat,
    required this.lng,
    this.cancelled = false,
  });


  factory Ride.fromJson(Map<String, dynamic> json) {
    // Extract location objects from the backend response
    final pickup = json['pickupLocation'] ?? {};
    final dropoff = json['dropoffLocation'] ?? {};
    final driver = json['driver'] ?? {};

    return Ride(
      id: json['_id'] ?? '',
      // Use the backend's address fields
      place: dropoff['address'] ?? 'Unknown Destination',
      dateTime: json['scheduledTime'] ?? '',
      fare: json['fare']?.toString() ?? '0',
      // Access populated driver fields
      driverName: driver['name'] ?? 'Searching...',
      driverPhone: driver['phone'] ?? '',
      carDetails: "${driver['carModel'] ?? ''} (${driver['carNumber'] ?? 'Taxi'})",
      lat: (dropoff['lat'] ?? 0.0).toDouble(),
      lng: (dropoff['lng'] ?? 0.0).toDouble(),
      cancelled: json['status'] == 'cancelled',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'carDetails': carDetails,
      'fare': fare,
      'lat': lat,
      'lng': lng,
    };
  }
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
  List<Ride> rideHistory = []; // Start empty
  bool _isHistoryLoading = true;

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
    _fetchRealRideHistory(); // Call the API fetch here
  }

  Future<void> _fetchRealRideHistory() async {
    // 1. Get the provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 2. Safety Check: If there's no user ID, don't even try to call the API
    if (userProvider.id == null || userProvider.id!.isEmpty) {
      debugPrint("User ID is missing. Skipping history fetch.");
      setState(() => _isHistoryLoading = false);
      return;
    }

    // 3. Construct URL
    final String url =
        'https://sizemoretaxi-itpj.onrender.com/api/trips/activity?userId=${userProvider.id}&role=rider';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 4. Validate that 'data' key exists and is a List
        if (data['data'] != null && data['data'] is List) {
          final List trips = data['data'];

          setState(() {
            // Map the API list to your Ride objects
            rideHistory = trips.map((json) => Ride.fromJson(json)).toList();
            _isHistoryLoading = false;
          });
        } else {
          // Handle case where 'data' is missing or not a list
          setState(() {
            rideHistory = [];
            _isHistoryLoading = false;
          });
        }
      } else {
        // 5. Handle Server Errors (e.g., 404, 500)
        debugPrint("Server error: ${response.statusCode} - ${response.body}");
        setState(() => _isHistoryLoading = false);
      }
    } catch (e) {
      // 6. Handle Connection/Timeout Errors
      debugPrint("Connection error fetching history: $e");
      if (mounted) {
        setState(() => _isHistoryLoading = false);
        // Optional: Show a snackbar to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't refresh your trip history")),
        );
      }
    }
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
            // Add this right after the Column containing the profile pic and name
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Recent Rides", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            _isHistoryLoading
                ? const Center(child: CircularProgressIndicator())
                : rideHistory.isEmpty
                ? const Padding(padding: EdgeInsets.all(16.0), child: Text("No rides yet"))
                : Column(
              children: rideHistory.take(2).map((ride) => ListTile(
                leading: const Icon(Icons.history, color: Colors.green),
                title: Text(ride.place),
                subtitle: Text(ride.dateTime),
                trailing: Text(ride.fare),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PassengerRideDetailScreen(rideData: ride.toMap())),
                  );
                },
              )).toList(),
            ),
            const Divider(),
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
                Navigator.pushNamed(
                  context,
                  '/help',
                  arguments: {'role': 'rider'},
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