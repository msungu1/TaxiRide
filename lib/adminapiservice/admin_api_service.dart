import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/reportmodel/ReportModel.dart';
import 'package:sizemore_taxi/feedbackmodel/FeedbackModel.dart';

class AdminApiService {
  static const String baseUrl = 'https://sizemoretaxi.onrender.com';
  static const String _tokenKey = 'adminToken';
  static const Duration _timeout = Duration(seconds: 15);

  // --- Token Management ---
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    print('🔐 Saving token: $token');
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('🔐 Retrieved token: $token');
    return token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🧹 Token cleared');
  }

  // --- Secure Request Helper ---
  static Future<http.Response> _securedRequest({
    required String method,
    required String path,
    dynamic body,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required');
    }

    final uri = Uri.parse('$baseUrl/api/admin/$path');
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    try {
      print('📡 Sending $method request to $uri');
      final response = await switch (method.toLowerCase()) {
        'get' => http.get(uri, headers: headers),
        'post' => http.post(uri, headers: headers, body: jsonEncode(body)),
        'put' => http.put(uri, headers: headers, body: jsonEncode(body)),
        'delete' => http.delete(uri, headers: headers),
        _ => throw Exception('Invalid HTTP method'),
      }.timeout(_timeout);

      print('✅ Response ${response.statusCode}: ${response.body}');

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

  // --- User Management ---
  static Future<List<UserModel>> fetchAllUsers() async {
    final response = await _securedRequest(method: 'GET', path: 'users');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['users'] as List).map((e) => UserModel.fromJson(e)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> updatedData) async {
    final response = await _securedRequest(
      method: 'PUT',
      path: 'users/$userId',
      body: updatedData,
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<void> toggleUserStatus(String userId, bool isBlocked) async {
    final endpoint = isBlocked ? 'users/$userId/disable' : 'users/$userId/enable';
    final response = await _securedRequest(method: 'PUT', path: endpoint);
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<void> deleteUser(String userId) async {
    final response = await _securedRequest(method: 'DELETE', path: 'users/$userId');
    if (response.statusCode != 200) throw _handleError(response);
  }

  // --- Reports ---
  static Future<List<ReportModel>> fetchReports() async {
    final response = await _securedRequest(method: 'GET', path: 'reports');
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => ReportModel.fromJson(e))
          .toList();
    } else {
      throw _handleError(response);
    }
  }

  // --- Feedback ---
  static Future<List<FeedbackModel>> fetchFeedback() async {
    final response = await _securedRequest(method: 'GET', path: 'feedback');
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((f) => FeedbackModel.fromJson(f))
          .toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<void> markFeedbackHandled(String feedbackId) async {
    final response = await _securedRequest(
      method: 'PUT',
      path: 'feedback/$feedbackId/handle',
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  // --- Error Handler ---
  static Exception _handleError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        clearToken();
        return Exception('Session expired. Please login again');
      case 403:
        return Exception('Permission denied');
      case 404:
        return Exception('Resource not found');
      case 500:
        return Exception('Server error: ${response.body}');
      default:
        return Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }
  static Future<void> blockUser(String userId) async {
    final response = await _securedRequest(
      method: 'PUT',
      path: 'users/$userId/disable',
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<void> unblockUser(String userId) async {
    final response = await _securedRequest(
      method: 'PUT',
      path: 'users/$userId/enable',
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

}
