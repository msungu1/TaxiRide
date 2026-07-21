import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/usermodel/UserModel.dart';
import 'package:sizemore_taxi/reportmodel/ReportModel.dart';
import 'package:sizemore_taxi/feedbackmodel/FeedbackModel.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this is imported
import 'package:sizemore_taxi/RatingModel.dart';

class AdminApiService {

  static const String baseUrl = 'https://sizemoretaxi-itpj.onrender.com';
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
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }


  static Future<void> completeTrip(String tripId) async {
    final response = await _securedRequest(
      method: 'POST',
      path: 'complete', // hits /api/trips/complete
      body: {'tripId': tripId},
    );
    if (response.statusCode != 200) throw _handleError(response);
  }
  static Future<List<UserModel>> getAvailableDrivers(String tripId) async {
    // We use _securedRequest because it already handles the Token and the /api/trips/ path
    final response = await _securedRequest(
      method: 'GET', // Matches your backend router.post
      path: 'available?tripId=$tripId',
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Access the 'data' field from your backend response
      final List list = decoded['data'] ?? [];
      return list.map((item) => UserModel.fromJson(item)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchActiveRides() async {
    final rides = await fetchAllTrips(status: 'assigned,accepted,in_progress');
    return List<Map<String, dynamic>>.from(rides);
  }

  static Future<List<dynamic>> fetchAllTrips({String? status}) async {
    // final path = status != null ? 'trips?status=$status' : 'trips';
    final path = status != null ? 'all?status=$status' : 'all';
    final response = await _securedRequest(method: 'GET', path: path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // FIX: Matches your log key: "trips"
      // return data['trips'] ?? data['data'] ?? [];
      return data['data'] ?? [];
    } else {
      throw _handleError(response);
    }
  }

  static Future<void> assignTrip(String tripId, String driverId) async {
    final response = await _securedRequest(
      method: 'POST',
      path: 'assign',
      body: {'tripId': tripId, 'driverId': driverId},
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<void> cancelTrip(String tripId, String reason) async {
    final response = await _securedRequest(
      method: 'POST',
      path: 'cancel',
      body: {'tripId': tripId, 'reason': reason},
    );
    if (response.statusCode != 200) throw _handleError(response);
  }


  static Future<void> acceptTrip(String tripId) async {
    final response = await _securedRequest(
      method: 'POST',
      path: 'accept', // hits /api/trips/accept
      body: {'tripId': tripId},
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  // --- User Management (Restored & Fixed) ---
  static Future<List<UserModel>> fetchAllUsers() async {
    final response = await _securedRequest(method: 'GET',
        path: 'users');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // FIX: Matches your log key: "users"
      final List userList = data['users'] ?? data['data'] ?? [];
      return userList.map((e) => UserModel.fromJson(e)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<void> updateUser(String userId,
      Map<String, dynamic> updatedData) async {
    final response = await _securedRequest(
      method: 'PATCH',
      path: 'users/$userId',
      body: updatedData,
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<void> toggleUserStatus(String userId, bool isBlocked) async {
    final endpoint = isBlocked
        ? 'users/$userId/disable'
        : 'users/$userId/enable';
    final response = await _securedRequest(method: 'PUT', path: endpoint);
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<void> deleteUser(String userId) async {
    final response = await _securedRequest(
        method: 'DELETE', path: 'users/$userId');
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<void> blockUser(String userId) async =>
      toggleUserStatus(userId, true);

  static Future<void> unblockUser(String userId) async =>
      toggleUserStatus(userId, false);

  // --- Feedback & Reports ---
  static Future<List<ReportModel>> fetchReports() async {
    final response = await _securedRequest(method: 'GET', path: 'reports');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data is List ? data : (data['data'] ??
          data['reports'] ?? []);
      return list.map((e) => ReportModel.fromJson(e)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<List<FeedbackModel>> fetchFeedback() async {
    final response = await _securedRequest(
      method: 'GET',
      path: '',
      overrideBasePath: '/api/feedback/',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data is List ? data : (data['data'] ??
          data['feedback'] ?? []);
      return list.map((f) => FeedbackModel.fromJson(f)).toList();
    } else {
      throw _handleError(response);
    }
  }

  static Future<void> markFeedbackHandled(String feedbackId) async {
    final response = await _securedRequest(
      method: 'PATCH',
      path: '$feedbackId/handle',
      overrideBasePath: '/api/feedback/',
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  static Future<List<RatingModel>> fetchRatings() async {
    final response = await _securedRequest(
      method: 'GET',
      path: '',
      overrideBasePath: '/api/ratings/',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data is List ? data : (data['data'] ?? []);
      return list.map((r) => RatingModel.fromJson(r)).toList();
    } else {
      throw _handleError(response);
    }
  }

  // --- Stats & Active Rides ---
  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    final response = await _securedRequest(
        method: 'GET', path: 'dashboard/stats');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw _handleError(response);
  }

  static Future<List<Map<String, dynamic>>> fetchOnlineDriverLocations() async {
    final response = await _securedRequest(
        method: 'GET', path: 'drivers/online-locations');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw _handleError(response);
    }
  }


  static Future<http.Response> _securedRequest({
    required String method,
    required String path,
    dynamic body,
    String? overrideBasePath, // ✅ new
  }) async {
    final token = await getToken();

    // Switch between Admin and Trip routes automatically
    String subPath = "/api/admin/";


    if (path.contains('available') ||
        path.contains('assign') ||
        path.contains('cancel') ||
        path.contains('accept') || // ✅ add
        path.contains('decline') || // ✅ add
        path.contains('all') || // ✅ add
        path.contains('options') || // ✅ add
        path.contains('confirm') || // ✅ add

    path.contains('complete')) {   // 👈 ADD THIS
    subPath = "/api/trips/";    }

    if (path.contains('feedback')) {
      subPath = "/api/feedback/";
    }
    if (path.contains('ratings')) { // ← ADD THIS NEW BLOCK RIGHT HERE
      subPath = "/api/ratings/";
    }
    // ✅ Explicit override always wins — avoids keyword-guessing bugs
    if (overrideBasePath != null) {
      subPath = overrideBasePath;
    }

    if (token == null) throw Exception('Authentication required');

    final uri = Uri.parse('$baseUrl$subPath$path');

    // UPDATED HEADERS: Added 'Accept' for better Web/CORS compatibility
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      print('📡 Sending $method request to $uri');

      // UPDATED SWITCH: Added jsonEncode(body ?? {}) to prevent null body errors on Web
      final response = await switch (method.toLowerCase()) {
        'get' => http.get(uri, headers: headers),
        'post' =>
            http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
        'put' => http.put(uri, headers: headers, body: jsonEncode(body ?? {})),
        'patch' =>
            http.patch(uri, headers: headers,
                body: jsonEncode(body ?? {})), // ✅ add this
        'delete' => http.delete(uri, headers: headers),
        _ => throw Exception('Invalid Method'),
      }.timeout(_timeout);

      print('✅ Response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 401) {
        await clearToken();
        throw Exception('Session expired');
      }

      return response;
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      // Specifically catch browser/CORS issues on Chrome
      throw Exception('Browser Network Error (CORS or Reachability): $e');
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static Exception _handleError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      return Exception(errorData['message'] ?? 'Status ${response.statusCode}');
    } catch (_) {
      return Exception('API Error ${response.statusCode}');
    }
  }

}