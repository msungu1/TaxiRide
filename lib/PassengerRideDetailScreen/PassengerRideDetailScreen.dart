import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

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

  // 🛡️ LOCAL STATE STATE MACHINE
  Map<String, dynamic> localRideData = {};
  Timer? _safetyStatusTimer; // 👈 ADD THIS LINE HERE
  String _currentStatusMessage = "Driver is on the way";
  final AudioPlayer _audioPlayer = AudioPlayer();

  final String apiKey = "AIzaSyDraWkg1uWEzstuOOIsWWedooG6Xq-RctM";
  LatLng _driverLocation = const LatLng(0, 0);
  LatLng _pickupLocation = const LatLng(0, 0);
  LatLng _dropoffLocation = const LatLng(0, 0);
  LatLng? _lastAnimatedDriverPosition;
  bool _arrivalHandled = false;
  bool _tripStartedHandled = false;
  bool _tripCompletedHandled = false;

  @override
  void initState() {
    super.initState();

    // Create a local, safely modifiable copy of initial payload data
    localRideData = Map<String, dynamic>.from(widget.rideData);

    _initializeLocations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPolylineRoute();
    });

    _initUnifiedSocketListener();
  }


  void _initUnifiedSocketListener() {
    _rideSubscription = SocketService.instance.rideUpdates.listen((data) {
      if (!mounted || data == null) return;
      debugPrint("📡 Unified Tracking Incoming Event Frame: $data");

      // Extract type and status flags safely across varying payload nested structures
      final type = data['type']?.toString();
      final rawStatus = (data['status'] ?? (data['trip'] != null ? data['trip']['status'] : null))?.toString().toLowerCase();

      // ================= 1. LIVE GPS MAP COORDINATION (Run outside setState to avoid lagging map animations) =================
      if (data['lat'] != null && data['lng'] != null) {
        final newPos = LatLng(
          double.parse(data['lat'].toString()),
          double.parse(data['lng'].toString()),
        );

        _driverLocation = newPos;

        // Smooth camera interpolation tracking threshold
        if (_lastAnimatedDriverPosition == null ||
            Geolocator.distanceBetween(
              _lastAnimatedDriverPosition!.latitude,
              _lastAnimatedDriverPosition!.longitude,
              newPos.latitude,
              newPos.longitude,
            ) > 15) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
          _lastAnimatedDriverPosition = newPos;
        }

        // Update driver car marker on the map frame
        if (mounted) {
          setState(() {});
        }
      }

      // ================= 2. UI & LIFECYCLE STATE CHANGES =================
      setState(() {
        // Capture driver profile structure if sent dynamically in payload chunks
        // if (data['driver'] != null) {
        //   localRideData['driver'] = data['driver'];
        // } else if (data['trip'] != null && data['trip']['driver'] != null) {
        //   localRideData['driver'] = data['trip']['driver'];
        // }
        if (data['driver'] != null) {
          localRideData['driver'] =
          Map<String, dynamic>.from(data['driver']);
        } else if (data['trip'] != null &&
            data['trip']['driver'] != null) {
          localRideData['driver'] =
          Map<String, dynamic>.from(data['trip']['driver']);
        }

        // Handle backend status string changes
        if (rawStatus != null) {
          _currentStatusMessage = _parseStatus(rawStatus);


          if (rawStatus == 'arrived' && !_arrivalHandled) {

            _arrivalHandled = true;

            _playAlertSound();

            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("🚕 Driver has arrived at your pickup point!"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }

        // if (type == 'trip_started' || rawStatus == 'in_progress') {
        //   _currentStatusMessage = "Trip Started... Sit back and relax";
        // }

        if ((type == 'trip_started' ||
            rawStatus == 'in_progress' ||
            rawStatus == 'started') &&
            !_tripStartedHandled) {

          _tripStartedHandled = true;

          _currentStatusMessage = "Trip Started... Sit back and relax";

          _playAlertSound();

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🛣️ Your trip has started"),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
        }

        final eventType = data['type']?.toString();
        final status = data['status']?.toString();

        final isCompletedEvent =
            (eventType?.toLowerCase().contains('complete') ?? false) ||
                (status?.toLowerCase().contains('complete') ?? false);

        if (isCompletedEvent && !_tripCompletedHandled) {
          _tripCompletedHandled = true;

          _currentStatusMessage = "Trip Completed";

          _playAlertSound();

          // Stop listening to socket updates (NO await needed)
          _rideSubscription?.cancel();
          _rideSubscription = null;

          _safetyStatusTimer?.cancel();

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Trip completed successfully"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }

          // Small delay for smooth UX
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _showTripCompletedDialog();
            }
          });

          return;
        }

        if (type == 'trip_cancelled' || rawStatus == 'cancelled') {
          _currentStatusMessage = "Trip Cancelled";

          _rideSubscription?.cancel();
          _rideSubscription = null;
          _safetyStatusTimer?.cancel();

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Trip was cancelled by driver"),
                backgroundColor: Colors.red
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      });
    });
  }
  void _initializeLocations() {
    final pickup = localRideData['pickupLocation'];
    final dropoff = localRideData['dropoffLocation'];

    if (pickup != null) {
      _pickupLocation = LatLng(
        double.parse(pickup['lat'].toString()),
        double.parse(pickup['lng'].toString()),
      );
      _driverLocation = _pickupLocation; // Initial map center default fallback
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
      case 'in_progress':
      case 'ongoing':
        return "Trip in progress... Sit back and relax";
      case 'completed':
        return "You have reached your destination";
      case 'cancelled':
        return "This trip has been cancelled";
      default:
        return "Connecting to driver...";
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await _audioPlayer.stop(); // prevent overlap
      await _audioPlayer.play(
        AssetSource('sounds/alert.mp3'),
      );
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }
  void _showTripCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              _summaryRow("Pickup", localRideData['pickupLocation']?['address'] ?? "Pickup Location"),
              const SizedBox(height: 10),
              _summaryRow("Dropoff", localRideData['dropoffLocation']?['address'] ?? "Dropoff Location"),
              const SizedBox(height: 10),
              _summaryRow("Fare", "KES ${localRideData['fare'] ?? 0}"),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("DONE", style: TextStyle(color: Colors.white)),
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
        SizedBox(width: 80, child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value)),
      ],
    );
  }

  Future<void> _loadPolylineRoute() async {
    final url = "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${_pickupLocation.latitude},${_pickupLocation.longitude}"
        "&destination=${_dropoffLocation.latitude},${_dropoffLocation.longitude}"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data["routes"] == null || data["routes"].isEmpty) return;

      final points = data["routes"][0]["overview_polyline"]["points"];
      final decodedPoints = PolylinePoints.decodePolyline(points);
      final polylineCoordinates = decodedPoints.map((e) => LatLng(e.latitude, e.longitude)).toList();

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
      });

      _zoomToFitRoute();
    } catch (e) {
      debugPrint("❌ Polyline processing error: $e");
    }
  }

  void _zoomToFitRoute() {
    if (_mapController == null) return;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        _pickupLocation.latitude < _dropoffLocation.latitude ? _pickupLocation.latitude : _dropoffLocation.latitude,
        _pickupLocation.longitude < _dropoffLocation.longitude ? _pickupLocation.longitude : _dropoffLocation.longitude,
      ),
      northeast: LatLng(
        _pickupLocation.latitude > _dropoffLocation.latitude ? _pickupLocation.latitude : _dropoffLocation.latitude,
        _pickupLocation.longitude > _dropoffLocation.longitude ? _pickupLocation.longitude : _dropoffLocation.longitude,
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _safetyStatusTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = localRideData['driver'] ?? {};
    const Color brandYellow = Color(0xFFFFD60A);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. STATIC INITIALIZED MAP LAYER
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: _driverLocation, zoom: 14),
            onMapCreated: (controller) {
              _mapController = controller;
              _zoomToFitRoute();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            polylines: _polylines,
            markers: {
              Marker(
                markerId: const MarkerId('driver_car'),
                position: _driverLocation,
                flat: true,
                anchor: const Offset(0.5, 0.5),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
              ),
              Marker(
                markerId: const MarkerId('pickup_point'),
                position: _pickupLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: const MarkerId('dropoff_point'),
                position: _dropoffLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
          ),

          // 2. TOP PANEL (DYNAMIC RE-RENDERING IN-PLACE)
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
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_sharp, color: brandYellow, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _currentStatusMessage.toUpperCase(),
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

          // 3. BOTTOM PANEL
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
                      GestureDetector(
                        onTap: () {
                          if (driver['phone'] != null) {
                            launchUrl(Uri.parse("tel:${driver['phone']}"));
                          }
                        },
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
                            "KES ${localRideData['fare'] ?? '0'}",
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