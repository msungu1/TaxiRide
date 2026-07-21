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
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../RatingsScreen.dart';
import'../RatingModel.dart';
import 'package:sizemore_taxi/adminuser/admin_colors.dart';
import 'package:sizemore_taxi/adminuser/dashboard_header.dart';



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
  List<RatingModel> ratingsList = [];
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
  final AudioPlayer _emergencyPlayer = AudioPlayer();

  int _lastTripCount = 0;
  bool _isPopupShowing = false;
  StreamSubscription? _socketSub;
  double totalRevenue = 0;
  int completedTripsCount = 0;
  int totalTripsCount = 0;
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
// ---------------- NEW RIDE REQUEST ----------------
      if (type == 'ride_requested') {
        debugPrint("🚕 NEW RIDE REQUEST RECEIVED");
        final riderData = event['rider'] ?? {};
        setState(() {
          pendingTrips.insert(0, {
            '_id': event['tripId'],
            'riderName': event['rider']?['name'] ?? 'Unknown Rider',
            'pickupLocation': event['pickupLocation'],
            'dropoffLocation': event['dropoffLocation'],
            'riderPhone': riderData['phone'] ?? '',   // <-- was missing
            'fare': event['fare'],
            'vehicleType': event['vehicleType'],
          });

          pendingBookingsCount = pendingTrips.length;
        });

        _showRideRequestPopup({
          '_id': event['tripId'],
          'riderName': event['rider']?['name'] ?? 'Unknown Rider',
          'pickupLocation': event['pickupLocation'],
          'dropoffLocation': event['dropoffLocation'],
          'riderPhone': riderData['phone'] ?? '',

          'fare': event['fare'],
          'vehicleType': event['vehicleType'],
        });
      }
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
// ---------------- EMERGENCY ----------------
      if (type == 'admin_emergency_alert') {

      debugPrint("🚨 EMERGENCY EVENT RECEIVED");

      _showEmergencyPopup(event);
      }

      if (type == 'new_feedback') {
        fetchFeedback();
        Fluttertoast.showToast(
          msg: "New feedback from ${event['userName'] ?? 'a user'}",
          backgroundColor: Colors.blue,
        );
      }

    });

    fetchUsers();
    _refreshData();
    fetchDashboardStats();
    fetchPendingTrips();
    fetchFeedback();
    fetchRatings();
    fetchTotalTripsCompleted();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {

      if (mounted) {
        fetchUsers();
        fetchPendingTrips();
        fetchDashboardStats();
        fetchTotalTripsCompleted(); // ADD THIS
      }
    });
  }

  void _updateDriverMarker(Map<String, dynamic> data) {
    final String driverId = data['driverId']?.toString() ?? data['userId']?.toString() ?? 'unknown';
    final double? lat = (data['lat'] as num?)?.toDouble();
    final double? lng = (data['lng'] as num?)?.toDouble();

    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) return;

    setState(() {
      _driverMarkers[MarkerId(driverId)] = Marker(
        markerId: MarkerId(driverId),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        rotation: (data['heading'] as num?)?.toDouble() ?? 0,
        anchor: const Offset(0.5, 0.5),
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
      fetchFeedback(),
      fetchDashboardStats(),
      fetchPendingTrips(),
    ]);
  }

// Update inside _AdminScreenState
  Future<void> fetchRatings() async {
    try {
      final ratings = await AdminApiService.fetchRatings();
      setState(() => ratingsList = ratings);
    } catch (e) {
      debugPrint("Ratings fetch failed: $e");
    }
  }
  int _fetchTripsRequestId = 0;
  Future<void> fetchPendingTrips() async {
    final int requestId = ++_fetchTripsRequestId;
    try {
      // We only want the 'requested' ones for the horizontal list/popups
      final result = await AdminApiService.fetchAllTrips(status: 'requested,pending,accepted');
      debugPrint("RAW FETCH RESULT: ${result.map((t) => {'id': t['_id'], 'status': t['status'], 'vehicleType': t['vehicleType']}).toList()}");

      if (mounted) {

        setState(() {
          pendingTrips = result.where((t) {
            final status = (t['status'] ?? '').toString().toLowerCase();
            final vehicle = (t['vehicleType'] ?? '').toString().toLowerCase();

            if (status == 'accepted') {
              // Only keep accepted trips visible if they're chopper
              // (waiting for manual call / complete)
              return vehicle == 'chopper';
            }
            return true; // pending/requested always shown
          }).toList();

          isLoadingTrips = false;
          filteredTrips = pendingTrips;
        });
      }
    } catch (e) {
      print("Dashboard Trip Fetch Error: $e");
    }
  }
  Future<void> fetchOnlineDriverLocations() async {
    try {
      final drivers = await AdminApiService.fetchOnlineDriverLocations();
      if (!mounted) return;
      setState(() {
        for (final d in drivers) {
          final lat = (d['lat'] as num?)?.toDouble();
          final lng = (d['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final driverId = d['driverId'].toString();
          _driverMarkers[MarkerId(driverId)] = Marker(
            markerId: MarkerId(driverId),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(title: "Driver: ${d['name'] ?? 'Active Driver'}"),
          );
        }
      });
    } catch (e) {
      debugPrint("Online driver locations fetch failed: $e");
    }
  }
  void _showRideRequestPopup(Map<String, dynamic> tripData) {
    if (_isPopupShowing) return;
    _isPopupShowing = true;

    final bool isChopper =
        (tripData['vehicleType'] ?? '').toString().toLowerCase() == 'chopper';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RideRequestPopup(
        rideData: {
          'tripId': tripData['_id'],
          'riderName': tripData['riderName'],
          'pickupLocation': tripData['pickupLocation'],
          'dropoffLocation': tripData['dropoffLocation'],
          'fare': tripData['fare'],
          'vehicleType': tripData['vehicleType'],
        },
        onAccept: () {
          Navigator.pop(context);
          _isPopupShowing = false;

          Future.microtask(() async {
            if (isChopper) {
              try {
                await AdminApiService.acceptTrip(tripData['_id']);
                Fluttertoast.showToast(
                  msg: "Trip accepted. Passenger notified.",
                  backgroundColor: Colors.green,
                );
                _refreshData();
              } catch (e) {
                Fluttertoast.showToast(
                  msg: "Failed to accept: $e",
                  backgroundColor: Colors.red,
                );
              }
            } else {
              _showDispatchDialog(tripData['_id']);
            }
          });
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
        totalRevenue = (stats['totalRevenue'] ?? 0).toDouble();
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
  Future<void> fetchTotalTripsCompleted() async {
    try {
      final result = await AdminApiService.fetchAllTrips(status: 'completed');
      if (mounted) {
        setState(() => totalTripsCount = result.length);
      }
    } catch (e) {
      debugPrint("Total trips fetch failed: $e");
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
  Future<void> _showEmergencyPopup(Map<String, dynamic> data) async {
    if (!mounted) return;

    final driver = data['driver'] as Map<String, dynamic>?;
    final rider = data['rider'] as Map<String, dynamic>?;
    final triggeredBy = data['triggeredBy'] ?? 'unknown';
    final person = triggeredBy == 'driver' ? driver : rider;

    final lat = data['lat'];
    final lng = data['lng'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.red.shade900,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "EMERGENCY ALERT",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Triggered by: ${triggeredBy.toString().toUpperCase()}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Message: ${data['message'] ?? 'N/A'}",
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              if (person != null) ...[
                Text("Name: ${person['name'] ?? 'Unknown'}",
                    style: const TextStyle(color: Colors.white)),
                Text("Phone: ${person['phone'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white)),
                if (person['carModel'] != null)
                  Text("Vehicle: ${person['carModel']} (${person['carNumber'] ?? ''})",
                      style: const TextStyle(color: Colors.white)),
              ] else
                const Text("No user profile attached to this alert",
                    style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              if (lat != null && lng != null)
                Text("Location: $lat, $lng",
                    style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _emergencyPlayer.stop();
                _isPopupShowing = false;
                if (mounted) Navigator.pop(context);
              },
              child: const Text("DISMISS"),
            ),
            if (person != null && person['phone'] != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: person['phone']);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: const Text("CALL", style: TextStyle(color: Colors.red)),
              ),
          ],
        );
      },
    );

    try {
      await _emergencyPlayer.setReleaseMode(ReleaseMode.loop);
      await _emergencyPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint("❌ AUDIO ERROR: $e");
    }
  }
  Future<void> _callPassenger(Map<String, dynamic> trip) async {
    final phone = trip['riderPhone'] ?? trip['phone'] ?? trip['rider']?['phone'];

    if (phone == null || phone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passenger phone number not available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone.toString());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to initiate phone call"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<void> _handleCompleteTrip(String tripId) async {
    try {
      await AdminApiService.completeTrip(tripId);
      Fluttertoast.showToast(msg: "Trip marked as completed");
      _refreshData();
      fetchTotalTripsCompleted();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to complete trip: $e",
        backgroundColor: Colors.red,
      );
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

  Widget _buildPremiumCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                )

              ],
            ),

            const Spacer(),

            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                widthFactor: .75,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )

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

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),

              ],
            ),
          ),

        ],
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
      backgroundColor: AdminColors.background,
      body: SafeArea(
        child: ListView(
          children: [
            const DashboardHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,              shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),

                children: [

                  _buildPremiumCard(
                    title: 'Total Users',
                    value: '$totalUsers',
                    icon: Icons.people_alt_rounded,
                    gradient: const [
                      Color(0xFF3B82F6),
                      Color(0xFF1D4ED8),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserListScreen()),
                    ),
                  ),

                  _buildPremiumCard(
                    title: 'Active Drivers',
                    value: '$activeDrivers',
                    icon: Icons.local_taxi,
                    gradient: const [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverListScreen()),
                    ),
                  ),

                  _buildPremiumCard(
                    title: 'Active Passengers',
                    value: '$activePassengers',
                    icon: Icons.person,
                    gradient: const [
                      Color(0xFFF59E0B),
                      Color(0xFFD97706),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PassengerListScreen()),
                    ),
                  ),

                  _buildPremiumCard(
                    title: 'Blocked Users',
                    value: '$blockedUsers',
                    icon: Icons.block,
                    gradient: const [
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BlockedUserListScreen()),
                    ),
                  ),

                  _buildPremiumCard(
                    title: 'Pending Bookings',
                    value: '$pendingBookingsCount',
                    icon: Icons.pending_actions,
                    gradient: const [
                      Color(0xFF8B5CF6),
                      Color(0xFF7C3AED),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingBookingsScreen()),
                    ),
                  ),
                  _buildPremiumCard(
                    title: 'Total Revenue',
                    value: 'KES ${totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.payments,
                    gradient: const [
                      Color(0xFF16A34A),
                      Color(0xFF15803D),
                    ],
                    onTap: () {
                      // Optional: navigate to a detailed revenue/reports screen later
                    },
                  ),
                  _buildPremiumCard(
                    title: 'Active Rides',
                    value: '$activeRidesCount',
                    icon: Icons.route,
                    gradient: const [
                      Color(0xFF14B8A6),
                      Color(0xFF0F766E),
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActiveRidesScreen()),
                      ).then((_) => _refreshData());
                    },
                  ),

                  _buildPremiumCard(
                    title: 'Online Drivers',
                    value: '$onlineDriversCount',
                    icon: Icons.location_on,
                    gradient: const [
                      Color(0xFF22C55E),
                      Color(0xFF15803D),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverListScreen()),
                    ),
                  ),

                  _buildPremiumCard(
                    title: 'User Feedback',
                    value: '${feedbackList.length}',
                    icon: Icons.feedback,
                    gradient: const [
                      Color(0xFFF97316),
                      Color(0xFFEA580C),
                    ],
                    onTap: () => Navigator.pushNamed(context, '/feedback'),
                  ),

                  _buildPremiumCard(
                    title: 'Driver Ratings',
                    value: '${ratingsList.length}',
                    icon: Icons.star,
                    gradient: const [
                      Color(0xFFEAB308),
                      Color(0xFFCA8A04),
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RatingsScreen()),
                    ),
                  ),
                  _buildAnalyticsCard(
                    icon: Icons.check_circle,
                    title: "Total Trips",
                    value: "$totalTripsCount",
                    color: Colors.indigo,
                  ),



                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(width: 14),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Live Fleet Map",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 4),

                              Text(
                                "Real-time Sizemore driver locations",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),

                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: Colors.green,
                                size: 10,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "LIVE",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )

                      ],
                    ),
                  ),

                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: SizedBox(
                      height: 320,
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(-1.2921, 36.8219),
                          zoom: 12,
                        ),
                        markers: Set<Marker>.of(_driverMarkers.values),
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [

                      const Icon(
                        Icons.pending_actions,
                        color: Colors.orange,
                        size: 24,
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        "Pending Ride Requests",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "$pendingBookingsCount Waiting",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )

                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 370,
                    child: isLoadingTrips
                        ? const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    )
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
                        debugPrint("TRIP DATA: $trip");
                        final riderName = trip['riderName'] ?? trip['rider']?['name'] ?? 'Unknown Rider';
                        final fare = trip['fare'] ?? '0';
                        final vehicle = trip['vehicleType'] ?? 'Standard';
                        final tripId = trip['_id'];
                        final bool isChopper = vehicle.toString().toLowerCase() == 'chopper';

                        return Container(
                          key: ValueKey(tripId),
                          width: 320,
                          margin: const EdgeInsets.only(right: 18),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      vehicle.toString().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.timer, color: Colors.orange, size: 18),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text("Passenger", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(
                                riderName,
                                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              // 👇 NEW: phone number
                              const SizedBox(height: 4),
                              Text(
                                (trip['riderPhone'] ?? trip['rider']?['phone'] ?? 'No phone').toString(),
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),

// 👇 NEW: pickup / dropoff
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.trip_origin, color: Colors.green, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (trip['pickupLabel'] ?? trip['pickupLocation']?['address'] ?? 'Unknown pickup').toString(),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.flag, color: Colors.red, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (trip['dropoffLabel'] ?? trip['dropoffLocation']?['address'] ?? 'Unknown dropoff').toString(),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),


                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Icon(Icons.payments, color: Colors.green, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    "KES $fare",
                                    style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _handleCancel(tripId),
                                      icon: const Icon(Icons.close),
                                      label: const Text("Reject"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: isChopper
                                        ? ElevatedButton.icon(
                                      icon: const Icon(Icons.call),
                                      label: const Text("Call Passenger"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final phone = trip['riderPhone'] ??
                                            trip['phone'] ??
                                            trip['rider']?['phone'];

                                        if (phone == null || phone.toString().isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Passenger phone number not available"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final uri = Uri(scheme: 'tel', path: phone.toString());

                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Unable to initiate phone call"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    )
                                        : ElevatedButton.icon(
                                      icon: const Icon(Icons.local_taxi),
                                      label: const Text("Dispatch"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () async {
                                        try {
                                          await AdminApiService.acceptTrip(tripId);
                                          if (!mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DispatchManagementScreen(
                                                tripId: tripId,
                                                rideData: trip,
                                              ),
                                            ),
                                          ).then((_) => _refreshData());
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.red,
                                              content: Text(e.toString()),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (isChopper) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text("Mark Completed"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () => _handleCompleteTrip(tripId),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      "Live Operations",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount:
                      MediaQuery.of(context).size.width > 900 ? 4 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.3,
                      children: [
                        _buildAnalyticsCard(
                          icon: Icons.local_taxi,
                          title: "Online Drivers",
                          value: "$onlineDriversCount",
                          color: Colors.green,
                        ),
                        _buildAnalyticsCard(
                          icon: Icons.route,
                          title: "Active Trips",
                          value: "$activeRidesCount",
                          color: Colors.blue,
                        ),
                        _buildAnalyticsCard(
                          icon: Icons.pending_actions,
                          title: "Pending Requests",
                          value: "$pendingBookingsCount",
                          color: Colors.orange,
                        ),
                        _buildAnalyticsCard(
                          icon: Icons.people,
                          title: "Passengers",
                          value: "$activePassengers",
                          color: Colors.purple,
                        ),
                        _buildPremiumCard(
                          title: 'Total Trips',
                          value: '$totalTripsCount',
                          icon: Icons.check_circle,
                          gradient: const [
                            Color(0xFF6366F1),
                            Color(0xFF4338CA),
                          ],
                          onTap: () {
                            // Optional: navigate to a completed trips history screen
                          },
                        ),
                      ],
                    ),
                  ),              ],
              ),
            ),
            // buildFeedbackSection(),
          ],
        ),

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
