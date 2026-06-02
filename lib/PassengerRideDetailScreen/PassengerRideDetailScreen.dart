import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';


class PassengerRideDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rideData;

  const PassengerRideDetailScreen({super.key, required this.rideData});

  @override
  State<PassengerRideDetailScreen> createState() => _PassengerRideDetailScreenState();
}

class _PassengerRideDetailScreenState extends State<PassengerRideDetailScreen> {
  StreamSubscription? _rideSubscription;
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};

  String apiKey = "AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM";
  // Track live changes
  LatLng _driverLocation = const LatLng(0, 0);
  LatLng _pickupLocation = const LatLng(0, 0);
  LatLng _dropoffLocation = const LatLng(0, 0);
  String _currentStatus = "Driver is on the way";
  LatLng? _currentDriverPosition;

  @override
  void initState() {
    super.initState();

    // 1. Initial Setup from backend rideData payload
    _initializeLocations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPolylineRoute();
    });
    // 2. 🔗 THE LINK: Listen for live updates from Socket.io
    // _rideSubscription = SocketService.instance.rideUpdates.listen((data) {
    //   if (!mounted) return;
    //
    //
    //   // ================= STATUS UPDATES =================
    //   if (data.containsKey('lat') && data.containsKey('lng')) {
    //     final newPos = LatLng(
    //       double.parse(data['lat'].toString()),
    //       double.parse(data['lng'].toString()),
    //     );
    //
    //     setState(() {
    //       _driverLocation = newPos;
    //     });
    //
    //     // optional smooth camera follow (no Geolocator needed)
    //     if (_currentDriverPosition == null ||
    //         Geolocator.distanceBetween(
    //           _currentDriverPosition!.latitude,
    //           _currentDriverPosition!.longitude,
    //           newPos.latitude,
    //           newPos.longitude,
    //         ) > 20) {
    //
    //       _mapController?.animateCamera(
    //         CameraUpdate.newLatLng(newPos),
    //       );
    //     }
    //
    //     _currentDriverPosition = newPos;
    //     _currentDriverPosition = newPos;
    //   }
    //
    //   if (data.containsKey('status')) {
    //     setState(() {
    //       _currentStatus = _parseStatus(data['status']);
    //     });
    //   }
    //
    //   // ================= TRIP COMPLETED =================
    //   if (data['type'] == 'completed') {
    //     _showTripCompletedDialog();
    //   }
    //
    //   // ================= TRIP CANCELLED =================
    //   if (data['type'] == 'trip_cancelled') {
    //     setState(() {
    //       _currentStatus = "Trip Cancelled";
    //     });
    //
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text("Trip was cancelled"),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //
    //     Future.delayed(const Duration(seconds: 2), () {
    //       if (mounted) {
    //         Navigator.of(context).popUntil((route) => route.isFirst);
    //       }
    //     });
    //   }
    // });


    _rideSubscription =
        SocketService.instance.rideUpdates.listen((data) {
          if (!mounted) return;

          // ================= LOCATION UPDATES =================
          if (data.containsKey('lat') && data.containsKey('lng')) {
            final newPos = LatLng(
              double.parse(data['lat'].toString()),
              double.parse(data['lng'].toString()),
            );

            setState(() {
              _driverLocation = newPos;
            });

            // smooth camera follow
            if (_currentDriverPosition == null ||
                Geolocator.distanceBetween(
                  _currentDriverPosition!.latitude,
                  _currentDriverPosition!.longitude,
                  newPos.latitude,
                  newPos.longitude,
                ) >
                    20) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(newPos),
              );
            }

            _currentDriverPosition = newPos;
          }

          // ================= STATUS UPDATES =================
          if (data.containsKey('status')) {
            setState(() {
              _currentStatus = _parseStatus(data['status']);
            });
          }

          // ================= TRIP ASSIGNED / DRIVER UPDATE =================
          if (data['type'] == 'driver_assigned' ||
              data['type'] == 'ride_assigned') {
            if (data['driver'] != null) {
              setState(() {
                widget.rideData['driver'] = data['driver'];
              });
            }
          }

          // ================= TRIP STARTED =================
          if (data['type'] == 'trip_started') {
            setState(() {
              _currentStatus = "Trip Started";
            });
          }

          // ================= TRIP COMPLETED (🔥 FIXED) =================
          if (data['type'] == 'completed' ||
              data['type'] == 'trip_completed') {
            final trip = data['trip'];

            setState(() {
              _currentStatus = "Trip Completed";

              // 🔥 CRITICAL FIX: restore driver data from backend
              if (trip != null && trip['driver'] != null) {
                widget.rideData['driver'] = trip['driver'];
              }
            });

            _showTripCompletedDialog();
          }

          // ================= TRIP CANCELLED =================
          if (data['type'] == 'trip_cancelled') {
            setState(() {
              _currentStatus = "Trip Cancelled";
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Trip was cancelled"),
                backgroundColor: Colors.red,
              ),
            );

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }
        });
  }

  void _showTripCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("Trip Completed"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(
                "Pickup",
                widget.rideData['pickupLocation']?['address'] ??
                    "Pickup Location",
              ),

              const SizedBox(height: 10),

              _summaryRow(
                "Dropoff",
                widget.rideData['dropoffLocation']?['address'] ??
                    "Dropoff Location",
              ),

              const SizedBox(height: 10),

              _summaryRow(
                "Fare",
                "KES ${widget.rideData['fare'] ?? 0}",
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  Navigator.of(context).pop();

                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
                child: const Text(
                  "DONE",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$title:",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  void _initializeLocations() {
    final pickup = widget.rideData['pickupLocation'];
    final dropoff = widget.rideData['dropoffLocation'];

    if (pickup != null) {
      _pickupLocation = LatLng(
        double.parse(pickup['lat'].toString()),
        double.parse(pickup['lng'].toString()),
      );
      // Start the map centered on the pickup point until driver moves
      _driverLocation = _pickupLocation;
    }

    if (dropoff != null) {
      _dropoffLocation = LatLng(
        double.parse(dropoff['lat'].toString()),
        double.parse(dropoff['lng'].toString()),
      );
    }
  }

  String _parseStatus(String status) {
    switch (status.toLowerCase()) {

      case 'accepted':
        return "Driver is heading to your location";

      case 'arrived':
        return "Driver has arrived at pickup!";

      case 'started':
        return "Trip in progress... Sit back and relax";

    // optional backup
      case 'in_progress':
        return "Trip in progress... Sit back and relax";

      case 'completed':
        return "You have reached your destination";

      case 'cancelled':
        return "This trip has been cancelled";

      default:
        return "Connecting to driver...";
    }
  }

  void _handleTripCompletion() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  Future<void> _loadPolylineRoute() async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${_pickupLocation.latitude},${_pickupLocation.longitude}"
        "&destination=${_dropoffLocation.latitude},${_dropoffLocation.longitude}"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      final data = jsonDecode(response.body);

      if (data["routes"] == null || data["routes"].isEmpty) {
        return;
      }

      final points =
      data["routes"][0]["overview_polyline"]["points"];

      final decodedPoints =
      PolylinePoints.decodePolyline(points);

      final polylineCoordinates = decodedPoints
          .map((e) => LatLng(e.latitude, e.longitude))
          .toList();

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId("trip_route"),
            points: polylineCoordinates,
            width: 6,
            color: Colors.blue,
            geodesic: true,
          ),
        };
      }

      );
    } catch (e) {
      debugPrint("❌ Polyline error: $e");
    }

    await Future.delayed(const Duration(milliseconds: 500));

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        _pickupLocation.latitude < _dropoffLocation.latitude
            ? _pickupLocation.latitude
            : _dropoffLocation.latitude,
        _pickupLocation.longitude < _dropoffLocation.longitude
            ? _pickupLocation.longitude
            : _dropoffLocation.longitude,
      ),
      northeast: LatLng(
        _pickupLocation.latitude > _dropoffLocation.latitude
            ? _pickupLocation.latitude
            : _dropoffLocation.latitude,
        _pickupLocation.longitude > _dropoffLocation.longitude
            ? _pickupLocation.longitude
            : _dropoffLocation.longitude,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }
  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Backend uses nested "driver" object
    final driver = widget.rideData['driver'] ?? {};
    const Color brandYellow = Color(0xFFFFD60A);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. LIVE MAP
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _driverLocation,
              zoom: 14,
            ),

            onMapCreated: (controller) async {
              _mapController = controller;

              // Auto fit full trip route
              await Future.delayed(const Duration(milliseconds: 500));

              LatLngBounds bounds = LatLngBounds(
                southwest: LatLng(
                  _pickupLocation.latitude < _dropoffLocation.latitude
                      ? _pickupLocation.latitude
                      : _dropoffLocation.latitude,
                  _pickupLocation.longitude < _dropoffLocation.longitude
                      ? _pickupLocation.longitude
                      : _dropoffLocation.longitude,
                ),
                northeast: LatLng(
                  _pickupLocation.latitude > _dropoffLocation.latitude
                      ? _pickupLocation.latitude
                      : _dropoffLocation.latitude,
                  _pickupLocation.longitude > _dropoffLocation.longitude
                      ? _pickupLocation.longitude
                      : _dropoffLocation.longitude,
                ),
              );

              _mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(bounds, 80),
              );
            },

            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,

            // ✅ REAL ROUTE LINE
            polylines: _polylines,

            markers: {
              // DRIVER CAR
              Marker(
                markerId: const MarkerId('driver_car'),
                position: _driverLocation,
                rotation: 0,
                flat: true,
                anchor: const Offset(0.5, 0.5),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow,
                ),
              ),

              // PICKUP
              Marker(
                markerId: const MarkerId('pickup_point'),
                position: _pickupLocation,
                infoWindow: const InfoWindow(
                  title: "Pickup",
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),

              // DROPOFF
              Marker(
                markerId: const MarkerId('dropoff_point'),
                position: _dropoffLocation,
                infoWindow: const InfoWindow(
                  title: "Dropoff",
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
          ),
          // 2. TOP STATUS CARD
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: brandYellow.withOpacity(0.5), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_sharp, color: brandYellow, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _currentStatus.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: brandYellow,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. BOTTOM INFO PANEL
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: brandYellow,
                        child: Icon(Icons.person, color: Colors.black, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['name'] ?? "Sizemore Driver",
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${driver['carModel'] ?? 'Toyota Axio'} • ${driver['carNumber'] ?? 'KDC 123X'}",
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Call Button
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse("tel:${driver['phone']}")),
                        child: const CircleAvatar(
                          radius: 25,
                          backgroundColor: Color(0xFF2E7D32),
                          child: Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Est. Total Fare", style: TextStyle(color: Colors.white38, fontSize: 12)),
                          Text(
                            "KES ${widget.rideData['fare'] ?? '0'}",
                            style: const TextStyle(color: brandYellow, fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                        child: const Text("CASH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
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