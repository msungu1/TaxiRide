import 'package:flutter/material.dart';

class DriverTripsScreen extends StatelessWidget {
  const DriverTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with trips fetched from backend
    final trips = [
      {"date": "Aug 30, 2025", "fare": 350.0, "rider": "John Doe", "status": "Completed"},
      {"date": "Aug 29, 2025", "fare": 500.0, "rider": "Jane Smith", "status": "Completed"},
      {"date": "Aug 28, 2025", "fare": 200.0, "rider": "Mike Brown", "status": "Cancelled"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Trips"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.local_taxi, color: Colors.blueAccent),
              title: Text("Rider: ${trip["rider"]}"),
              subtitle: Text("${trip["date"]} • Status: ${trip["status"]}"),
              trailing: Text(
                "Ksh ${trip["fare"]}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
