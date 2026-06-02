import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:sizemore_taxi/env_helper.dart';   // ← this is correct
// Import your env helper (adjust path if needed)

class RideStartedScreen extends StatefulWidget {
  const RideStartedScreen({super.key});

  @override
  State<RideStartedScreen> createState() => _RideStartedScreenState();
}

class _RideStartedScreenState extends State<RideStartedScreen> {
  GoogleMapController? _mapController;

  // Replace these with real values from your booking/ride data (e.g. from provider, args, etc.)
  final LatLng _pickup = const LatLng(-1.2921, 36.8219);     // Example: Nairobi CBD
  final LatLng _dropoff = const LatLng(-1.3500, 36.9000);    // Example destination
  LatLng _driverPosition = const LatLng(-1.2800, 36.8100);   // Starting driver pos (live update)

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late final PolylinePoints _polylinePoints;

  Timer? _simulationTimer; // Demo only — replace with socket.io in production

  @override
  void initState() {
    super.initState();

    // Initialize PolylinePoints with API key from your env helper
    // final apiKey = EnvHelper.['AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM'] ?? '';
    final apiKey = EnvHelper.googleMapsKey;
    if (apiKey.isEmpty) {
      debugPrint("ERROR: Google Maps API key is missing from .env");
      // You could show a SnackBar or fallback UI here
    }

    _polylinePoints = PolylinePoints(apiKey: apiKey);

    _initMapAndMarkers();
    _simulateDriverMovement(); // Remove this in real app
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initMapAndMarkers() async {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickup,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoff,
        infoWindow: const InfoWindow(title: 'Dropoff'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverPosition,
        infoWindow: const InfoWindow(title: 'Driver • Ethan Carter'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    await _drawRoutePolyline();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _drawRoutePolyline() async {
    final request = PolylineRequest(
      origin: PointLatLng(_pickup.latitude, _pickup.longitude),
      destination: PointLatLng(_dropoff.latitude, _dropoff.longitude),
      mode: TravelMode.driving,
    );

    final result = await _polylinePoints.getRouteBetweenCoordinates(request: request);

    if (result.points.isNotEmpty) {
      final polyPoints = result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: const Color(0xFFEEDB0B), // your yellow accent
            width: 5,
            points: polyPoints,
            // Optional: dashed pattern
            // patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      });

      // Fit camera to show full route + some padding
      if (_mapController != null) {
        final bounds = _getLatLngBounds([_pickup, _dropoff]);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      }
    } else {
      debugPrint('Route drawing failed: ${result.errorMessage}');
      // You can show a user message here if needed
    }
  }

  LatLngBounds _getLatLngBounds(List<LatLng> points) {
    double south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double west  = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double east  = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  void _simulateDriverMovement() {
    // This is just for demo — in real app use socket.io or Firestore stream
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      setState(() {
        _driverPosition = LatLng(
          _driverPosition.latitude + 0.0008,
          _driverPosition.longitude + 0.0012,
        );

        // Update only driver marker
        _markers.removeWhere((m) => m.markerId.value == 'driver');
        _markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(_driverPosition));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232110),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _driverPosition,
              zoom: 14.5,
            ),
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;

              // Auto-fit route bounds once map is ready
              if (_polylines.isNotEmpty) {
                final bounds = _getLatLngBounds([_pickup, _dropoff]);
                controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
              }
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Trip in progress',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Draggable bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.25,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF232110),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF686331),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Driver info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: const NetworkImage(
                              'https://lh3.googleusercontent.com/...', // ← real driver photo URL
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ethan Carter',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Toyota Camry • KDA 123A',
                                  style: GoogleFonts.notoSans(
                                    color: const Color(0xFFcbc690),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call, color: Color(0xFFEEDB0B)),
                            onPressed: () {
                              // Call driver logic
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Color(0xFF494622), height: 32),

                    // ETA / Progress
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arriving in ~7 min',
                            style: GoogleFonts.notoSans(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 0.65, // ← make dynamic later
                              backgroundColor: const Color(0xFF686331),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFEEDB0B)),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fare
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fare estimate',
                            style: GoogleFonts.notoSans(color: Colors.white),
                          ),
                          Text(
                            'Ksh 1,250',
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              'Chat with Driver',
                              bg: const Color(0xFF494622),
                              textColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              'Emergency',
                              bg: const Color(0xFFEEDB0B),
                              textColor: const Color(0xFF232110),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String text, {required Color bg, required Color textColor}) {
    return ElevatedButton(
      onPressed: () {
        // Add real action (chat, emergency SOS, etc.)
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
      ),
    );
  }
}