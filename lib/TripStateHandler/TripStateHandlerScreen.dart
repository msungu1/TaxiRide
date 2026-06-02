import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/ridedetail/RideDetailsScreen.dart';
import 'package:sizemore_taxi/waitingscreen/ride_waiting_screen.dart';

class TripStateHandlerScreen extends StatefulWidget {
  const TripStateHandlerScreen({super.key});

  @override
  State<TripStateHandlerScreen> createState() => _TripStateHandlerScreenState();
}

class _TripStateHandlerScreenState extends State<TripStateHandlerScreen> {
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkActiveTrip();
  }

  Future<void> _checkActiveTrip() async {
    final userProvider =
    Provider.of<UserProvider>(context, listen: false);

    try {
      final res = await http.get(
        Uri.parse(
          "https://sizemoretaxi-itpj.onrender.com/api/trips/active/${userProvider.id}",
        ),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final trip = data['trip'];

        if (trip == null) {
          _goHome();
          return;
        }

        final status = trip['status'];

        if (!mounted) return;

        switch (status) {
          case "requested":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RideWaitingScreen(tripId: trip['_id']),
              ),
            );
            break;

          case "accepted":
          case "assigned":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RideDetailsScreen(rideData: trip),
              ),
            );
            break;

          case "in_progress":
          case "ongoing":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RideDetailsScreen(rideData: trip),
              ),
            );
            break;

          default:
            _goHome();
        }
      } else {
        _goHome();
      }
    } catch (e) {
      debugPrint("Trip check error: $e");
      _goHome();
    }
  }

  void _goHome() {
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1f1e14),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEEDB0B),
        ),
      ),
    );
  }
}