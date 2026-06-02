import 'package:flutter/material.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';

class DriverAssignmentSheet extends StatefulWidget {
  final String tripId;
  final String vehicleType;

  const DriverAssignmentSheet({
    super.key,
    required this.tripId,
    required this.vehicleType,
  });

  @override
  State<DriverAssignmentSheet> createState() => _DriverAssignmentSheetState();
}

class _DriverAssignmentSheetState extends State<DriverAssignmentSheet> {
  late Future<List<UserModel>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = AdminApiService.getAvailableDrivers(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Assign ${widget.vehicleType} Driver",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _driversFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error.toString().replaceAll('Exception:', '')}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final drivers = snapshot.data ?? [];

                if (drivers.isEmpty) {
                  return const Center(
                    child: Text("No available drivers found for this type."),
                  );
                }

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      title: Text(driver.name ?? "Unknown Driver"),
                      subtitle: Text("${driver.carModel} • ${driver.carNumber}"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _handleAssignment(driver),
                        child: const Text("Assign"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleAssignment(UserModel driver) async {
    try {
      await AdminApiService.assignTrip(widget.tripId, driver.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Trip assigned to ${driver.name}")),
        );
        Navigator.pop(context, true); // Return true to refresh the main list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to assign: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}