import 'dart:convert';
import 'package:http/http.dart' as http;

class RideApiService {
  static const String baseUrl = "https://your-backend.com/api"; // 🔹 replace with your API

  static Future<bool> requestRide({
    required String from,
    required String to,
    required String dateTime, // send as ISO string
    required String rideType,
  }) async {
    final url = Uri.parse('$baseUrl/rides/request');

    final body = jsonEncode({
      "from": from,
      "to": to,
      "dateTime": dateTime,
      "rideType": rideType,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer YOUR_TOKEN', // if you have auth
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print("Request ride failed: ${response.statusCode} ${response.body}");
      return false;
    }
  }
}
