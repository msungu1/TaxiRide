import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:csv/csv.dart';
import 'package:sizemore_taxi/feedbackmodel/FeedbackModel.dart';
import 'package:sizemore_taxi/userlist/UserListScreen.dart';
import 'package:sizemore_taxi/driverListscreen/DriverListScreen.dart';
import 'package:sizemore_taxi/passengerlist/PassengerListScreen.dart';
import 'package:sizemore_taxi/blocked/BlockedUserListScreen.dart';
import 'package:sizemore_taxi/FeedbackScreen/FeedbackScreen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizemore_taxi/pending/PendingBookingsScreen.dart';
import 'package:sizemore_taxi/active/ActiveRidesScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:sizemore_taxi/ride_popup/ride_request_popup.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:sizemore_taxi/main.dart';
// import 'package:sizemore_taxi/dispatch/DispatchDriverDialog.dart';
import 'package:sizemore_taxi/dispatch/DispatchManagementScreen.dart';


/// Admin Dashboard screen for managing users, feedback, and reports.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<MarkerId, Marker> _driverMarkers = {};
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  List<UserModel> selectedUsers = [];
  List<dynamic> pendingTrips = []; // Dynamic list for trips
  bool isLoading = true;
  // String currentAdminId = "ADMIN_ID_HERE";
  String currentAdminId = "69ba699b69ab7e2d98210e71";
  final TextEditingController _tripSearchController = TextEditingController();
  List<dynamic> filteredTrips = [];
  List<FeedbackModel> feedbackList = [];
  bool isLoadingFeedback = false;
  bool isLoadingDashboard = true;
  bool isLoadingTrips = true;
  // Add these variables
  int pendingBookingsCount = 0;
  int activeRidesCount = 0;
  int onlineDriversCount = 0;
// In initState:
  Timer? _pollingTimer;
  int _lastTripCount = 0;
  bool _isPopupShowing = false;
  StreamSubscription? _socketSub;

  @override
  // void initState() {
  //   super.initState();
  //   // 1. Link the navigator key so popups can show over any screen
  //   SocketService.instance.setNavigatorKey(navigatorKey);
  //
  //   // 2. Initialize as Admin
  //   // Use dummy lat/lng for admin if location isn't required for dashboard
  //   SocketService.instance.init(
  //     userId: "69ba699b69ab7e2d98210e71", // your admin id
  //     lat: 0.0,
  //     lng: 0.0,
  //     role: 'admin',
  //   );
  //
  //   // Listen for driver updates via Socket
  //   SocketService.instance.socket?.on('driver_location_update', (data) {
  //     _updateDriverMarker(data);
  //   });
  //   SocketService.instance.socket?.on('trip_cancelled', (data) {
  //     debugPrint("🚨 Admin: Trip ${data['tripId']} was cancelled. Removing from UI...");
  //
  //     if (mounted) {
  //       setState(() {
  //         // Remove the trip from the local pending list immediately
  //         pendingTrips.removeWhere((trip) => trip['_id'] == data['tripId']);
  //
  //         // Update the count so the UI updates
  //         pendingBookingsCount = pendingTrips.length;
  //       });
  //
  //       // Optional: If the popup for THIS specific trip is showing, close it
  //       if (_isPopupShowing) {
  //         Navigator.of(context).pop();
  //         _isPopupShowing = false;
  //       }
  //
  //       Fluttertoast.showToast(
  //         msg: "A ride request was cancelled",
  //         backgroundColor: Colors.orange,
  //       );
  //     }
  //   });
  //
  //   fetchUsers();
  //   // fetchFeedback();
  //   // fetchDashboardStats();
  //   _refreshData();
  //   fetchPendingTrips();
  //
  //   _pollingTimer = Timer.periodic(const Duration(seconds:10), (timer)
  //   {
  //     if (mounted){
  //       fetchUsers();
  //       fetchPendingTrips();
  //       // fetchDashboardStats();
  //     }
  //   }
  //   );
  // }

  @override
  void initState() {
    super.initState();

    // 1. navigator key
    SocketService.instance.setNavigatorKey(navigatorKey);

    // 2. init socket
    SocketService.instance.init(
      userId: "69ba699b69ab7e2d98210e71",
      lat: 0.0,
      lng: 0.0,
      role: 'admin',
    );

    // 3. SINGLE SOURCE OF TRUTH: rideUpdates stream
    _socketSub = SocketService.instance.rideUpdates.listen((event) {
      if (!mounted) return;

      final type = event['type'];
      final tripId = event['tripId'];

      debugPrint("📡 Admin Stream Event: $event");

      // ---------------- CANCEL ----------------
      if (type == 'trip_cancelled') {
        setState(() {
          pendingTrips.removeWhere((t) => t['_id'] == tripId);
          pendingBookingsCount = pendingTrips.length;
        });

        if (_isPopupShowing) {
          Navigator.of(context).pop();
          _isPopupShowing = false;
        }

        Fluttertoast.showToast(
          msg: "A ride request was cancelled",
          backgroundColor: Colors.orange,
        );
      }

      // ---------------- NEW DRIVER LOCATION ----------------
      if (type == 'location') {
        _updateDriverMarker(event);
      }
    });

    fetchUsers();
    _refreshData();
    fetchPendingTrips();

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        fetchUsers();
        fetchPendingTrips();
      }
    });
  }

  void _updateDriverMarker(Map<String, dynamic> data) {
    // Use 'userId' or 'driverId' depending on what your backend emits back
    final String driverId = data['driverId'] ?? data['userId'] ?? 'unknown';
    final double lat = data['lat'] ?? 0.0;
    final double lng = data['lng'] ?? 0.0;

    if (lat == 0.0 || lng == 0.0) return;

    setState(() {
      _driverMarkers[MarkerId(driverId)] = Marker(
        markerId: MarkerId(driverId),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        // Fallback if name is missing from the stream
        infoWindow: InfoWindow(title: "Driver: ${data['driverName'] ?? 'Active Driver'}"),
      );
    });
  }
  @override
  void dispose(){
    _socketSub?.cancel(); // ✅ ADD THIS
    _pollingTimer?.cancel();
    super.dispose();
  }
  /// Helper to refresh all dashboard data
  Future<void> _refreshData() async {
    await Future.wait([
      fetchUsers(),
      // fetchFeedback(),
      // fetchDashboardStats(),
      fetchPendingTrips(),
    ]);
  }

// Update inside _AdminScreenState

  Future<void> fetchPendingTrips() async {
    try {
      // We only want the 'requested' ones for the horizontal list/popups
      final result = await AdminApiService.fetchAllTrips(status: 'requested');

      if (mounted) {
        setState(() {
          pendingTrips = result;
          isLoadingTrips = false;
          filteredTrips = result;

          // Check for new trips to show the popup
          if (pendingTrips.isNotEmpty && pendingTrips.length > _lastTripCount) {
            // Pass the last trip in the list to the popup
            _showRideRequestPopup(pendingTrips.first);
          }
          _lastTripCount = pendingTrips.length;
        });
      }
    } catch (e) {
      print("Dashboard Trip Fetch Error: $e");
    }
  }

  void _showRideRequestPopup(Map<String, dynamic> tripData) {
    if (_isPopupShowing) return;
    _isPopupShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RideRequestPopup(
        rideData: {
          'tripId': tripData['_id'],
          'riderName': tripData['riderName'], // Match your backend key
          'pickupLocation': tripData['pickupLocation'],
          'dropoffLocation': tripData['dropoffLocation'],
          'fare': tripData['fare'], // Make sure this matches the backend key
          'vehicleType': tripData['vehicleType'],
        },
        onAccept: () {
          Navigator.pop(context);
          _isPopupShowing = false;
          _showDispatchDialog(tripData['_id']);
        },
        onReject: () {
          Navigator.pop(context);
          _isPopupShowing = false;
          _handleCancel(tripData['_id']);
        },
      ),
    );
  }
  Future<void> fetchDashboardStats() async {
    setState(() => isLoadingDashboard = true);

    try {
      final stats = await AdminApiService.fetchDashboardStats();

      setState(() {
        pendingBookingsCount = stats['pendingBookings'] ?? 0;
        activeRidesCount = stats['activeRides'] ?? 0;
        onlineDriversCount = stats['onlineDrivers'] ?? 0;
        isLoadingDashboard = false;
      });
    } catch (e) {
      setState(() => isLoadingDashboard = false);
      Fluttertoast.showToast(
        msg: 'Failed to load dashboard stats: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
  Future<void> fetchUsers() async {
    try {
      final result = await AdminApiService.fetchAllUsers();
      setState(() {
        users = result;
        filteredUsers = result;
        isLoading = false;
        selectedUsers.clear();
      });
    } catch (e) {
      setState(() => isLoading = false);
      Fluttertoast.showToast(msg: 'Error fetching users: $e');
    }
  }

  Future<void> fetchFeedback() async {
    if (!mounted) return;
    setState(() => isLoadingFeedback = true);
    try {
      final feedback = await AdminApiService.fetchFeedback();
      setState(() {
        feedbackList = feedback;
        isLoadingFeedback = false;
      });
    } catch (e) {
      debugPrint("Feedback fetch failed: $e");
      setState(() => isLoadingFeedback = false);
      // Silently fail so the UI doesn't break for the user
    }
  }

  Future<void> toggleStatus(UserModel user) async {
    try {
      await AdminApiService.toggleUserStatus(user.id!, !user.isBlocked);
      Fluttertoast.showToast(msg: 'User status updated');
      fetchUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating user: $e');
    }
  }

  Future<void> deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminApiService.deleteUser(user.id!);
        Fluttertoast.showToast(msg: 'User deleted');
        fetchUsers();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error deleting user: $e');
      }
    }
  }
  Future<void> _handleAssign(String tripId, String driverId) async {
    try {
      await AdminApiService.assignTrip(tripId, driverId);
      Fluttertoast.showToast(msg: "Trip assigned successfully!");
      _refreshData();
    } catch (e) {
      // This will now show "Rides must be booked at least 30 minutes in advance"
      // or "Driver already has an active trip"
      Fluttertoast.showToast(
        msg: e.toString().replaceAll("Exception:", ""),
        backgroundColor: Colors.red,
      );
    }
  }
  Future<void> _handleCancel(String tripId) async {
    try {
      await AdminApiService.cancelTrip(tripId, "Cancelled by Admin");
      Fluttertoast.showToast(msg: "Trip Cancelled");
      _refreshData();
    } catch (e) {
      Fluttertoast.showToast(msg: "Cancellation failed: $e");
    }
  }

  void _showDispatchDialog(String tripId) {
    // FIND the trip data from your local list to pass into the screen
    final tripData = pendingTrips.firstWhere((t) => t['_id'] == tripId, orElse: () => null);

    if (tripData == null) {
      Fluttertoast.showToast(msg: "Trip data not found");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispatchManagementScreen(
          tripId: tripId,
          rideData: tripData, // Pass the trip map here
        ),
      ),
    ).then((_) {
      // This runs AFTER the screen is closed.
      fetchPendingTrips();
      fetchUsers();
    });
  }
  void showAdminNotify(String message) {
    if (!mounted) return;
    try {
      Fluttertoast.showToast(msg: message);
    } catch (e) {
      // Fallback for macOS Desktop
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }
  void showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Email: ${user.email}"),
              Text("Phone: ${user.phone}"),
              Text("Role: ${user.role}"),
              Text("National ID: ${user.nationalId}"),
              if (user.role.toLowerCase() == 'driver') ...[
                Text("Car Model: ${user.carModel}"),
                Text("Car Number: ${user.carNumber}"),
                Text("Car Type: ${user.carType}"),
                Text("License Number: ${user.licenseNumber}"),
              ],
              Text("Blocked: ${user.isBlocked}"),
            ],
          ),
        );
      },
    );
  }

  void toggleBulkBlock(bool block) async {
    for (var user in selectedUsers) {
      await AdminApiService.toggleUserStatus(user.id!, block);
    }
    Fluttertoast.showToast(msg: block ? 'Users blocked' : 'Users unblocked');
    fetchUsers();
  }

  void deleteSelectedUsers() async {
    for (var user in selectedUsers) {
      await AdminApiService.deleteUser(user.id!);
    }
    Fluttertoast.showToast(msg: 'Users deleted');
    fetchUsers();
  }

  void exportUsersAsCSV() {
    List<List<String>> rows = [
      ["Name", "Email", "Phone", "Role", "National ID", "Blocked"],
      ...selectedUsers.map((u) => [u.name, u.email, u.phone, u.role, u.nationalId ?? '', u.isBlocked.toString()])
    ];
    String csv = const ListToCsvConverter().convert(rows);
    Fluttertoast.showToast(msg: 'CSV Generated. Copy and paste:\n$csv');
  }
// This goes inside your _AdminScreenState
  Widget _buildSquareCard({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell( // Use InkWell for better touch feedback
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Consistent dark slate
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  /// Navigation card to feedback screen
  Widget feedbackNavigationCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/feedback');
      },
      child: Card(
        color: Colors.orange.withOpacity(0.2),
        margin: const EdgeInsets.all(12),
        child: const ListTile(
          leading: Icon(Icons.feedback, color: Colors.white),
          title: Text('User Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Text('Tap to view all user feedback', style: TextStyle(color: Colors.white70)),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = users.length;
    final activeDrivers = users.where((u) => u.role.toLowerCase() == 'driver' && !u.isBlocked).length;
    final activePassengers = users.where((u) => u.role.toLowerCase() == 'rider' && !u.isBlocked).length;
    final blockedUsers = users.where((u) => u.isBlocked).length;
    final pendingBookingsCount = pendingTrips.length;
    return Scaffold(
      backgroundColor: const Color(0xFF0A2647),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),

              children: [
                _buildSquareCard(
                  title: 'Total Users',
                  value: '$totalUsers',
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserListScreen())),
                ),
                _buildSquareCard(
                  title: 'Active Drivers',
                  value: '$activeDrivers',
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverListScreen())),
                ),
                _buildSquareCard(
                  title: 'Active Passengers',
                  value: '$activePassengers',
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassengerListScreen())),
                ),
                _buildSquareCard(
                  title: 'Blocked Users',
                  value: '$blockedUsers',
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUserListScreen())),
                ),
                _buildSquareCard(
                  title: 'User Feedback',
                  value: '${feedbackList.length}',
                  color: Colors.orange, // You can customize this color
                  onTap: () => Navigator.pushNamed(context, '/feedback'),
                ),
                _buildSquareCard(
                  title: 'Pending Bookings',
                  value: '$pendingBookingsCount',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PendingBookingsScreen()),
                  ),
                ),

                _buildSquareCard(
                  title: 'Active Rides',
                  value: '$activeRidesCount',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActiveRidesScreen())
                    ).then((_) => _refreshData()); // Refresh stats when you come back
                  },
                ),

                _buildSquareCard(
                  title: 'Online Drivers',
                  value: '$onlineDriversCount',
                  color: Colors.greenAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverListScreen())),
                ),

              ],
            ),
          ),
          // 2. LIVE MAP – add it here (right after stats)
          // 2. LIVE MAP – add it here (right after stats)
          Container(
            height: 350,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            clipBehavior: Clip.hardEdge,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-1.2921, 36.8219), // Nairobi center
                zoom: 12,
              ),
              // --- UPDATE ONLY THE LINE BELOW ---
              markers: Set<Marker>.of(_driverMarkers.values),
              // ----------------------------------
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                // Optional: controller.setMapStyle(mapStyle);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pending Bookings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200, // Slightly taller to accommodate content
                  child: isLoadingTrips
                      ? const Center(child: CircularProgressIndicator(color: Colors.red))
                      : pendingTrips.isEmpty
                      ? const Center(
                    child: Text(
                      "No pending requests at the moment",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: pendingTrips.length,
                    itemBuilder: (context, index) {
                      final trip = pendingTrips[index];
                      final riderName = trip['riderName'] ?? 'Unknown Rider';
                      final fare = trip['fare'] ?? '0';
                      final vehicle = trip['vehicleType'] ?? 'Standard';
                      final tripId = trip['_id'];

                      return Card(
                        margin: const EdgeInsets.only(right: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: 280,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    vehicle.toString().toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Icon(Icons.notifications_active, size: 16, color: Colors.orange),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Rider: $riderName",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Fare: KES $fare",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _handleCancel(tripId),
                                    child: const Text("Reject", style: TextStyle(color: Colors.red)),
                                  ),
                                  const SizedBox(width: 8),

                                  // ElevatedButton(
                                  //   onPressed: () async {
                                  //     // 1. Accept first — this notifies the rider
                                  //     await AdminApiService.acceptTrip(trip['_id']);
                                  //
                                  //     // 2. Then open dispatch screen
                                  //     Navigator.push(
                                  //       context,
                                  //       MaterialPageRoute(
                                  //         builder: (context) => DispatchManagementScreen(
                                  //           tripId: trip['_id'],
                                  //           rideData: trip,
                                  //         ),
                                  //       ),
                                  //     ).then((_) => _refreshData());
                                  //   },
                                  //   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  //   child: const Text("Dispatch"),
                                  // ),

                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        // ✅ STEP 1: Accept first — moves status: requested → accepted
                                        await AdminApiService.acceptTrip(trip['_id']);

                                        if (!mounted) return;

                                        // ✅ STEP 2: Now open dispatch — assignTrip will find status: "accepted"
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DispatchManagementScreen(
                                              tripId: trip['_id'],
                                              rideData: trip,
                                            ),
                                          ),
                                        ).then((_) => _refreshData());

                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Failed to accept ride: $e"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text("Dispatch"),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // buildFeedbackSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
