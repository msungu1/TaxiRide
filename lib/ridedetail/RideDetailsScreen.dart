import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';

class RideDetailsScreen extends StatefulWidget {

  final dynamic rideData; // Pass driver and trip info here

  const RideDetailsScreen({super.key, this.rideData});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Default coordinates (Central Nairobi) to prevent crashes if data is null
  static const double defaultLat = -1.286389;
  static const double defaultLng = 36.817223;

  @override
  void initState() {
    super.initState();
    _addMarkers();
  }

  // 🛠️ Safety Helper: Ensures we always get a double, never a null
  double _ensureDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  void _addMarkers() {
    // Reach into the nested 'pickupLocation' and 'dropoffLocation' maps
    final pLat = _ensureDouble(widget.rideData['pickupLocation']?['lat']);
    final pLng = _ensureDouble(widget.rideData['pickupLocation']?['lng']);
    final dLat = _ensureDouble(widget.rideData['dropoffLocation']?['lat']);
    final dLng = _ensureDouble(widget.rideData['dropoffLocation']?['lng']);

    setState(() {
      _markers.clear(); // Clear existing to prevent duplicates on rebuild

      if (pLat != 0.0) {
        _markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pLat, pLng),
          infoWindow: InfoWindow(title: widget.rideData['pickupLocation']?['address'] ?? 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }

      if (dLat != 0.0) {
        _markers.add(Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(dLat, dLng),
          infoWindow: InfoWindow(title: widget.rideData['dropoffLocation']?['address'] ?? 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }
    });
  }
  // Open Google Maps app for actual navigation
  Future<void> _openNavigation() async {
    // 1. Correct the variable names to match what you extracted
    final lat = _ensureDouble(widget.rideData['pickupLocation']?['lat']);
    final lng = _ensureDouble(widget.rideData['pickupLocation']?['lng']);

    if (lat == 0.0 || lng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid location coordinates")),
      );
      return;
    }

    // 2. Define URLs for both Mobile and Web
    // 'google.navigation' works on Android/iOS
    // 'https://www.google.com/maps' works on Web
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final String appleMapsUrl = "https://maps.apple.com/?q=$lat,$lng";
    final String nativeIntent = "google.navigation:q=$lat,$lng&mode=d";

    try {
      if (await canLaunchUrl(Uri.parse(nativeIntent))) {
        // Direct intent for Android
        await launchUrl(Uri.parse(nativeIntent));
      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        // Fallback for Web or if Google Maps app isn't installed
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _finishRide() {
    SocketService.instance.socket?.emit('finish_ride', {
      'rideId': widget.rideData['_id'],
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ride Completed! Well done.")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Safely extract coordinates from nested objects
    final pickup = widget.rideData['pickupLocation'];
    final dropoff = widget.rideData['dropoffLocation'];

    final startLat = _ensureDouble(pickup?['lat']);
    final startLng = _ensureDouble(pickup?['lng']);

    // 2. Determine initial position with a fallback
    final initialPosition = LatLng(
        startLat != 0.0 ? startLat : defaultLat,
        startLng != 0.0 ? startLng : defaultLng
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ongoing Ride"),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation_rounded, color: Colors.blue),
            onPressed: _openNavigation,
            tooltip: "Navigate to Pickup",
          )
        ],
      ),
      body: Stack(
        children: [
          // Map fills the background
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false, // Keep UI clean
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // Bottom Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30), // Extra bottom padding for iOS/modern phones
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rider Info Row
                  Row(
                    children: [
                      const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blueGrey,
                          child: Icon(Icons.person, color: Colors.white, size: 30)
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.rideData['riderName'] ?? "Rider",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            // Check if the fare string already contains KES/Ksh to avoid repetition
                            Text("Fare: ${widget.rideData['fare'].toString().contains('KES') ? '' : 'Ksh '}${widget.rideData['fare'] ?? '0'}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      // Call Button
                      CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {
                            final phone = widget.rideData['riderPhone'] ?? "";
                            if (phone.isNotEmpty) launchUrl(Uri.parse("tel:$phone"));
                          },
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(),
                  ),

                  // Destination Preview (Helpful for the driver)
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dropoff?['address'] ?? "No destination address provided",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.support_agent),
                          onPressed: () { /* Add Admin Chat Logic */ },
                          label: const Text("ADMIN"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2, // Make Finish Ride more prominent
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // Changed to black for a premium taxi feel
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _finishRide,
                          child: const Text("FINISH RIDE",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}