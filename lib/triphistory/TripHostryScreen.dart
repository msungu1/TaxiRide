import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/PassengerRideDetailScreen/PassengerRideDetailScreen.dart';
class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<dynamic> _trips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTripHistory();
  }

  Future<void> _fetchTripHistory() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.id == null || userProvider.id!.isEmpty) {
      setState(() {
        _errorMessage = "No user ID found. Please log in again.";
        _isLoading = false;
      });
      return;
    }

    final url =
        'https://sizemoretaxi-itpj.onrender.com/api/trips/activity?userId=${userProvider.id}&role=rider';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          _trips = jsonResponse['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load trips";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error: $e";
        _isLoading = false;
      });
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
        title: Text(
          'Your Trips',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Note: Removed leading back button because this is a tab in your ProfileScreen
      ),
      body: RefreshIndicator( // Added pull-to-refresh
        onRefresh: _fetchTripHistory,
        color: brandYellow,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: brandYellow))
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white54)))
            : _trips.isEmpty
            ? const Center(child: Text("No trips found", style: TextStyle(color: Colors.white54)))
            : ListView.builder(
          itemCount: _trips.length,
          itemBuilder: (context, index) {
            final trip = _trips[index];
            final String status = trip['status'] ?? 'unknown';

            IconData iconData;
            Color statusColor;

            switch (status.toLowerCase()) {
              case 'completed':
                iconData = Icons.check_circle_rounded;
                statusColor = Colors.greenAccent;
                break;
              case 'cancelled':
                iconData = Icons.cancel_rounded;
                statusColor = Colors.redAccent;
                break;
              case 'dispatched':
              case 'started':
                iconData = Icons.local_taxi_rounded;
                statusColor = brandYellow;
                break;
              default:
                iconData = Icons.history_rounded;
                statusColor = Colors.white38;
            }

            // 2. Wrap item in InkWell for navigation
            return GestureDetector(
              onTap: () {
                // Only navigate if there is driver data available
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PassengerRideDetailScreen(
                      rideData: {
                        'driverName': trip['driverName'] ?? 'Searching...',
                        'driverPhone': trip['driverPhone'] ?? '',
                        'carDetails': trip['carDetails'] ?? 'Taxi',
                        'fare': trip['total']?.toString() ?? '0',
                        'lat': trip['lat'],
                        'lng': trip['lng'],
                        'pickupAddress': trip['pickupAddress'],
                        'destinationAddress': trip['destinationAddress'],
                        'status': trip['status'],
                      },
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: status.toLowerCase() == 'started'
                          ? brandYellow.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05)
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                status.toUpperCase(),
                                style: GoogleFonts.manrope(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              // 3. Added Date indicator
                              Text(
                                _formatDate(trip['createdAt']),
                                style: const TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            trip['pickupAddress'] ?? 'Pickup Location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.0),
                            child: Icon(Icons.arrow_downward, size: 12, color: Colors.white24),
                          ),
                          Text(
                            trip['destinationAddress'] ?? 'Destination',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "KES ${trip['total'] ?? '0'}",
                          style: GoogleFonts.manrope(
                            color: brandYellow,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 12),
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

  // Simple date formatter
  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}";
    } catch (e) {
      return "";
    }
  }
}