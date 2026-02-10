import 'package:flutter/material.dart';

class RideRequestPopup extends StatelessWidget {
  final Map<String, dynamic> rideData;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestPopup({
    super.key,
    required this.rideData,
    required this.onAccept,
    required this.onReject,
  });

  // Helper to handle both String addresses or Lat/Lng Maps from backend
  String _getLocationName(dynamic loc) {
    if (loc == null) return "Unknown Location";
    if (loc is String) return loc;
    if (loc is Map) {
      if (loc.containsKey('address')) return loc['address'];
      final lat = loc['lat'];
      final lng = loc['lng'];
      if (lat != null && lng != null) {
        return "Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
      }
    }
    return "Unknown Location";
  }

  @override
  Widget build(BuildContext context) {
    // Extracting data safely based on common backend structures
    final pickup = _getLocationName(rideData['pickupLocation']);
    final dropoff = _getLocationName(rideData['dropoffLocation']);

    // Handle nested fare objects (e.g., { amount: 500, currency: 'KES' })
    dynamic fareData = rideData['fare'];
    String fareDisplay = fareData is Map
        ? "${fareData['amount']} ${fareData['currency']}"
        : fareData.toString();

    final vehicle = rideData['vehicleType'] ?? 'Standard';
    final distance = rideData['distance'] ?? 'Unknown dist';

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing by back button
      child: Material(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_taxi,
                  size: 50,
                  color: Color(0xFFFFD700),
                ),
                const SizedBox(height: 10),
                const Text(
                  "NEW RIDE REQUEST",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Divider(height: 30),

                _buildInfoRow(
                  Icons.directions_car,
                  "Service",
                  vehicle.toUpperCase(),
                ),
                _buildInfoRow(
                  Icons.location_on,
                  "Pickup",
                  pickup,
                  color: Colors.green,
                ),
                _buildInfoRow(
                  Icons.flag,
                  "Dropoff",
                  dropoff,
                  color: Colors.red,
                ),
                _buildInfoRow(Icons.straighten, "Distance", distance),

                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Estimated Fare",
                        style: TextStyle(color: Colors.black54),
                      ),
                      Text(
                        fareDisplay,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "DECLINE",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "ACCEPT",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
