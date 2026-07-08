import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';

class DispatchManagementScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> rideData;

  const DispatchManagementScreen({
    super.key,
    required this.tripId,
    required this.rideData
  });

  @override
  State<DispatchManagementScreen> createState() => _DispatchManagementScreenState();
}

class _DispatchManagementScreenState extends State<DispatchManagementScreen> {
  List<UserModel> availableDrivers = [];
  Set<Marker> _markers = {};
  bool isLoadingDrivers = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Listen for live location updates from the socket
    SocketService.instance.socket?.on('driver_location_update', (data) {
      if (!mounted) return;

      final String? driverId = data['driverId']?.toString();
      final double? lat = (data['lat'] is int) ? (data['lat'] as int).toDouble() : data['lat'];
      final double? lng = (data['lng'] is int) ? (data['lng'] as int).toDouble() : data['lng'];

      if (driverId != null && lat != null && lng != null) {
        setState(() {
          int index = availableDrivers.indexWhere((d) => d.id == driverId);
          if (index != -1) {
            availableDrivers[index] = availableDrivers[index].copyWith(
              currentLocation: {'lat': lat, 'lng': lng},
            );
            _updateMarkers();
          }
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _fetchAvailableDrivers();
  }

  Future<void> _fetchAvailableDrivers() async {
    try {
      setState(() => isLoadingDrivers = true);
      // Backend returns List<UserModel> now based on your AdminApiService logic
      final List<UserModel> fetchedDrivers = await AdminApiService.getAvailableDrivers(widget.tripId);

      setState(() {
        availableDrivers = fetchedDrivers;
        isLoadingDrivers = false;
      });

      _updateMarkers();
      _fitMapToMarkers();
    } catch (e) {
      debugPrint("Error fetching drivers: $e");
      setState(() => isLoadingDrivers = false);
    }
  }

  void _updateMarkers() {
    final Set<Marker> newMarkers = {};

    // 1. Pickup Marker
    final pickup = widget.rideData['pickupLocation'];
    if (pickup != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          pickup['lat']?.toDouble() ?? 0.0,
          pickup['lng']?.toDouble() ?? 0.0,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "Pickup Point"),
      ));
    }

    // 2. Driver Markers
    for (var driver in availableDrivers) {
      if (driver.currentLocation != null) {
        final dLat = driver.currentLocation!['lat']?.toDouble() ?? 0.0;
        final dLng = driver.currentLocation!['lng']?.toDouble() ?? 0.0;

        newMarkers.add(Marker(
          markerId: MarkerId(driver.id ?? 'unknown'),
          position: LatLng(dLat, dLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
              title: driver.name,
              // FIX: added ?? false for null safety
              snippet: "${driver.carModel} - ${(driver.isOnline ?? false) ? 'Online' : 'Offline'}"
          ),
        ));
      }
    }

    setState(() => _markers = newMarkers);
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }

  String _calculateDistance(Map<String, dynamic>? driverLoc, Map<String, dynamic>? pickupLoc) {
    if (driverLoc == null || pickupLoc == null) return "Distance unknown";
    try {
      double dLat = driverLoc['lat']?.toDouble() ?? 0.0;
      double dLng = driverLoc['lng']?.toDouble() ?? 0.0;
      double pLat = pickupLoc['lat']?.toDouble() ?? 0.0;
      double pLng = pickupLoc['lng']?.toDouble() ?? 0.0;

      double distanceInMeters = Geolocator.distanceBetween(dLat, dLng, pLat, pLng);
      return "${(distanceInMeters / 1000).toStringAsFixed(1)} km away";
    } catch (e) {
      return "Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispatch Center"),
        backgroundColor: Colors.red,
        actions: [IconButton(onPressed: _fetchAvailableDrivers, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.rideData['pickupLocation']?['lat']?.toDouble() ?? -1.2921,
                  widget.rideData['pickupLocation']?['lng']?.toDouble() ?? 36.8219,
                ),
                zoom: 13,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_markers.isNotEmpty) _fitMapToMarkers();
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF0F172A),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("Available Drivers Nearby", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: isLoadingDrivers
                        ? const Center(child: CircularProgressIndicator(color: Colors.red))
                        : availableDrivers.isEmpty
                        ? const Center(child: Text("No drivers found", style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                      itemCount: availableDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = availableDrivers[index];
                        final distance = _calculateDistance(driver.currentLocation, widget.rideData['pickupLocation']);

                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.car_rental, color: Colors.white)),
                            title: Text(driver.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text("$distance • ${driver.carType}", style: const TextStyle(color: Colors.greenAccent)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _confirmDispatch(driver),
                              child: const Text("Assign"),
                            ),
                          ),
                        );
                      },
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

  void _confirmDispatch(UserModel driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Assign Ride", style: TextStyle(color: Colors.white)),
        content: Text("Dispatch this ride to ${driver.name}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Confirm")
          ),
        ],
      ),
    );

    if (confirm == true && driver.id != null) {
      try {
        await AdminApiService.assignTrip(widget.tripId, driver.id!);
        if (mounted) {
          Navigator.pop(context); // Close the dispatch screen
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Assigned to ${driver.name}")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dispatch Error: $e"), backgroundColor: Colors.red));
      }
    }
  }
}