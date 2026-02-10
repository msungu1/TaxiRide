import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Custom Imports
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:sizemore_taxi/Editprofile/EditProfileScreen.dart';
import 'package:sizemore_taxi/changepassword/ChangePasswordScreen.dart';
import 'package:sizemore_taxi/login_screen/LoginScreen.dart';
import 'package:sizemore_taxi/drivernotification/DriverNotificationsScreen.dart';
import 'package:sizemore_taxi/driverwallet/DriverWalletScreen.dart';
import 'package:sizemore_taxi/DriverTrips/DriverTripsScreen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // UI & Map State
  int _selectedIndex = 0;
  bool _onlineStatus = false;
  bool _locationLoading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _initialPosition = const LatLng(-1.286389, 36.817223);
  StreamSubscription<Position>? _positionStream;

  // Driver Data
  String? name, email, phone, vehicleModel, plateNumber;
  double earningsToday = 0.0;
  double earningsWeek = 0.0;
  double driverRating = 4.8;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _determineInitialPosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    SocketService.instance.disconnect();
    super.dispose();
  }

  // ---------------- INITIAL LOCATION ----------------
  Future<void> _determineInitialPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _locationLoading = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_initialPosition, 14.5),
    );
  }

  // ---------------- ONLINE / OFFLINE ----------------
  void _toggleOnlineStatus(bool enable) async {
    setState(() => _onlineStatus = enable);

    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('userId');

    if (enable && driverId != null) {
      // INIT SOCKET
      SocketService.instance.init(
        userId: driverId,
        lat: _initialPosition.latitude,
        lng: _initialPosition.longitude,
        role: 'driver',
      );

      // START LOCATION STREAM
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream =
          Geolocator.getPositionStream(locationSettings: settings)
              .listen((position) {
            SocketService.instance.sendLocation(
              lat: position.latitude,
              lng: position.longitude,
            );

            setState(() {
              _initialPosition =
                  LatLng(position.latitude, position.longitude);
            });
          });
    } else {
      _positionStream?.cancel();
      SocketService.instance.disconnect();
    }
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      name = prefs.getString('name') ?? 'Driver';
      vehicleModel = prefs.getString('vehicleModel') ?? 'Toyota Axio';
      plateNumber = prefs.getString('plateNumber') ?? 'KDA 123A';
    });

    try {
      final response = await http.get(
        Uri.parse('https://sizemoretaxi.onrender.com/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['user'];
        setState(() {
          name = data['name'];
          email = data['email'];
          phone = data['phone'];
          vehicleModel = data['vehicleModel'];
          plateNumber = data['plateNumber'];
        });
      }
    } catch (_) {}
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      const Center(child: Text("No active rides")),
      _buildAccountTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedIndex == 0
              ? "Home"
              : _selectedIndex == 1
              ? "Rides"
              : "Account",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_taxi), label: "Rides"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(radius: 25),
            title: Text(name ?? "Driver",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              _onlineStatus ? "ONLINE" : "OFFLINE",
              style: TextStyle(
                color: _onlineStatus ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            trailing: Switch(
              value: _onlineStatus,
              activeColor: Colors.green,
              onChanged: _toggleOnlineStatus,
            ),
          ),

          // MAP (unchanged)
          Container(
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: _locationLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
              initialCameraPosition:
              CameraPosition(target: _initialPosition, zoom: 14.5),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    return ListView(
      children: [
        ListTile(
          title: const Text("Edit Profile"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
        ),
        ListTile(
          title: const Text("Change Password"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          ),
        ),
        ListTile(
          title: const Text("Logout"),
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
            );
          },
        ),
      ],
    );
  }
}
