import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

class DriverActiveTripScreen extends StatefulWidget {
  final Map tripData;

  const DriverActiveTripScreen({super.key, required this.tripData});

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen> {
  GoogleMapController? _mapController;

  late LatLng pickup;
  late LatLng dropoff;
  StreamSubscription<Position>? _positionStream;

  Marker? _driverMarker;
  LatLng? _currentDriverPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String apiKey = "AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM";

  String distanceText = "";
  String durationText = "";
  String pickupAddress = "";
  String dropoffAddress = "";

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();

    final pickupLocation = widget.tripData['pickupLocation'];
    final dropoffLocation = widget.tripData['dropoffLocation'];

    pickup = LatLng(
      _safeDouble(pickupLocation?['lat']),
      _safeDouble(pickupLocation?['lng']),
    );

    dropoff = LatLng(
      _safeDouble(dropoffLocation?['lat']),
      _safeDouble(dropoffLocation?['lng']),
    );
    _loadRoute();
    _startLiveTracking();

    _getAddress(pickup.latitude, pickup.longitude).then((value) {
      setState(() => pickupAddress = value);
    });

    _getAddress(dropoff.latitude, dropoff.longitude).then((value) {
      setState(() => dropoffAddress = value);
    });

    SocketService.instance.socket?.on("ride_assigned", (data) {
      if (!mounted) return;

      setState(() {
        widget.tripData.addAll(data);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚕 New trip assigned"),
          backgroundColor: Colors.green,
        ),
      );

      // refresh map data if pickup/dropoff changed
      if (data['pickup'] != null && data['dropoff'] != null) {
        _loadRoute();
      }
    });
  }

  // ─────────────────────────────
  // GOOGLE DIRECTIONS API ROUTE
  // ─────────────────────────────
  Future<void> _loadRoute() async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${pickup.latitude},${pickup.longitude}"
        "&destination=${dropoff.latitude},${dropoff.longitude}"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print("Directions API error: ${response.body}");
      return;
    }
    final data = json.decode(response.body);

    if (data["routes"] == null || data["routes"].isEmpty) {
      print("No routes found");
      return;
    }

    final route = data["routes"][0];

    setState(() {
      distanceText = route["legs"][0]["distance"]["text"];
      durationText = route["legs"][0]["duration"]["text"];
    });

    final encodedPolyline = route["overview_polyline"]["points"];

    // ✅ FIXED: static call
    final List<PointLatLng> decodedPoints =
    PolylinePoints.decodePolyline(encodedPolyline);

    final List<LatLng> polylineCoordinates = decodedPoints
        .map((e) => LatLng(e.latitude, e.longitude))
        .toList();

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("pickup"),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        Marker(
          markerId: const MarkerId("dropoff"),
          position: dropoff,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      };

      _polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: polylineCoordinates,
        )
      };
    });
  }
  // ─────────────────────────────
  // NAVIGATION
  // ─────────────────────────────
  Future<void> _openNavigation() async {
    final url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1"
          "&destination=${dropoff.latitude},${dropoff.longitude}",
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
  void _updateDriverLivePosition(Position pos) {
    final newPos = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "driver");

      _markers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: newPos,
          rotation: pos.heading,
          flat: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPos),
    );

    SocketService.instance.socket?.emit('driver_location_update', {
      'driverId': widget.tripData['driver']?['_id'] ?? widget.tripData['driver'],
      'tripId': widget.tripData['_id'],
      'lat': pos.latitude,
      'lng': pos.longitude,
      'heading': pos.heading,
      'speed': pos.speed,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  void _startLiveTracking() async {
    LocationSettings settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: settings)
            .listen((Position pos) {
          _updateDriverLivePosition(pos);
        });
  }
  void _callPassenger() async {
    final phone = widget.tripData['riderPhone'];
    if (phone == null) return;

    final url = Uri.parse("tel:$phone");
    await launchUrl(url);
  }

  Future<void> _endTrip() async {
    final tripId = widget.tripData['_id']?.toString() ??
        widget.tripData['tripId']?.toString();    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),

              const SizedBox(height: 15),

              const Text(
                "Trip Summary",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _summaryRow(
                "Pickup",
                pickupAddress.isNotEmpty ? pickupAddress : "Pickup location"
              ),

              _summaryRow(
                "Dropoff",
                dropoffAddress.isNotEmpty ? dropoffAddress : "Dropoff location"
              ),

              _summaryRow("Distance", distanceText),

              _summaryRow("Duration", durationText),

              _summaryRow(
                "Fare",
                "Ksh ${widget.tripData['fare'] ?? 0}",
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "CONFIRM END TRIP",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse("https://sizemoretaxi-itpj.onrender.com/api/trips/complete"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "tripId": tripId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // stop tracking
        await _positionStream?.cancel();

        // notify socket listeners
        SocketService.instance.socket?.emit("trip_completed", {
          "tripId": tripId,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip completed successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // go back to home screen
        Navigator.pop(context, true);

      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to complete trip: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Future<String> _getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        return [
          place.street,
          place.subLocality,
          place.locality
        ].where((e) => e != null && e.isNotEmpty).join(", ");
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
    }

    return "Unknown location";
  }
  Widget _summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickup,
              zoom: 13.5,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (c) => _mapController = c,
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.tripData['rider'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Passenger: ${widget.tripData['rider']['name']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Phone: ${widget.tripData['rider']['phone']}"),
                        const SizedBox(height: 10),
                      ],
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Fare: Ksh ${widget.tripData['fare'] ?? 0}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Distance: $distanceText"),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "ETA: $durationText",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _callPassenger,
                          icon: const Icon(Icons.phone),
                          label: const Text("Call"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openNavigation,
                          icon: const Icon(Icons.navigation),
                          label: const Text("Navigate"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _endTrip,
                      child: const Text("END TRIP"),
                    ),
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