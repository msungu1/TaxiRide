import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// ✅ Double check this path matches your file location
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';

class DriverAvailableTripsScreen extends StatefulWidget {
  const DriverAvailableTripsScreen({super.key});

  @override
  State<DriverAvailableTripsScreen> createState() => _DriverAvailableTripsScreenState();
}



class _DriverAvailableTripsScreenState extends State<DriverAvailableTripsScreen> {
  List<dynamic> _availableTrips = [];
  bool _isAccepting = false;
  bool _isLoading = true;
  String? _activeTripId;

  @override
  void initState() {
    super.initState();
    _fetchInitialTrips();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    // ✅ Cleaned up the syntax error here
    final socket = SocketService.instance.socket;
    socket?.off("ride_requested");
    socket?.off("trip_unavailable");
    super.dispose();
  }

  void _setupSocketListeners() {
    // Use the full class name to ensure Flutter knows we aren't talking about a string
    final dynamic currentSocket = SocketService.instance.socket;

    if (currentSocket == null) {
      debugPrint("⚠️ Socket is null. Check initialization in main.dart");
      return;
    }

    currentSocket.on("ride_requested", (data) {
      if (mounted && data != null) {
        setState(() {
          // Ensure data is treated as a Map
          final Map<String, dynamic> newTrip = Map<String, dynamic>.from(data);
          _availableTrips.insert(0, newTrip);
        });
      }
    });

    currentSocket.on("trip_unavailable", (data) {
      if (mounted && data != null) {
        // Cast the tripId safely to a string
        final String takenTripId = data['tripId'].toString();
        setState(() {
          _availableTrips.removeWhere((trip) => trip['_id'].toString() == takenTripId);
        });
      }
    });
  }

  Future<void> _fetchInitialTrips() async {
    try {
      final response = await http.get(Uri.parse('https://sizemoretaxi-itpj.onrender.com/api/trips/available'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _availableTrips = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptTrip(String tripId) async {
    setState(() => _isAccepting = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final socket = SocketService.instance.socket;

    try {
      final response = await http.post(
        Uri.parse('https://sizemoretaxi-itpj.onrender.com/api/trips/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "driverId": userProvider.id,
          "tripId": tripId,
        }),
      );

      if (!mounted) return;

      setState(() => _isAccepting = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🚕 Prevent duplicate joins
        if (_activeTripId != tripId) {
          _activeTripId = tripId;

          // 1. Join socket room (only once per trip)
          SocketService.instance.joinTripRoom(tripId);

          // 2. Notify backend driver joined
          socket?.emit("driver_joined_trip", {
            "tripId": tripId,
            "driverId": userProvider.id,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip Accepted! Drive safely."),
            backgroundColor: Colors.green,
          ),
        );

        // OPTIONAL: Navigate to active trip screen
        // Navigator.pushReplacement(...)

      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to accept trip")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAccepting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFFFD60A);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Marketplace", style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandYellow))
          : _availableTrips.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _availableTrips.length,
        itemBuilder: (context, index) => _tripRequestCard(_availableTrips[index], brandYellow),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar_rounded, color: Colors.white.withOpacity(0.1), size: 80),
          const SizedBox(height: 16),
          Text("Searching for rides...", style: GoogleFonts.manrope(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _tripRequestCard(dynamic trip, Color yellow) {
    String iconPath = 'assets/icons/comfort.png';
    final type = trip['vehicleType']?.toString() ?? "Car";
    if (type == "Van") iconPath = 'assets/icons/sedan.png';
    if (type == "Premium") iconPath = 'assets/icons/premium-service.png';
    if (type == "Chopper") iconPath = 'assets/icons/chopper.png';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: yellow.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: yellow.withOpacity(0.1), shape: BoxShape.circle),
                child: Image.asset(iconPath, width: 32, height: 32, color: yellow, colorBlendMode: BlendMode.srcIn),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.toUpperCase(), style: GoogleFonts.manrope(color: yellow, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                    Text("New Ride Request", style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Text("KES ${trip['fare']}", style: GoogleFonts.manrope(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          _locationRow(Icons.radio_button_checked, "Pickup", trip['pickupAddress'] ?? "Loading...", yellow),
          const SizedBox(height: 16),
          _locationRow(Icons.location_on, "Dropoff", trip['destinationAddress'] ?? "Loading...", Colors.redAccent),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: yellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _isAccepting ? null : () => _acceptTrip(trip['_id']),
              child: _isAccepting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text("ACCEPT RIDE", style: GoogleFonts.manrope(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.manrope(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(address, style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    );
  }
}