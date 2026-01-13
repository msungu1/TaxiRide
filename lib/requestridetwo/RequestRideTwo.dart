import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';

class RequestRideTwo extends StatefulWidget {
  final dynamic selectedOption;
  final String pickupAddress;
  final String dropoffAddress;
  final dynamic pickupLatLng; // Expected to be the LatLng class you defined
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2e2d1f),
        title: Text("Request Sent", style: GoogleFonts.spaceGrotesk(color: Colors.white)),
        content: Text(
          "Your ride for ${DateFormat('jm').format(widget.scheduledDate)} has been posted to drivers.",
          style: GoogleFonts.notoSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("GREAT", style: TextStyle(color: Color(0xFFEEDB0B))),
          ),
        ],
      ),
    );
  }
  /// 🚀 Final API call to create the trip
  Future<void> _handleConfirmTrip(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final scheduledDateTime = DateTime(
      widget.scheduledDate.year,
      widget.scheduledDate.month,
      widget.scheduledDate.day,
      widget.scheduledTime.hour,
      widget.scheduledTime.minute,
    );

    setState(() => _isSubmitting = true);

    try {
      // 1. Double check this URL. If your backend uses /api/trips,
      // ensure this matches the router path in your server.js
      final url = Uri.parse('https://sizemoretaxi.onrender.com/api/trips/request');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Force the server to know we want JSON
        },
        body: jsonEncode({
          "riderId": userProvider.id,
          "pickupLocation": {
            "lat": widget.pickupLatLng.latitude,
            "lng": widget.pickupLatLng.longitude,
          },
          "dropoffLocation": {
            "lat": widget.dropoffLatLng.latitude,
            "lng": widget.dropoffLatLng.longitude,
          },
          "vehicleType": widget.selectedOption.id,
          "scheduledTime": scheduledDateTime.toIso8601String(),
        }),
      );

      // 2. Check if the response is actually JSON before parsing
      if (response.headers['content-type']?.contains('application/json') ?? false) {
        final result = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSuccessDialog();
        } else {
          throw result['message'] ?? "Server error: ${response.statusCode}";
        }
      } else {
        // This is where your <!DOCTYPE html> error is currently happening.
        // We catch it here to see what the server is actually saying.
        print("Server returned HTML instead of JSON: ${response.body}");
        throw "Server is currently unavailable or the route is incorrect.";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }



    // try {
    //   final response = await http.post(
    //     Uri.parse('https://sizemoretaxi.onrender.com/api/trips/request'),
    //     headers: {
    //       'Content-Type': 'application/json',
    //       'Accept': 'application/json',
    //     },
    //     body: jsonEncode({
    //       "riderId": userProvider.id,
    //       "pickupLocation": widget.pickupLatLng.toJson(),
    //       "dropoffLocation": widget.dropoffLatLng.toJson(),
    //       "vehicleType": widget.selectedOption.id,
    //       "scheduledTime": scheduledDateTime.toIso8601String(),
    //     }),
    //   );
    //
    //   // --- DEBUGGING START ---
    //   print("Status Code: ${response.statusCode}");
    //
    //   // Check if the response is HTML instead of JSON
    //   if (response.body.contains('<!DOCTYPE html>')) {
    //     print("SERVER ERROR (HTML): ${response.body}");
    //     throw Exception("Server sent back a web page instead of data. Check backend logs.");
    //   }
    //   // --- DEBUGGING END ---
    //
    //   final result = jsonDecode(response.body);
    //
    //   if (response.statusCode == 200 || response.statusCode == 201) {
    //     // Success logic...
    //   } else {
    //     throw Exception(result['message'] ?? "Failed to request ride");
    //   }
    // } catch (e) {
    //   print("Front-end caught error: $e");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
    //   );
    // }
    //
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Formatting the display date/time
    final formattedTime = "${widget.scheduledDate.day}/${widget.scheduledDate.month} @ ${widget.scheduledTime.format(context)}";

    return Scaffold(
      backgroundColor: const Color(0xFF1f1e14),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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

            // Rider Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEEDB0B),
                    child: Text(
                      userProvider.name?[0].toUpperCase() ?? "U",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProvider.name ?? 'Valued Rider',
                        style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        userProvider.phone ?? 'No phone number',
                        style: GoogleFonts.notoSans(color: const Color(0xFFbebb9d), fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Vehicle Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: const Color(0xFF2e2d1f), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Image.asset(widget.selectedOption.imagePath, height: 100),
                    const SizedBox(height: 10),
                    Text(widget.selectedOption.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.selectedOption.price, style: const TextStyle(color: Color(0xFFEEDB0B), fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

            // Location List
            _locationTile(icon: Icons.my_location, title: 'Pickup', subtitle: widget.pickupAddress),
            _locationTile(icon: Icons.location_pin, title: 'Dropoff', subtitle: widget.dropoffAddress),

            // Details
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

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _handleConfirmTrip(context),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF1f1e14),
                    backgroundColor: const Color(0xFFEEDB0B),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Confirm & Request Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationTile({required IconData icon, required String title, required String subtitle}) {
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
                Text(title, style: GoogleFonts.notoSans(fontSize: 12, color: const Color(0xFFbebb9d))),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSans(fontSize: 14, color: Colors.white)),
              ],
            ),
          )
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
          Text(label, style: GoogleFonts.notoSans(color: const Color(0xFFbebb9d))),
          Text(value, style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}