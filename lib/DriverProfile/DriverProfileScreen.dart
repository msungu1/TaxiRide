import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/Editprofile/EditProfileScreen.dart';
import 'package:sizemore_taxi/changeemail/ChangeEmailScreen.dart';
import 'package:sizemore_taxi/changepassword/ChangePasswordScreen.dart';
import 'package:sizemore_taxi/changephone/ChangePhoneScreen.dart';
import 'package:sizemore_taxi/help/HelpSupportScreen.dart';
import 'package:sizemore_taxi/privacy/PrivacyPolicyScreen.dart';
import 'package:sizemore_taxi/login_screen/LoginScreen.dart';
import 'package:sizemore_taxi/drivernotification/DriverNotificationsScreen.dart';
import 'package:sizemore_taxi/driverwallet/DriverWalletScreen.dart';
import 'package:sizemore_taxi/DriverTrips/DriverTripsScreen.dart';
import 'dart:convert'; // For jsonEncode/jsonDecode
import 'package:http/http.dart' as http; // Fixes 'http' error
import 'package:socket_io_client/socket_io_client.dart' as IO; // Fixes 'IO' and 'Socket' errors
import 'dart:async'; // Add this for StreamSubscription

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
// To store current trip details
  Map<String, dynamic>? _currentTrip;
  GoogleMapController? _mapController;
  late IO.Socket socket;
  LatLng _initialPosition = const LatLng(-1.286389, 36.817223); // Nairobi default
  bool _locationLoading = true;
  StreamSubscription<Position>? _positionStream;

  int _selectedIndex = 0;
  bool _onlineStatus = false;
  String? name, email, phone, profilePic, vehicleModel, plateNumber;
  double earningsToday = 0.0;
  double earningsWeek = 0.0;
  double driverRating = 4.8;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _determinePosition(); // Get driver's current location
    _initSocket();
  }
  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }
  // --- SOCKET LOGIC ---
  void _initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('driverId');

    socket = IO.io('https://sizemoretaxi.onrender.com/',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .enableAutoConnect()
            .build()
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to Backend Socket');
      if (userId != null) {
        socket.emit('join', userId);
      }
    });

    socket.on('ride_requested', (data) {
      _showNewRideDialog(data);
    });

    socket.onDisconnect((_) => debugPrint('Disconnected from Socket'));
  }

  void _showNewRideDialog(dynamic data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("🚖 New Ride Request!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pickup: ${data['pickupLocation'] ?? 'Unknown'}"),
            const SizedBox(height: 8),
            Text("Fare: KES ${data['fare']?['amount'] ?? '0'}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Decline", style: TextStyle(color: Colors.red))
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _acceptRide(data['tripId'], data);              },
              child: const Text("Accept")
          ),
        ],
      ),
    );
  }

  void _startLocationUpdates() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {

      // 1. Update the local Map UI
      _initialPosition = LatLng(position.latitude, position.longitude);

      // 2. Send location to Backend via Socket
      // Your backend likely expects 'updateLocation' or 'driver_location'
      if (socket.connected) {
        socket.emit('update_location', {
          'lat': position.latitude,
          'lng': position.longitude,
        });
        debugPrint("Location sent to server: ${position.latitude}, ${position.longitude}");
      }
    });
  }
  void _zoomToFitMarkers() {
    if (_markers.length < 2) return;

    // Create a bounds that includes all markers currently on the map
    double? minLat, maxLat, minLng, maxLng;

    for (Marker m in _markers) {
      if (minLat == null || m.position.latitude < minLat) minLat = m.position.latitude;
      if (maxLat == null || m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (minLng == null || m.position.longitude < minLng) minLng = m.position.longitude;
      if (maxLng == null || m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    // 50 is the padding in pixels from the edge of the container
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }
// --- NEW: ACCEPT RIDE LOGIC ---
  Future<void> _acceptRide(String? tripId, dynamic tripData) async {
    if (tripId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('https://sizemoretaxi.onrender.com/api/trips/accept'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'tripId': tripId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trip Accepted! Navigating to pickup..."))
        );

        setState(() {
          // 1. Clear previous markers
          _markers.clear();

          // 2. Add Pickup Marker (Green)
          _markers.add(Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(
                tripData['pickupLocation']['lat'],
                tripData['pickupLocation']['lng']
            ),
            infoWindow: const InfoWindow(title: "Pickup Passenger"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));

          // 3. Add Dropoff Marker (Red)
          _markers.add(Marker(
            markerId: const MarkerId('dropoff'),
            position: LatLng(
                tripData['dropoffLocation']['lat'],
                tripData['dropoffLocation']['lng']
            ),
            infoWindow: const InfoWindow(title: "Destination"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
        });

        // 4. Zoom the camera to show both points
        _zoomToFitMarkers();
      }
    } catch (e) {
      debugPrint("Error accepting trip: $e");
    }
  }

  // // --- NEW METHOD: Determine Current Position ---
  // Future<void> _determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) return;
  //
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) return;
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) return;
  //
  //   Position position = await Geolocator.getCurrentPosition();
  //
  //   if (mounted) {
  //     setState(() {
  //       _initialPosition = LatLng(position.latitude, position.longitude);
  //       _locationLoading = false;
  //     });
  //
  //     // Smoothly move the camera to the driver
  //     _mapController?.animateCamera(
  //       CameraUpdate.newLatLngZoom(_initialPosition, 14.5),
  //     );
  //   }
  // }

  // Future<void> _loadDriverData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     name = prefs.getString('name') ?? 'Driver';
  //     email = prefs.getString('email') ?? 'Not set';
  //     phone = prefs.getString('phone') ?? '';
  //     profilePic = prefs.getString('profilePic');
  //     vehicleModel = prefs.getString('vehicleModel') ?? 'Toyota Axio';
  //     plateNumber = prefs.getString('plateNumber') ?? 'KDA 123A';
  //     earningsToday = prefs.getDouble('earningsToday') ?? 1500.0;
  //     earningsWeek = prefs.getDouble('earningsWeek') ?? 7500.0;
  //   });
  // }

  // --- LOCATION LOGIC ---
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _locationLoading = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 14.5));
    }
  }

  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token'); // Ensure you save this at login

    // 1. Set local defaults first
    setState(() {
      name = prefs.getString('name') ?? 'Driver';
      email = prefs.getString('email') ?? 'Not set';
    });

    // 2. Fetch fresh data from Render
    try {
      final response = await http.get(
        Uri.parse('https://sizemoretaxi.onrender.com/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user']; // Adjust based on your actual JSON structure

        setState(() {
          name = user['name'];
          email = user['email'];
          phone = user['phone'];
          // MATCHING BACKEND: Ensure key names match your User Model
          vehicleModel = user['vehicleModel'] ?? 'No Vehicle';
          plateNumber = user['plateNumber'] ?? 'No Plate';
          // Your backend logic for vehicleType is crucial here
          String backendVehicleType = user['vehicleType'] ?? 'standard';

          prefs.setString('vehicleType', backendVehicleType);
        });
      }
    } catch (e) {
      debugPrint("Backend sync failed: $e");
    }
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

  /// ---------- HOME TAB ----------
  // ✅ Quick Action Button Helper
  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

// ✅ Updated Home Tab
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Driver Info + Online/Offline Toggle
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: (profilePic != null && profilePic!.isNotEmpty)
                  ? NetworkImage(profilePic!)
                  : const AssetImage("assets/default_avatar.png") as ImageProvider,
            ),
            title: Text(
              name ?? "Driver",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "⭐ ${driverRating.toStringAsFixed(1)} • ${vehicleModel ?? ""}",
              style: const TextStyle(color: Colors.black54),
            ),
            // 🔹 LIVE STATUS TOGGLE
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _onlineStatus ? "ONLINE" : "OFFLINE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _onlineStatus ? Colors.green : Colors.red,
                  ),
                ),
                Switch(
                  value: _onlineStatus,
                  activeColor: Colors.green,
                  onChanged: (val) {
                    setState(() {
                      _onlineStatus = val;
                      if (_onlineStatus) {
                        _startLocationUpdates(); // Start GPS tracking
                        socket.emit('go_online'); // Notify Backend
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("You are now online and searching for rides")),
                        );
                      } else {
                        _positionStream?.cancel(); // Stop GPS tracking to save battery
                        socket.emit('go_offline'); // Notify Backend
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("You are now offline")),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // 🔹 Map Section
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _locationLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 14.5,
                ),
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _markers, // <--- Add this
                polylines: _polylines, // <--- Add this
                mapType: MapType.normal,
                zoomControlsEnabled: false,
              ),
            ),
          ),

          // 🔹 Quick Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAction(Icons.history, "My Trips", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverTripsScreen()));
                }),
                _quickAction(Icons.account_balance_wallet, "Wallet", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverWalletScreen()));
                }),
                _quickAction(Icons.notifications, "Notifications", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverNotificationsScreen()));
                }),
                _quickAction(Icons.settings, "Settings", () {
                  setState(() => _selectedIndex = 2); // Switch to Account Tab
                }),
              ],
            ),
          ),

          const Divider(thickness: 1),

          // 🔹 Daily Summary Card
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "📊 Today's Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("Earnings", style: TextStyle(color: Colors.black54)),
                          Text(
                            "Ksh ${earningsToday.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Weekly", style: TextStyle(color: Colors.black54)),
                          Text(
                            "Ksh ${earningsWeek.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Rating", style: TextStyle(color: Colors.black54)),
                          Text(
                            driverRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- RIDES TAB ----------
  Widget _buildRidesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.local_taxi, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No active rides",
              style: TextStyle(fontSize: 18, color: Colors.black54)),
        ],
      ),
    );
  }

  /// ---------- ACCOUNT TAB ----------
  /// ---------- ACCOUNT TAB ----------
  Widget _buildAccountTab() {
    return ListView(
      children: [
        // 🔹 Profile Header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: (profilePic != null && profilePic!.isNotEmpty)
                    ? NetworkImage(profilePic!)
                    : const AssetImage("assets/default_avatar.png") as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? "Driver",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? "Not set",
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    Text(
                      phone ?? "",
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${vehicleModel ?? ""} • ${plateNumber ?? ""}",
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // 🔹 Settings List
        _SettingsTile(
          title: 'Edit Profile',
          icon: Icons.edit,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Change Email',
          icon: Icons.email,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangeEmailScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Change Phone',
          icon: Icons.phone,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePhoneScreen()),
            );
          },
        ),
        _SettingsTile(
          title: 'Change Password',
          icon: Icons.lock,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
            );
          },
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
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      _buildRidesTab(),
      _buildAccountTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Text(
          _selectedIndex == 0
              ? "Home"
              : _selectedIndex == 1
              ? "Rides"
              : "Account",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi),
            label: "Rides",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent, size: 26),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing:
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
