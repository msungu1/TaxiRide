import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';

class ActiveRidesScreen extends StatefulWidget {
  const ActiveRidesScreen({super.key});

  @override
  State<ActiveRidesScreen> createState() => _ActiveRidesScreenState();
}

class _ActiveRidesScreenState extends State<ActiveRidesScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveRides();
    _setupSocketListeners();
  }


  void _setupSocketListeners() {
    final socket = SocketService.instance.socket;
    if (socket == null) return;

    // Listen for Trip Completed
    socket.on('trip_completed', (data) {
      debugPrint("🏁 Admin: Ride ${data['tripId']} completed.");
      _removeRideLocally(data['tripId']);
    });

    // Listen for Trip Cancelled
    socket.on('trip_cancelled', (data) {
      debugPrint("🛑 Admin: Ride ${data['tripId']} cancelled.");
      _removeRideLocally(data['tripId']);
    });

    // Listen for status changes (e.g., from 'assigned' to 'ongoing')
    socket.on('status_update', (data) {
      _updateRideStatusLocally(data['tripId'], data['status']);
    });
  }

  // Helper to remove the ride from the list UI
  void _removeRideLocally(String? tripId) {
    if (tripId == null || !mounted) return;
    setState(() {
      _rides.removeWhere((ride) =>
      (ride['_id'] ?? ride['id']).toString() == tripId.toString()
      );
    });
  }

  // Helper to update status (e.g., changing color from orange to green)
  void _updateRideStatusLocally(String? tripId, String? newStatus) {
    if (tripId == null || newStatus == null || !mounted) return;
    setState(() {
      final index = _rides.indexWhere((ride) =>
      (ride['_id'] ?? ride['id']).toString() == tripId.toString()
      );
      if (index != -1) {
        _rides[index]['status'] = newStatus;
      }
    });
  }

  @override
  void dispose() {
    // 2. Clean up listeners so they don't leak memory
    SocketService.instance.socket?.off('trip_completed');
    SocketService.instance.socket?.off('trip_cancelled');
    SocketService.instance.socket?.off('status_update');
    super.dispose();
  }
  Future<void> _fetchActiveRides() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Hits the API for assigned/ongoing trips
      final rides = await AdminApiService.fetchActiveRides();

      setState(() {
        _rides = List<Map<String, dynamic>>.from(rides);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: "Failed to load active rides: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2647),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Active & Assigned Rides"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActiveRides,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _rides.isEmpty
          ? const Center(
        child: Text(
          "No active rides right now",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchActiveRides,
        color: Colors.red,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _rides.length,
          itemBuilder: (context, index) {
            final ride = _rides[index];

            // Consistent mapping with your other screens
            final passenger = ride['riderName'] ?? ride['passengerName'] ?? 'Unknown';
            final driver = ride['driverName'] ?? 'Waiting for driver...';
            final pickup = ride['pickupLocation'] ?? 'N/A';
            final dropoff = ride['dropoffLocation'] ?? 'N/A';
            final status = ride['status'] ?? 'assigned';
            final rideId = ride['_id'] ?? ride['id'] ?? 'unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "$passenger ➔ $driver",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'ongoing' ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text("Pickup: $pickup", style: const TextStyle(fontSize: 13)),
                    Text("Dropoff: $dropoff", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Fare: Ksh ${ride['fare'] ?? '0'}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.location_searching, size: 16),
                          label: const Text("Track"),
                          onPressed: () {
                            Fluttertoast.showToast(msg: "Tracking $rideId");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
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
    );
  }
}