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
import 'package:sizemore_taxi/ProfileScreen/ProfileScreen.dart';

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
  String _tripStage = 'accepted';

  // 🛡️ LOCAL STATE STATE MACHINE
  Map<String, dynamic> localRideData = {};
  Timer? _safetyStatusTimer;
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
      // 🔌 Tell backend this screen is actively viewing this specific trip room context
      if (localRideData['tripId'] != null || localRideData['_id'] != null) {
        final activeTripId = localRideData['tripId'] ?? localRideData['_id'];
        SocketService.instance.socket?.emit('join_trip', {'tripId': activeTripId.toString()});
      }
    });


    _initUnifiedSocketListener();
  }

  void _initUnifiedSocketListener() {
    _rideSubscription = SocketService.instance.rideUpdates.listen((data) {
      if (!mounted || data == null) return;
      debugPrint("📡 Unified Tracking Incoming Event Frame: $data");

      // Extract variations of key names from backend file schemas
      final type = data['type']?.toString();
      final rawStatus = (data['status'] ?? (data['trip'] != null ? data['trip']['status'] : null))?.toString().toLowerCase();

      // ================= 1. LIVE GPS MAP COORDINATION =================
      if (data['lat'] != null && data['lng'] != null) {
        final newPos = LatLng(
          double.parse(data['lat'].toString()),
          double.parse(data['lng'].toString()),
        );

        _driverLocation = newPos;
        _loadPolylineRoute();

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

        if (mounted) setState(() {});
      }
      bool shouldShowCompletionDialog = false;
      // ================= 2. UI & LIFECYCLE STATE CHANGES =================
      setState(() {
        if (data['driver'] != null) {
          localRideData['driver'] = Map<String, dynamic>.from(data['driver']);
        } else if (data['trip'] != null && data['trip']['driver'] != null) {
          localRideData['driver'] = Map<String, dynamic>.from(data['trip']['driver']);
        }

        if (rawStatus != null) {
          _currentStatusMessage = _parseStatus(rawStatus);
          _tripStage = rawStatus;
          _loadPolylineRoute();

          if (rawStatus == 'arrived' && !_arrivalHandled) {
            _arrivalHandled = true;
            _playAlertSound();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🚕 Driver has arrived at your pickup point!"), backgroundColor: Colors.green),
            );
          }
        }

        if ((type == 'trip_started' || rawStatus == 'in_progress' || rawStatus == 'started') && !_tripStartedHandled) {
          _tripStartedHandled = true;
          _currentStatusMessage = "Trip Started... Sit back and relax";
          _playAlertSound();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🛣️ Your trip has started"), backgroundColor: Colors.blue),
          );
        }

        // ✅ BALANCED COMPLETED EVENT CHECKER (Matches Backend Lines 416-424)
        final eventType = data['type']?.toString().toLowerCase() ?? '';
        final statusString = data['status']?.toString().toLowerCase() ?? '';

        final isCompletedEvent =
            eventType.contains('complete') ||
                statusString.contains('complete') ||
                _tripStage == 'completed';
        debugPrint("🔥 COMPLETION EVENT RECEIVED: $data");

        // if (isCompletedEvent && !_tripCompletedHandled) {
        //   _tripCompletedHandled = true;
        //
        //   _currentStatusMessage = "Trip Completed";
        //   _playAlertSound();
        //
        //   // Stop active tracking listeners cleanly
        //   _rideSubscription?.cancel();
        //   _rideSubscription = null;
        //   _safetyStatusTimer?.cancel();
        //
        //   // Extract metrics safely sent from backend schema keys
        //   if (data['fare'] != null) localRideData['fare'] = data['fare'];
        //   if (data['distance'] != null) localRideData['distance'] = data['distance'];
        //
        //   if (mounted) {
        //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(
        //         content: Text("✅ Trip completed successfully"),
        //         backgroundColor: Colors.green,
        //         duration: Duration(seconds: 2),
        //       ),
        //     );
        //   }
        //
        //   // Trigger zero-action dialog popup
        //   _showTripCompletedDialog();
        //   return;
        // }

        if (isCompletedEvent && !_tripCompletedHandled) {
          _tripCompletedHandled = true;

          debugPrint("✅ TRIP COMPLETION EVENT DETECTED");

          _currentStatusMessage = "Trip Completed";

          if (data['fare'] != null) {
            localRideData['fare'] = data['fare'];
          }

          if (data['distance'] != null) {
            localRideData['distance'] = data['distance'];
          }

          _playAlertSound();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Trip completed successfully"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          debugPrint("📦 SHOWING COMPLETION DIALOG");
          // ✅ SHOW DIALOG
          shouldShowCompletionDialog = true;




          return;
        }
        if (type == 'trip_cancelled' || rawStatus == 'cancelled') {
          _currentStatusMessage = "Trip Cancelled";
          _rideSubscription?.cancel();
          _rideSubscription = null;
          _safetyStatusTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trip was cancelled by driver"), backgroundColor: Colors.red),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
          });
        }
      });
      if (shouldShowCompletionDialog && mounted) {
        debugPrint("📦 SHOWING COMPLETION DIALOG");
        _showTripCompletedDialog();
      }
    });
  }
  void _showTripCompletedDialog() {
    final distanceKm = Geolocator.distanceBetween(
      _pickupLocation.latitude,
      _pickupLocation.longitude,
      _dropoffLocation.latitude,
      _dropoffLocation.longitude,
    ) / 1000;

    final startTime = DateTime.tryParse(localRideData['startTime'] ?? '');
    final endTime = DateTime.tryParse(
      localRideData['endTime'] ?? DateTime.now().toIso8601String(),
    );

    final duration = (startTime != null && endTime != null)
        ? "${endTime.difference(startTime).inMinutes} mins"
        : "N/A";

    // ✅ SHOW SUCCESS SNACKBAR IMMEDIATELY
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Trip completed successfully"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    BuildContext? activeDialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {

        activeDialogContext = dialogContext;

        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text(
                "Trip Completed",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Redirecting to home screen...",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _summaryRow(
                "Pickup",
                localRideData['pickupLocation']?['address'] ??
                    "Pickup Location",
              ),

              const SizedBox(height: 6),

              _summaryRow(
                "Dropoff",
                localRideData['dropoffLocation']?['address'] ??
                    "Dropoff Location",
              ),

              const SizedBox(height: 6),

              _summaryRow(
                "Fare",
                "KES ${localRideData['fare'] ?? 0}",
              ),

              const SizedBox(height: 6),

              _summaryRow(
                "Distance",
                "${distanceKm.toStringAsFixed(2)} km",
              ),

              const SizedBox(height: 6),

              _summaryRow(
                "Duration",
                duration,
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      debugPrint("🚀 CLOSING DIALOG");

      // close dialog first
      if (activeDialogContext != null) {
        Navigator.of(activeDialogContext!).pop();
      }      debugPrint("🚀 CLEANING UP");

      await _rideSubscription?.cancel();
      _rideSubscription = null;
      _safetyStatusTimer?.cancel();

      debugPrint("🚀 NAVIGATING TO PROFILE");

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        ),
            (route) => false,
      );
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
      if (localRideData['driver'] != null &&
          localRideData['driver']['currentLocation'] != null) {
        final driverLoc = localRideData['driver']['currentLocation'];
        _driverLocation = LatLng(
          double.parse(driverLoc['lat'].toString()),
          double.parse(driverLoc['lng'].toString()),
        );
      } else {
        _driverLocation = _pickupLocation;
      }
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
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  Widget _summaryRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
      ],
    );
  }

  Future<void> _loadPolylineRoute() async {
    LatLng origin;
    LatLng destination;

    if (_tripStage == 'accepted' || _tripStage == 'arrived') {
      origin = _driverLocation;
      destination = _pickupLocation;
    } else if (_tripStage == 'in_progress' || _tripStage == 'started') {
      origin = _driverLocation;
      destination = _dropoffLocation;
    } else {
      origin = _pickupLocation;
      destination = _dropoffLocation;
    }

    final url = "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
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

      _zoomToFitDynamicRoute(origin, destination);
    } catch (e) {
      debugPrint("❌ Polyline processing error: $e");
    }
  }

  void _zoomToFitDynamicRoute(LatLng origin, LatLng destination) {
    if (_mapController == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude < destination.longitude ? origin.longitude : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
        origin.longitude > destination.longitude ? origin.longitude : destination.longitude,
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
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
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: _driverLocation, zoom: 14),
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 500), () {
                _loadPolylineRoute();
              });
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