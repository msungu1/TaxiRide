import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sizemore_taxi/ride_popup/ride_request_popup.dart';

class SocketService {
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  IO.Socket? _socket;
  GlobalKey<NavigatorState>? navigatorKey;
  bool _initialized = false;
  String? _currentUserId;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    debugPrint("📱 SocketService: NavigatorKey linked.");
  }

  // ---------------- INIT ----------------
  void init({
    required String userId,
    required double lat,
    required double lng,
    String role = 'driver',
  }) {
    if (_initialized && _currentUserId == userId && _socket?.connected == true)
      return;

    if (_initialized) disconnect();

    _initialized = true;
    _currentUserId = userId;

    _socket = IO.io(
      'https://sizemoretaxi.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId, 'role': role})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✅ SocketService: Connected as $role. Updating location...');
      sendLocation(lat: lat, lng: lng);
    });

    // This listens for the "ride_requested" event from your backend notifyDriver helper
    _socket!.on('ride_requested', (data) {
      debugPrint("🚨 REAL RIDE REQUEST RECEIVED: $data");
      _showRideRequestPopup(data);
    });

    _socket!.onDisconnect((_) => debugPrint('🔌 SocketService: Disconnected'));
  }

  // ---------------- UI POPUP ----------------
  // ---------------- UI POPUP ----------------
  void _showRideRequestPopup(dynamic data) {
    Future.microtask(() {
      final context = navigatorKey?.currentContext;
      if (context == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RideRequestPopup(
          rideData: Map<String, dynamic>.from(data),
          onAccept: () {
            // FIX: Use 'tripId' because that's what your backend controller sends
            final String? tripId = data['tripId'];

            debugPrint("✅ Emitting accept_ride for Trip: $tripId");
            _socket?.emit('accept_ride', {
              'tripId': tripId,
              'driverId': _currentUserId,
            });
            Navigator.of(context).pop();
          },
          onReject: () => Navigator.of(context).pop(),
        ),
      );
    });
  }

  // ---------------- ACTIONS ----------------
  void sendLocation({required double lat, required double lng}) {
    if (_socket != null && _socket!.connected) {
      // FIX: Add driverId to the payload
      _socket!.emit('driver_location_update', {
        'driverId': _currentUserId,
        'lat': lat,
        'lng': lng,
      });
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
    _currentUserId = null;
    debugPrint('🧹 SocketService: Disconnected and Cleaned');
  }
}
