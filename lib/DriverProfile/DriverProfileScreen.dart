import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizemore_taxi/DriverTrips/DriverTripsScreen.dart';
import 'package:sizemore_taxi/DriverWallet/DriverWalletScreen.dart';
import 'package:sizemore_taxi/drivernotification/DriverNotificationsScreen.dart';
import 'package:sizemore_taxi/changeemail/ChangeEmailScreen.dart';
import 'package:sizemore_taxi/changepassword/ChangePasswordScreen.dart';
import 'package:sizemore_taxi/changephone/ChangePhoneScreen.dart';
import 'package:sizemore_taxi/Editprofile/EditProfileScreen.dart';
import 'package:sizemore_taxi/help/HelpSupportScreen.dart';
import 'package:sizemore_taxi/login_screen/LoginScreen.dart';
import 'package:sizemore_taxi/privacy/PrivacyPolicyScreen.dart';
import "package:sizemore_taxi/driverRequest/DriverAvailableTripsScreen.dart";
import 'package:sizemore_taxi/triphistory/TripHostryScreen.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:sizemore_taxi/driver_active_trip_screen/driver_active_trip_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}


class _DriverProfileScreenState extends State<DriverProfileScreen> {
  int _selectedIndex = 0;
  bool _onlineStatus = false;

  String? name, email, phone, profilePic, vehicleModel, plateNumber;
  double earningsToday = 0.0;
  double earningsWeek = 0.0;
  double driverRating = 4.8;

  // ── Map related ───────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  bool _followingDriver = true;
  String? _currentUserId; // ✅ Add this line here
  Map<String, dynamic>? _activeTripData; // Stores the current ride info
  String _tripStatus = 'idle'; // 'idle', 'en_route', 'arrived', 'started'

  final List<Widget> _screens = [
    const DriverAvailableTripsScreen(),   // The Marketplace we built
    const TripHistoryScreen(),            // History screen
  ];

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(-1.286389, 36.817223), // Nairobi approx
    zoom: 15.0,
  );


  @override
  void initState() {
    super.initState();
    // We call a separate async method because initState itself cannot be async
    _initializeDriverSystem();
  }

  Future<void> _initializeDriverSystem() async {
    // 1. Load local driver profile details (name, car, etc.)
    await _loadDriverData();

    // 2. Access SharedPreferences to get the User ID
    final prefs = await SharedPreferences.getInstance();

    // ✅ FIX: Assign to the class-level variable so the location stream can see it
    _currentUserId = prefs.getString('userId');

    // 3. Start GPS tracking
    // This must happen before Socket init so we have coordinates to send
    await _startLocationUpdates();

    // 4. Initialize the Socket Connection
    // We use the class-level _currentUserId here
    SocketService.instance.init(
      userId: _currentUserId ?? 'unknown_id',
      lat: _currentPosition?.latitude ?? -1.286389, // Default to Nairobi
      lng: _currentPosition?.longitude ?? 36.817223,
      role: 'driver',
    );

    // 5. Setup Listener for incoming Ride Requests
    SocketService.instance.socket?.on('ride_assigned', (data) {
      _showNewRidePopup(data);
    });

    // 6. Sync Online Status
    // If the app was closed while online, tell the server we are still here
    if (_onlineStatus && _currentPosition != null) {
      SocketService.instance.updateLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      debugPrint("📡 Driver Reconnected: Syncing online status for $_currentUserId");
    }
  }
  void _showNewRidePopup(dynamic rideData) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🚕 New Ride Assigned!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Pickup: ${rideData['pickupAddress'] ?? 'Unknown'}",
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  final tripId =
                      rideData['tripId'] ?? rideData['_id'];

                  // 🔥 DRIVER ACCEPTS RIDE
                  SocketService.instance.socket?.emit(
                    'accept_ride',
                    {
                      'tripId': tripId,
                      'driverId': _currentUserId,
                    },
                  );
                  // Store active trip locally
                  setState(() {
                    _activeTripData = rideData;
                    _tripStatus = 'en_route';
                    _selectedIndex = 0;
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ride Accepted"),
                    ),
                  );
                },
                child: const Text(
                  "ACCEPT RIDE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }



  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'Driver';
      email = prefs.getString('email') ?? 'Not set';
      phone = prefs.getString('phone') ?? '';
      profilePic = prefs.getString('profilePic');
      // Change 'vehicleModel' to 'carModel' to match backend
      vehicleModel = prefs.getString('carModel') ?? 'Toyota Axio';
      // Change 'plateNumber' to 'carNumber' to match backend
      plateNumber = prefs.getString('carNumber') ?? 'KDA 123A';
      earningsToday = prefs.getDouble('earningsToday') ?? 1500.0;
      earningsWeek = prefs.getDouble('earningsWeek') ?? 7500.0;
    });
  }
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Location permission permanently denied. Open settings?"),
          action: SnackBarAction(
            label: "Settings",
            onPressed: () => Geolocator.openAppSettings(),
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _startLocationUpdates() async {
    if (!await _handleLocationPermission()) return;

    // Initial position
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _currentPosition = pos);
        _animateToPosition(pos);
      }
    } catch (e) {
      debugPrint("Initial location error: $e");
    }

    // Live updates
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: Duration(seconds: 20),
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings).listen(
          (Position pos) {
        if (!mounted) return;

        setState(() {
          _currentPosition = pos;
        });

        // 🚀 ENHANCED UPDATE: Send location + rotation to the backend
        if (_onlineStatus) {
          // We use the socket instance directly to include the 'heading'
          // This is what makes the car icon rotate on the Passenger's Map
          SocketService.instance.socket?.emit('driver_location_update', {
            'driverId': _currentUserId, // Ensure this variable is set in _initializeDriverSystem
            'lat': pos.latitude,
            'lng': pos.longitude,
            'heading': pos.heading,    // Direction the driver is facing (0-360 degrees)
            'speed': pos.speed,        // Helpful for calculating ETA more accurately
            'timestamp': DateTime.now().toIso8601String(),
          });

          debugPrint("📡 Broadcast: Lat: ${pos.latitude}, Lng: ${pos.longitude}, Heading: ${pos.heading}");
        }

        // Smoothly move the driver's own map
        if (_followingDriver) {
          _animateToPosition(pos);
        }
      },
      onError: (e) {
        debugPrint("Location stream error: $e");
        // Optional: Show a snackbar if location is lost
      },
    );
  }
  Future<void> _openNavigation(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open navigation"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Navigation launch error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Navigation error: $e"),
        ),
      );
    }
  }
  void _animateToPosition(Position pos) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 16.5,
          bearing: pos.heading,
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have been logged out")),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }
// 1. Function to trigger the phone call
  void _callRider(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  bool _isEmittingStatus = false;

  Future<void> _handleStatusUpdate() async {
    final tripId = _activeTripData?['tripId'] ?? _activeTripData?['_id'];

    if (tripId == null) return;

    // prevent spam clicks
    if (_isEmittingStatus) return;
    _isEmittingStatus = true;

    try {
      final socket = SocketService.instance.socket;

      if (_tripStatus == 'en_route') {
        // 🚕 Driver has arrived at pickup
        socket?.emit('driver_arrived', {
          'tripId': tripId,
        });

        // 📢 notify passenger (optional extra event if backend supports it)
        socket?.emit('trip_status_update', {
          'tripId': tripId,
          'status': 'arrived',
        });

        setState(() {
          _tripStatus = 'arrived';
        });
      }

      else if (_tripStatus == 'arrived') {
        // 🚀 Passenger has entered car / trip starts
        socket?.emit('start_trip', {
          'tripId': tripId,
        });

        socket?.emit('trip_status_update', {
          'tripId': tripId,
          'status': 'started',
        });


        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => DriverActiveTripScreen(
        //       tripData: _activeTripData!,
        //     ),
        //   ),
        // );
        final tripEnded = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverActiveTripScreen(
              tripData: _activeTripData!,
            ),
          ),
        );

// ✅ Reset UI immediately after trip ends
        if (tripEnded == true && mounted) {
          setState(() {
            _activeTripData = null;
            _tripStatus = 'idle';
            _selectedIndex = 0; // Home tab
          });
        }

      }

      else if (_tripStatus == 'started') {
        // 🏁 Trip completed
        socket?.emit('complete_trip', {
          'tripId': tripId,
        });

        socket?.emit('trip_status_update', {
          'tripId': tripId,
          'status': 'completed',
        });

        setState(() {
          _tripStatus = 'completed';
          _activeTripData = null;
        });
      }

    } catch (e) {
      debugPrint("❌ Status update error: $e");
    }

    // unlock button after delay
    Future.delayed(const Duration(seconds: 2), () {
      _isEmittingStatus = false;
    });
  }


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

  // ── Home Tab with Live Map ────────────────────────────────────────────────
  Widget _buildHomeTab() {
    return Column(
      children: [
        // Driver header + online toggle
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          color: Colors.white,
          child: Row(
            children: [

              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  name?.substring(0, 1).toUpperCase() ?? "D",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? "Driver",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      "⭐ ${driverRating.toStringAsFixed(1)} • ${vehicleModel ?? ''}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    _onlineStatus ? "Online" : "Offline",
                    style: TextStyle(
                      fontSize: 12,
                      color: _onlineStatus ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Switch(
                    value: _onlineStatus,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() => _onlineStatus = val);

                      if (val) {
                        // 🚀 CRITICAL: If they just toggled ON, send the current position immediately
                        if (_currentPosition != null) {
                          SocketService.instance.updateLocation(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          );
                          debugPrint("📡 Robert One manually toggled ONLINE. Sending location...");
                        }
                      } else {
                        // Optional: You might want to tell the server the driver is now offline
                        // SocketService.instance.emit('driver_offline', userId);
                      }
                    },
                  ),                ],
              ),
            ],
          ),
        ),

        // Map area (takes remaining space)
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: _defaultPosition,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,

                markers: _currentPosition == null
                    ? {}
                    : {
                  Marker(
                    markerId: const MarkerId("driver"),
                    position: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    rotation: _currentPosition!.heading,
                    flat: true,
                    anchor: const Offset(0.5, 0.5),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  ),
                },

                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  if (_currentPosition != null) {
                    _animateToPosition(_currentPosition!);
                  }
                },
              ),
              // Optional recenter button (appears when auto-follow is off)
              if (!_followingDriver && _currentPosition != null)
                Positioned(
                  right: 16,
                  bottom: 90,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: () {
                      _animateToPosition(_currentPosition!);
                      setState(() => _followingDriver = true);
                    },
                  ),
                ),
            ],
          ),
        ),

        // Quick actions + summary (scrollable part)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickAction(Icons.history, "My Trips", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverTripsScreen()),
                        );
                      }),
                      _quickAction(Icons.account_balance_wallet, "Wallet", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverWalletScreen()),
                        );
                      }),
                      _quickAction(Icons.notifications, "Notifications", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverNotificationsScreen()),
                        );
                      }),
                      _quickAction(Icons.settings, "Settings", () {
                        setState(() => _selectedIndex = 2);
                      }),
                    ],
                  ),
                ),

                const Divider(height: 1),

              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _SummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRidesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_taxi, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No active rides", style: TextStyle(fontSize: 18, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
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
                    Text(name ?? "Driver", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email ?? "Not set", style: const TextStyle(color: Colors.black54)),
                    Text(phone ?? "", style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(
                      "${vehicleModel ?? ''} • ${plateNumber ?? ''}",
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        _SettingsTile(
          title: 'Edit Profile',
          icon: Icons.edit,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
        ),
        _SettingsTile(
          title: 'Change Email',
          icon: Icons.email,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailScreen())),
        ),
        _SettingsTile(
          title: 'Change Phone',
          icon: Icons.phone,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePhoneScreen())),
        ),
        _SettingsTile(
          title: 'Change Password',
          icon: Icons.lock,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
        _SettingsTile(
          title: 'Help & Support',
          icon: Icons.help_outline,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
        ),
        _SettingsTile(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
        ),
        _SettingsTile(
          title: 'Logout',
          icon: Icons.logout,
          onTap: () => _logout(context),
        ),
      ],
    );
  }
  Widget _buildActiveTripOverlay() {
    if (_activeTripData == null) {
      return const SizedBox.shrink();
    }

    const Color brandYellow = Color(0xFFFFD60A);

    final pickup = _activeTripData!['pickupAddress'] ?? "Pickup";
    final destination = _activeTripData!['dropoffAddress'] ?? "Destination";
    final riderName = _activeTripData!['riderName'] ?? "Passenger";

    return Positioned(
      bottom: 20,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// TOP ROW
            Row(
              children: [

                const CircleAvatar(
                  radius: 24,
                  backgroundColor: brandYellow,
                  child: Icon(
                    Icons.person,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        riderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _tripStatus == 'en_route'
                            ? "Heading to pickup"
                            : _tripStatus == 'arrived'
                            ? "Waiting for passenger"
                            : "Trip in progress",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                /// CALL BUTTON
                IconButton(
                  onPressed: () =>
                      _callRider(_activeTripData!['riderPhone']),
                  icon: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// PICKUP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Icon(
                  Icons.radio_button_checked,
                  color: Colors.green,
                  size: 18,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    pickup,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// DESTINATION
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 18,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// PROGRESS BAR
            Row(
              children: [

                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: _tripStatus == 'en_route'
                          ? brandYellow
                          : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: _tripStatus == 'started'
                          ? Colors.green
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            /// ACTION BUTTONS
            Row(
              children: [

                /// NAVIGATION BUTTON
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final lat = _tripStatus == 'started'
                          ? _activeTripData!['dropoffLat']
                          : _activeTripData!['pickupLat'];

                      final lng = _tripStatus == 'started'
                          ? _activeTripData!['dropoffLng']
                          : _activeTripData!['pickupLng'];

                      if (lat != null && lng != null) {
                        _openNavigation(lat, lng);
                      }
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text("Navigate"),
                  ),
                ),

                const SizedBox(width: 12),

                /// STATUS BUTTON
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _tripStatus == 'arrived'
                            ? Colors.green
                            : brandYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      onPressed: _handleStatusUpdate,

                      child: Text(
                        _tripStatus == 'en_route'
                            ? "I HAVE ARRIVED"
                            : _tripStatus == 'arrived'
                            ? "START TRIP"
                            : "END TRIP",

                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      const DriverAvailableTripsScreen(),      _buildAccountTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        title: Text(
          _selectedIndex == 0 ? "Home" : _selectedIndex == 1 ? "Rides" : "Account",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // body: tabs[_selectedIndex],
      body: Stack(
        children: [
          tabs[_selectedIndex],

          // ✅ Show active trip overlay only on Home tab
          if (_selectedIndex == 0)
            _buildActiveTripOverlay(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_taxi), label: "Rides"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
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
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}