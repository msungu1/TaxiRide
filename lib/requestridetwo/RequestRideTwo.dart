import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/waitingscreen/ride_waiting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestRideTwo extends StatefulWidget {
  final dynamic selectedOption;
  final String pickupAddress;
  final String dropoffAddress;
  final dynamic pickupLatLng;
  final dynamic dropoffLatLng;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;

  const RequestRideTwo({
    super.key,
    required this.selectedOption,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLatLng,
    required this.dropoffLatLng,
    required this.scheduledDate,
    required this.scheduledTime,
  });

  @override
  State<RequestRideTwo> createState() => _RequestRideTwoState();
}

class _RequestRideTwoState extends State<RequestRideTwo> {
  bool _isSubmitting = false;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Auto-close after 3 seconds.
        // ✅ FIX: use dialogContext (the context this builder handed us) instead
        // of the outer RequestRideTwo context. _handleConfirmTrip immediately
        // does a pushReplacement right after calling this, which deactivates
        // RequestRideTwo's own context — so by the time this timer fired it was
        // popping through a dead widget tree and crashing with "Looking up a
        // deactivated widget's ancestor is unsafe."
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
        });

        return AlertDialog(
          backgroundColor: const Color(0xFF2e2d1f),
          title: Text("Request Sent", style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          content: Text(
            "Your ride has been posted to drivers. We'll notify you when one accepts.",
            style: GoogleFonts.notoSans(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // just close dialog
              },
              child: const Text("OK", style: TextStyle(color: Color(0xFFEEDB0B))),
            ),
          ],
        );
      },
    );
  }


  Future<void> _handleConfirmTrip(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // 🚀 1. FALLBACK CHECK: If Provider is empty, check SharedPreferences
    String? activeToken = userProvider.token;
    if (activeToken == null || activeToken.isEmpty) {
      debugPrint("⚠️ Provider token empty, checking SharedPreferences...");
      final prefs = await SharedPreferences.getInstance();
      activeToken = prefs.getString('token');
    }

    if (activeToken == null || activeToken.isEmpty) {
      _showErrorSnackBar("Session expired. Please log in again.");
      return;
    }
    final scheduledDateTime = DateTime(
      widget.scheduledDate.year,
      widget.scheduledDate.month,
      widget.scheduledDate.day,
      widget.scheduledTime.hour,
      widget.scheduledTime.minute,
    );

    final now = DateTime.now();
    if (scheduledDateTime.isBefore(now.add(const Duration(minutes: 30)))) {
      _showErrorSnackBar("Rides must be scheduled at least 30 minutes in advance.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final url = Uri.parse('https://sizemoretaxi-itpj.onrender.com/api/trips/confirm');

      // ✅ FIX: Cleaned up the JSON structure and matching backend keys
      final Map<String, dynamic> requestBody = {
        "riderId": userProvider.id,
        "pickup": {
          "lat": widget.pickupLatLng.latitude,
          "lng": widget.pickupLatLng.longitude,
          "address": widget.pickupAddress,
        },
        "dropoff": {
          "lat": widget.dropoffLatLng.latitude,
          "lng": widget.dropoffLatLng.longitude,
          "address": widget.dropoffAddress,
        },
        "vehicleType": widget.selectedOption.id,
        "scheduledTime": scheduledDateTime.toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer ${userProvider.token}',
          'Authorization': 'Bearer $activeToken', // Using the validated token
        },

        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);

        // ✅ FIX: Accessing the ID from your backend's response structure
        // Your backend returns { message: "...", trip: newTrip }
        final tripId = result['trip']?['_id'];

        if (tripId == null) {
          throw Exception("Server confirmed trip but returned no ID.");
        }

        if (mounted) {
          _showSuccessDialog();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideWaitingScreen(tripId: tripId),
            ),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw errorBody['message'] ?? "Error ${response.statusCode}";
      }
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final formattedTime =
        "${widget.scheduledDate.day}/${widget.scheduledDate.month} @ ${widget.scheduledTime.format(context)}";

    return Scaffold(
      backgroundColor: const Color(0xFF1f1e14),
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Confirm Trip',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // --- Rider Info ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEEDB0B),
                    child: Text(
                      userProvider.name != null && userProvider.name!.isNotEmpty
                          ? userProvider.name![0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProvider.name ?? 'Valued Rider',
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userProvider.phone ?? 'No phone number',
                        style: GoogleFonts.notoSans(
                          color: const Color(0xFFbebb9d),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Vehicle Card (Old UI Style) ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2e2d1f),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Image.asset(widget.selectedOption.imagePath, height: 100),
                    const SizedBox(height: 10),
                    Text(
                      widget.selectedOption.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.selectedOption.price,
                      style: const TextStyle(
                        color: Color(0xFFEEDB0B),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Location List ---
            _locationTile(
              icon: Icons.my_location,
              title: 'Pickup',
              subtitle: widget.pickupAddress,
            ),
            _locationTile(
              icon: Icons.location_pin,
              title: 'Dropoff',
              subtitle: widget.dropoffAddress,
            ),

            // --- Trip Details ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _tripDetail('Vehicle Type', widget.selectedOption.id),
                  _tripDetail('Scheduled for', formattedTime),
                  _tripDetail('Estimate', widget.selectedOption.time),
                ],
              ),
            ),

            const Spacer(),

            // --- Confirm Button ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleConfirmTrip(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF1f1e14),
                    backgroundColor: const Color(0xFFEEDB0B),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Confirm & Request Ride',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFEEDB0B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: const Color(0xFFbebb9d),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSans(color: const Color(0xFFbebb9d)),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}