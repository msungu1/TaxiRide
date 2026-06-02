import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RideApiService {
  static const String baseUrl = "https://sizemoretaxi-itpj.onrender.com/api";

  static Future<bool> requestRide({
    required Map<String, dynamic> pickup, // Backend expects an object (lat, lng, address)
    required Map<String, dynamic> dropoff,
    required String scheduledTime,
    required String vehicleType,
    required String riderId,
  }) async {
    // 1. URL FIX: Changed from /request to /confirm to match your updated router
    final Uri url = Uri.parse("$baseUrl/trips/confirm");

    // 2. TOKEN RETRIEVAL: You must send the token for verifyToken middleware to work
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    // final body = jsonEncode({
    //   "pickup": pickup,
    //   "dropoff": dropoff,
    //   "scheduledTime": scheduledTime,
    //   "vehicleType": vehicleType,
    //   "riderId": riderId,
    // });

    final body = jsonEncode({
      "pickup": {
        "address": pickup['address'],
        "lat": pickup['lat'],
        "lng": pickup['lng']
      },
      "dropoff": {
        "address": dropoff['address'],
        "lat": dropoff['lat'],
        "lng": dropoff['lng']
      },


      "vehicleType": vehicleType, // Must be exactly "vehicleType"
      "scheduledTime": scheduledTime,
      "riderId": riderId, // Must be exactly "riderId"
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Crucial for verifyToken
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Trip requested successfully!");
        return true;
      } else {
// This will show you if the "30-minute rule" or "Active trip" rule is blocking you
        final errorData = jsonDecode(response.body);
        print("❌ Request failed: ${errorData['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Connection Error: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getTripOptions({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> dropoff,
    required String scheduledTime,
  }) async {
    final Uri url = Uri.parse("$baseUrl/trips/options");

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final body = jsonEncode({
      "pickup": pickup,
      "dropoff": dropoff,
      "scheduledTime": scheduledTime,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': '$token', // 🚀 Match the standard backend middleware key
          'Authorization': 'Bearer $token', // ✅ This fixes the 401 Unauthorized error
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['options'] ?? []; // Returns the list of cars and prices
      } else {
        print("❌ Failed to fetch options: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to fetch ride options");
      }
    } catch (e) {
      print("❌ Error fetching options: $e");
      throw Exception("Failed to fetch ride options");
    }
  }

}