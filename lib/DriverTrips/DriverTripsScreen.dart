import 'package:flutter/material.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sizemore_taxi/ridedetail/RideDetailsScreen.dart';

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  List<dynamic> activeRides = [];
  bool isLoading = true;

  // Update this to your computer's IP (e.g., http://192.168.100.10:5000)
  final String baseUrl = "https://your-api-url.com";

  @override
  void initState() {
    super.initState();
    _setupRideListeners();
    _fetchAssignedRides();
  }

  void _setupRideListeners() {
    // Listens for real-time assignments from Admin
    SocketService.instance.socket?.on('ride_assigned', (data) {
      debugPrint("🚀 Socket: New Ride Assigned: $data");
      if (mounted) {
        setState(() {
          // Check if ride already exists in list to avoid duplicates
          bool exists = activeRides.any((r) => r['_id'] == data['_id']);
          if (!exists) {
            activeRides.insert(0, data);
          }
        });

        // Quick snackbar to alert the driver even if they are scrolling
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("New Ride Assigned!"),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _fetchAssignedRides() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final token = prefs.getString('token');

      debugPrint("🔍 Fetching rides for Driver ID: $userId");

      final response = await http.get(
        Uri.parse('$baseUrl/api/trips/assigned/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint("📦 Received ${data.length} rides from server");
        setState(() {
          activeRides = data;
          isLoading = false;
        });
      } else {
        debugPrint("❌ Server Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("🚨 Connection Error: $e");
      setState(() => isLoading = false);
    }
  }

  void _startRide(dynamic ride) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    // 1. Notify the server/rider via Socket
    SocketService.instance.socket?.emit('start_ride', {
      'rideId': ride['_id'],
      'driverId': userId,
    });

    debugPrint("🚩 Starting ride: ${ride['_id']}");

    // 2. Navigate to the Details Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RideDetailsScreen(rideData: ride),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Rides", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssignedRides,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
        onRefresh: _fetchAssignedRides,
        child: activeRides.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: activeRides.length,
          itemBuilder: (context, index) => _buildRideCard(activeRides[index]),
        ),
      ),
    );
  }

  Widget _buildRideCard(dynamic ride) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    "ASSIGNED",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                Text(
                  "Ksh ${ride['fare'] ?? '0'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                ride['riderName'] ?? "Unknown Rider",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Pickup: ${ride['pickupAddress'] ?? 'Loading address...'}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Sleek professional look
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _startRide(ride),
                child: const Text("ACCEPT & START", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_transfer_rounded, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              "No rides assigned yet",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text("Pull down to refresh or wait for Admin"),
          ],
        ),
      ),
    );
  }
}