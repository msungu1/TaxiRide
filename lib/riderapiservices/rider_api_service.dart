import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';

class RiderApiService {
  static const String baseUrl = 'https://sizemoretaxi.onrender.com';
  static const String _tokenKey = 'riderToken';
  static const Duration _timeout = Duration(seconds: 15);

  // Save token after login
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<http.Response> _securedRequest({
    required String method,
    required String path,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required');
    }

    final uri = Uri.parse('$baseUrl/api/rider/$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await switch (method.toLowerCase()) {
        'get' => http.get(uri, headers: headers),
        _ => throw Exception('Invalid HTTP method'),
      }.timeout(_timeout);

      if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Session expired. Please login again');
      }

      return response;
    } on TimeoutException {
      throw Exception('Request timeout');
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  // Fetch rider profile
  static Future<UserModel> fetchProfile() async {
    final response = await _securedRequest(method: 'GET', path: 'profile');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']); // depends on backend JSON
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }
}
