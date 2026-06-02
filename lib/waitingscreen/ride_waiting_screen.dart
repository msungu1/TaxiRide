import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// ✅ Correct Passenger-Facing Imports
import 'package:sizemore_taxi/UserProvider/UserProvider.dart';
import 'package:sizemore_taxi/sockets/sockets_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizemore_taxi/PassengerRideDetailScreen/PassengerRideDetailScreen.dart';

class RideWaitingScreen extends StatefulWidget {
  final String tripId;

  const RideWaitingScreen({super.key, required this.tripId});

  @override
  State<RideWaitingScreen> createState() => _RideWaitingScreenState();
}

class _RideWaitingScreenState extends State<RideWaitingScreen> {
  Timer? _pollingTimer;
  final TextEditingController _cancelReasonController =
  TextEditingController();
  StreamSubscription? _rideSubscription;
  String statusMessage = "Sending request to dispatch...";
  bool isLoading = true;
  bool _hasNavigated = false;
  String? selectedReason;

  final List<String> cancelReasons = [
    "Driver is too far",
    "Waiting time is too long",
    "Changed my mind",
    "Wrong pickup location",
    "Found another ride",
    "Driver asked me to cancel",
    "Other",
  ];
  @override
  void initState() {
    super.initState();
    _initializeWaitingLogic();
    _listenToRideUpdates(); // ✅ ADD THIS
  }

  void _listenToRideUpdates() {
    _rideSubscription = SocketService.instance.rideUpdates.listen((event) {
      final type = event['type'];
      final status = event['status'];

      debugPrint("📡 Ride Update Received: $event");

      if (!mounted) return;

      // ---------------- CANCEL / REJECT ----------------
      if (type == 'trip_cancelled' ||
          type == 'ride_rejected' ||
          type == 'ride_declined' ||
          status == 'cancelled' ||
          status == 'rejected') {

        _pollingTimer?.cancel();

        setState(() {
          isLoading = false;
          statusMessage = event['reason'] ?? "Ride request cancelled";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(event['reason'] ?? "Your ride request was cancelled"),
            backgroundColor: Colors.red,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });

        return;
      }

      // ---------------- 1. ADMIN ACCEPTED (WAITING STATE) ----------------
      if (type == 'ride_accepted_by_admin') {
        _pollingTimer?.cancel();

        setState(() {
          isLoading = true;
          statusMessage = "Ride accepted. Finding a driver nearby...";
        });

        return;
      }

      // ---------------- 2. DRIVER ASSIGNED (NAVIGATE) ----------------
      if (type == 'ride_accepted_by_driver')  {
        _pollingTimer?.cancel();

        if (_hasNavigated) return;
        _hasNavigated = true;

        debugPrint("✅ Driver assigned: navigating to ride screen");

        setState(() {
          isLoading = false;
          statusMessage = "Driver found! starting  your ride...";
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PassengerRideDetailScreen(
                rideData: event,
              ),
            ),
          );
        });

        return;
      }

      // -------- 3. TRIP STARTED (fallback navigate) --------
      if (type == 'trip_started') {       // ✅ added
        _pollingTimer?.cancel();

        if (_hasNavigated) return;
        _hasNavigated = true;

        setState(() {
          isLoading = true;
          statusMessage = "Your trip has started!";
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PassengerRideDetailScreen(rideData: event),
            ),
          );
        });

        return;
      }
      //-------- 5. STATUS UPDATE (driver arrived etc) --------
      if (type == 'status_update') {
      final status = event['status'];

      if (status == 'arrived') {
      setState(() {
      isLoading = true;
      statusMessage = "Your driver has arrived! Head outside.";
      });

      // Optional: vibrate to alert the rider
      HapticFeedback.heavyImpact();
      }

      if (status == 'in_progress') {
      // Driver started trip while rider was still on waiting screen
      // Navigate them to the ride screen
      _pollingTimer?.cancel();
      if (_hasNavigated) return;
      _hasNavigated = true;

      Navigator.pushReplacement(
      context,
      MaterialPageRoute(
      builder: (_) => PassengerRideDetailScreen(rideData: event),
      ),
      );
      }

      return;
      }
      // ---------------- COMPLETED ----------------
      if (type == 'completed' || status == 'completed') {

        _pollingTimer?.cancel();

        setState(() {
          isLoading = false;
          statusMessage = "Ride completed";
        });

        return;
      }
    });
  }
  void _initializeWaitingLogic() {
    // 1. Join the unique trip room so the Admin's signal finds this rider
    // SocketService.instance.socket?.emit('join_room', widget.tripId);
    SocketService.instance.joinTripRoom(widget.tripId);

    // _listenToRideUpdates();
    // 3. Start safety polling
    _startPolling();
  }

  void _navigateToTracking(dynamic data) {
    if (!mounted || data == null) return;
    if (_hasNavigated) return;

    _hasNavigated = true; // 🔒 lock navigation

    _pollingTimer?.cancel();

    setState(() {
      statusMessage = "Driver assigned! Preparing your map...";
      isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PassengerRideDetailScreen(rideData: data),
          ),
        );
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      try {
        final response = await http.get(
          Uri.parse(
            'https://sizemoretaxi-itpj.onrender.com/api/trips/${widget.tripId}',
          ),
          headers: {'Accept': 'application/json'},
        );

        if (response.statusCode != 200) return;

        final result = jsonDecode(response.body);
        final trip = result['data']?['trip'] ?? result['data'] ?? result;
        final status = trip['status'] ?? 'requested';

        if (!mounted) return;

        switch (status) {
          case 'requested':
            setState(() {
              statusMessage = "Searching for available drivers...";
            });
            break;

          case 'accepted':
            setState(() {
              statusMessage = "Driver accepted your request...";
            });
            break;

          case 'assigned':
          case 'in_progress':
          case 'ongoing':
            setState(() {
              statusMessage = "Driver found. Preparing your trip...";
            });

            break;

          case 'completed':
            timer.cancel();

            setState(() {
              isLoading = false;
              statusMessage = "Ride completed";
            });
            break;

          case 'cancelled':
            timer.cancel();

            setState(() {
              isLoading = false;
              statusMessage = "Trip cancelled";
            });
            break;
        }
      } catch (e) {
        debugPrint("Polling error: $e");
      }
    });
  }
  @override
  void dispose() {
    _pollingTimer?.cancel();
    _rideSubscription?.cancel();
    _cancelReasonController.dispose();    // Stop listening to avoid memory leaks or dual-navigation
    // SocketService.instance.socket?.off('ride_assigned');

    super.dispose();
  }
  Future<void> _showCancelDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Drag Handle
                      Center(
                        child: Container(
                          width: 55,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// Title
                      const Text(
                        "Cancel Ride?",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Please select a reason for cancellation.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// Cancel Reasons
                      Column(
                        children: cancelReasons.map((reason) {
                          final isSelected = selectedReason == reason;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedReason = reason;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),

                                  AnimatedSwitcher(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    child: isSelected
                                        ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      key: ValueKey("selected"),
                                    )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      /// Show TextField only for "Other"
                      if (selectedReason == "Other") ...[
                        const SizedBox(height: 10),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: TextField(
                            controller: _cancelReasonController,
                            maxLines: 4,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText:
                              "Tell us more about your cancellation...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                              const EdgeInsets.all(18),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      /// Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text(
                                "Keep Ride",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.black,
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () async {
                                if (selectedReason == null) return;

                                if (selectedReason != "Other") {
                                  _cancelReasonController.text =
                                  selectedReason!;
                                }

                                Navigator.pop(context);

                                await _cancelRide();
                              },
                              child: const Text(
                                "Cancel Ride",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _cancelRide() async {
    _pollingTimer?.cancel();

    final reason = _cancelReasonController.text.trim().isEmpty
        ? "No reason provided"
        : _cancelReasonController.text.trim();

    // SOCKET
    SocketService.instance.cancelRide(widget.tripId);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      await http.post(
        Uri.parse(
          'https://sizemoretaxi-itpj.onrender.com/api/trips/cancel-rider',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "tripId": widget.tripId,
          "reason": reason,
        }),
      );
    } catch (e) {
      debugPrint("Cancel error: $e");
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFEEDB0B);

    return Scaffold(
      backgroundColor: const Color(0xFF1f1e14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(
                      color: brandYellow,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                    ),
                  )
                else
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 70),

                const SizedBox(height: 40),

                Text(
                  statusMessage,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  isLoading
                      ? "The dispatch team is currently selecting a driver for your request."
                      : "The request could not be completed at this time.",
                  style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),



                TextButton(
                  onPressed: () {
                    _showCancelDialog();
                  },
                  child: Text(
                    "Cancel Request",
                    style: GoogleFonts.notoSans(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

            ),
          ),
        ),
      ),
    );
  }
}