import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  GlobalKey<NavigatorState>? navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    debugPrint("📱 NavigatorKey connected to SocketService");
  }

  final StreamController<Map<String, dynamic>> _rideUpdateController =
  StreamController<Map<String, dynamic>>.broadcast();
  Map<String, double>? _lastLocation;
  Stream<Map<String, dynamic>> get rideUpdates =>
      _rideUpdateController.stream;

  bool _initialized = false;
  String? _currentUserId;
  String? _role;
  String? _currentTripId;
  // ===================== INIT =====================

  void init({
    required String userId,
    required double lat,
    required double lng,
    String role = 'driver',
  }) {
    if (_initialized && _currentUserId == userId && _socket?.connected == true) {
      debugPrint("Socket already initialized");
      return;
    }

    if (_initialized) disconnect();

    _initialized = true;
    _currentUserId = userId;
    _role = role;

    _socket = IO.io(
      'https://sizemoretaxi-itpj.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId, 'role': role})
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint("✅ Connected as $role");

      _socket!.emit('register', {
        'userId': userId,
        'role': role,
      });

      if (role == 'driver') {
        _socket!.emit('go_online', {'driverId': userId});
      }

      updateLocation(lat, lng);

      _setupListeners();
    });
    _socket!.onReconnect((_) {

      debugPrint("🔄 SOCKET RECONNECTED");

      if (_currentUserId != null) {

        _socket!.emit('register', {
          'userId': _currentUserId,
          'role': _role,
        });

        debugPrint("✅ Re-registered socket");
      }

      // REJOIN ACTIVE TRIP
      if (_currentTripId != null) {

        joinTripRoom(_currentTripId!);

        debugPrint("✅ Rejoined trip room $_currentTripId");
      }
    });
    _socket!.onDisconnect((_) {
      debugPrint("🔌 Disconnected");
    });

    _socket!.onConnectError((e) {
      debugPrint("❌ Connect error: $e");
    });

  }

  // ===================== ROOMS =====================

  void joinTripRoom(String tripId) {
    if (_socket?.connected == true) {
      _currentTripId = tripId;
      _socket!.emit('join_trip', {'tripId': tripId});
      debugPrint("🔗 Joined trip room: $tripId");
    }

  }

  void leaveTripRoom(String tripId) {
    if (_socket?.connected == true) {
      _socket!.emit('leave_trip', {'tripId': tripId});
      debugPrint("✂️ Left trip room: $tripId");
    }
  }

  // ===================== LISTENERS =====================

  void _setupListeners() {
    if (_socket == null) return;

    // ===================== RIDE ASSIGNED (MAIN EVENT) =====================
    _socket!.on('ride_assigned', (data) {
      final tripId = data['tripId'];

      debugPrint("🚕 ride_assigned: $data");

      if (_role == 'rider') {
        _currentTripId = null;
        if (tripId != null) joinTripRoom(tripId);

        _rideUpdateController.add({
          'type': 'ride_assigned',
          'status': 'assigned',
          ...data,
        });
      }

      if (_role == 'driver') {
        _rideUpdateController.add({
          'type': 'new_ride',
          ...data,
        });
      }
    });

    // ===================== CANCEL =====================
    _socket!.on('trip_cancelled', (data) {
      debugPrint("trip_cancelled: $data");

      _rideUpdateController.add({
        'type': 'trip_cancelled',
        'status': 'cancelled',
        ...data,
      });
    });

    // ===================== ACCEPT (ADMIN CONFIRMATION) =====================
    _socket!.on('ride_accepted_by_admin', (data) {
      debugPrint("✅ ride accepted: $data");

      _rideUpdateController.add({
        'type': 'ride_accepted_by_admin',
        'status': 'accepted',
        ...data,
      });
    });
    // ===================== DRIVER ACCEPTED =====================
    _socket!.on('ride_accepted_by_driver', (data) {
      debugPrint("🚕 driver accepted ride: $data");

      _rideUpdateController.add({
        'type': 'ride_accepted_by_driver',
        'status': 'accepted',
        ...data,
      });
    });

    // Listen for driver assigned (from backend after dispatch)
    _socket!.on('driver_assigned', (data) {
      debugPrint("🚕 driver_assigned received: $data");

      if (_role == 'rider') {
        _rideUpdateController.add({
          'type': 'ride_assigned',  // keep type as 'ride_assigned' so RideWaitingScreen works
          'status': 'assigned',
          ...data,
        });
      }
    });
    // ===================== STATUS UPDATES =====================
    _socket!.on('status_update', (data) {
      debugPrint("📡 status_update: $data");

      _rideUpdateController.add({
        'type': 'status_update',
        'status': data['status'],
        ...data,
      });
    });

    // ===================== COMPLETED =====================
    // _socket!.on('trip_completed', (data) {
    //   final tripId = data['tripId'];
    //
    //   debugPrint("🏁 trip_completed: $data");
    //
    //   if (tripId != null) leaveTripRoom(tripId);
    //
    //   _rideUpdateController.add({
    //     'type': 'trip_completed',
    //     'status': 'completed',
    //     ...data,
    //   });
    // });

// ===================== COMPLETED =====================
    _socket!.on('trip_completed', (data) {

      debugPrint("🏁🏁🏁 trip_completed RAW:");
      debugPrint(data.toString());

      final safeData = Map<String, dynamic>.from(data);

      final tripId = safeData['tripId']?.toString();

      if (tripId != null) {
        leaveTripRoom(tripId);
      }

      _currentTripId = null;

      final payload = <String, dynamic>{
        'type': 'trip_completed',
        'status': 'completed',
        ...safeData,
      };

      debugPrint("✅ FINAL COMPLETION PAYLOAD:");
      debugPrint(payload.toString());

      _rideUpdateController.add(payload);
    });

    // ===================== 5. TRIP STARTED =====================
    _socket!.on('trip_started', (data) {
      debugPrint("🚗 trip_started: $data");

      _rideUpdateController.add({
        'type': 'trip_started',
        'status': 'in_progress',
        ...data,
      });
    });

    // ===================== LOCATION =====================
    _socket!.on('driver_location_update', (data) {
      _rideUpdateController.add({
        'type': 'location',
        ...data,
      });
    });
// ===================== 9. RIDE DECLINED =====================
    _socket!.on('ride_declined', (data) {
      debugPrint("ride_declined: $data");

      _rideUpdateController.add({
        'type': 'ride_declined',
        'status': 'cancelled',
        ...data,
      });
    });

    _socket!.on('registered', (data) {
      debugPrint(" Server confirmed registration: $data");
    });

  }
  // ===================== ACTIONS =====================

  void sendRideRequest(Map<String, dynamic> data) {
    _socket?.emit('ride_requested', data);
  }

  void acceptRide(String tripId) {
    _socket?.emit('accept_ride', {
      'tripId': tripId,
      'driverId': _currentUserId,
    });
  }

  void cancelRide(String tripId) {
    _socket?.emit('ride_cancelled', {
      'tripId': tripId,
    });
  }



  // ===================== CLEANUP =====================

  void updateLocation(double lat, double lng) {
    if (_currentTripId == null) return;
    if (_socket?.connected != true) return;

    _lastLocation = {
      'lat': lat,
      'lng': lng,
    };

    _socket!.emit('driver_location_update', {
      'driverId': _currentUserId,
      'tripId': _currentTripId,
      'lat': lat,
      'lng': lng,
    });

    debugPrint("📡 Location sent: $lat, $lng");
  }
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _initialized = false;
    _currentUserId = null;
    _role = null;

    debugPrint("🧹 Socket cleaned");
  }
  void dispose() {

    if (!_rideUpdateController.isClosed) {
      _rideUpdateController.close();
    }  }

}