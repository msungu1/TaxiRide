import 'package:flutter/material.dart';

class DriverNotificationsScreen extends StatelessWidget {
  const DriverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with notifications fetched from backend
    final notifications = [
      {"title": "Ride Completed", "body": "You earned Ksh 350 from John Doe", "time": "2 hrs ago"},
      {"title": "Weekly Bonus", "body": "Drive 10 trips this week to earn a bonus!", "time": "Yesterday"},
      {"title": "System Update", "body": "App version 2.1 is now available", "time": "2 days ago"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Colors.blueAccent),
              title: Text(notif["title"]!),
              subtitle: Text(notif["body"]!),
              trailing: Text(
                notif["time"]!,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}
