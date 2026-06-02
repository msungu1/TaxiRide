// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
//
// class PendingBookingsScreen extends StatefulWidget {
//   const PendingBookingsScreen({super.key});
//
//   @override
//   State<PendingBookingsScreen> createState() => _PendingBookingsScreenState();
// }
//
// class _PendingBookingsScreenState extends State<PendingBookingsScreen> {
//   List<Map<String, dynamic>> _bookings = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchPendingBookings();
//   }
//
//   // Future<void> _fetchPendingBookings() async {
//   //   setState(() => _isLoading = true);
//   //
//   //   try {
//   //     final bookings = await AdminApiService.fetchAllTrips(status: 'requested');
//   //
//   //     setState(() {
//   //       _bookings = bookings.cast<Map<String, dynamic>>();
//   //       _isLoading = false;
//   //     });
//   //   } catch (e) {
//   //     setState(() => _isLoading = false);
//   //     Fluttertoast.showToast(
//   //       msg: "Failed to load pending bookings: $e",
//   //       toastLength: Toast.LENGTH_LONG,
//   //       gravity: ToastGravity.BOTTOM,
//   //       backgroundColor: Colors.red,
//   //       textColor: Colors.white,
//   //     );
//   //   }
//   // }
//   Future<void> _fetchPendingBookings() async {
//     setState(() => _isLoading = true);
//
//     try {
//       // Use the function that hits /api/admin/trips?status=requested
//       final bookings = await AdminApiService.fetchAllTrips(status: 'requested');
//
//       setState(() {
//         // Map the dynamic list to List<Map<String, dynamic>>
//         _bookings = List<Map<String, dynamic>>.from(bookings);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       Fluttertoast.showToast(
//         msg: "Failed to load pending bookings: $e",
//         backgroundColor: Colors.red,
//       );
//     }
//   }
//   Future<void> _handleCancel(String tripId) async {
//     try {
//       await AdminApiService.cancelTrip(tripId, "Cancelled by Admin from Pending List");
//       Fluttertoast.showToast(msg: "Trip Cancelled");
//       _fetchPendingBookings(); // Refresh the list
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Cancellation failed: $e");
//     }
//   }
//   void _dispatchRide(String bookingId) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.85,
//         minChildSize: 0.6,
//         builder: (_, scrollController) => Container(
//           padding: const EdgeInsets.all(20),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: ListView(
//             controller: scrollController,
//             children: [
//               const Text(
//                 "Dispatch Ride",
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Text("Booking ID: $bookingId", style: const TextStyle(fontSize: 16)),
//               const SizedBox(height: 24),
//
//               // Auto-assign option
//               ListTile(
//                 leading: const Icon(Icons.flash_on, color: Colors.orange),
//                 title: const Text("Auto-assign nearest driver"),
//                 subtitle: const Text("System picks closest available driver"),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   try {
//                     // TODO: Replace with real dispatch call (HTTP or socket)
//                     // await AdminApiService.dispatchRide(bookingId: bookingId);
//                     // OR: SocketService().emit('admin_dispatch_ride', {'bookingId': bookingId, 'auto': true});
//                     Fluttertoast.showToast(
//                       msg: "Ride dispatched automatically",
//                       backgroundColor: Colors.green,
//                     );
//                     _fetchPendingBookings(); // Refresh list
//                   } catch (e) {
//                     Fluttertoast.showToast(msg: "Dispatch failed: $e", backgroundColor: Colors.red);
//                   }
//                 },
//               ),
//
//               const Divider(),
//
//               const Text("Or choose manually:", style: TextStyle(fontWeight: FontWeight.w600)),
//
//               // Fake manual drivers (replace with real online drivers list later)
//               ...List.generate(5, (i) => ListTile(
//                 leading: const CircleAvatar(child: Icon(Icons.person)),
//                 title: Text("Driver ${i + 1} - Toyota Premio"),
//                 subtitle: Text("${3 + i}.2 km away • Idle"),
//                 trailing: ElevatedButton(
//                   onPressed: () async {
//                     Navigator.pop(context);
//                     try {
//                       // TODO: Real dispatch
//                       // await AdminApiService.dispatchRide(bookingId: bookingId, driverId: 'drv$i');
//                       // OR socket.emit(...)
//                       Fluttertoast.showToast(
//                         msg: "Assigned to Driver ${i + 1}",
//                         backgroundColor: Colors.green,
//                       );
//                       _fetchPendingBookings();
//                     } catch (e) {
//                       Fluttertoast.showToast(msg: "Assign failed: $e", backgroundColor: Colors.red);
//                     }
//                   },
//                   child: const Text("Assign"),
//                 ),
//               )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A2647),
//       appBar: AppBar(
//         backgroundColor: Colors.red,
//         title: const Text("Pending Bookings"),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchPendingBookings,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.white))
//           : _bookings.isEmpty
//           ? const Center(
//         child: Text(
//           "No pending bookings",
//           style: TextStyle(color: Colors.white70, fontSize: 18),
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: _fetchPendingBookings,
//         color: Colors.red,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: _bookings.length,
//           itemBuilder: (context, index) {
//             final booking = _bookings[index];
//
//             // Adjust these keys to match your actual backend response
//             final pickup = booking['pickupLocation'] ?? 'Tap to see details';
//             final dropoff = booking['dropoffLocation'] ?? '';
//             final passenger = booking['riderName'] ?? 'Unknown Rider';
//             final fare = booking['fare']?.toString() ?? '0';
//             final time = booking['createdAt'] ?? booking['time'] ?? 'N/A';
//             final notes = booking['notes'] ?? '';
//
//             final bookingId = booking['_id'] ?? booking['id'] ?? 'unknown';
//
//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "$pickup → $dropoff",
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     const SizedBox(height: 8),
//                     Text("Passenger: $passenger"),
//                     Text("Fare: Ksh $fare"),
//                     Text("Booked: $time"),
//                     if (notes.isNotEmpty)
//                       Text("Notes: $notes", style: const TextStyle(color: Colors.grey)),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         TextButton(
//                           onPressed: () => _handleCancel(bookingId),
//
//                           child: const Text("Reject", style: TextStyle(color: Colors.red)),
//                         ),
//                         ElevatedButton(
//                           onPressed: () => _dispatchRide(bookingId),
//                           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                           child: const Text("Dispatch"),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
// Import your actual Dispatch screen
import 'package:sizemore_taxi/dispatch/DispatchManagementScreen.dart';

class PendingBookingsScreen extends StatefulWidget {
  const PendingBookingsScreen({super.key});

  @override
  State<PendingBookingsScreen> createState() => _PendingBookingsScreenState();
}

class _PendingBookingsScreenState extends State<PendingBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingBookings();
  }

  Future<void> _fetchPendingBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final bookings = await AdminApiService.fetchAllTrips(status: 'requested');
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(bookings);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Failed to load bookings: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _handleCancel(String tripId) async {
    try {
      await AdminApiService.cancelTrip(tripId, "Cancelled by Admin");
      Fluttertoast.showToast(msg: "Trip Cancelled");
      _fetchPendingBookings();
    } catch (e) {
      Fluttertoast.showToast(msg: "Cancellation failed: $e");
    }
  }

  // 🛠️ REPLACED: Now navigates to DispatchManagementScreen
  void _goToDispatch(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispatchManagementScreen(
          tripId: booking['_id'] ?? booking['id'],
          rideData: booking,
        ),
      ),
    ).then((_) {
      // When the admin returns from Dispatching, refresh the list.
      // Since the trip is now 'assigned', it won't show up in 'requested'.
      _fetchPendingBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2647),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Pending Bookings"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPendingBookings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _bookings.isEmpty
          ? const Center(child: Text("No pending bookings", style: TextStyle(color: Colors.white70, fontSize: 18)))
          : RefreshIndicator(
        onRefresh: _fetchPendingBookings,
        color: Colors.red,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _bookings.length,
          itemBuilder: (context, index) {
            final booking = _bookings[index];
            final bookingId = booking['_id'] ?? booking['id'] ?? 'unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${booking['pickupLocation'] ?? 'N/A'} → ${booking['dropoffLocation'] ?? 'N/A'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(height: 20),
                    Text("Passenger: ${booking['riderName'] ?? 'Unknown'}"),
                    Text("Fare: Ksh ${booking['fare'] ?? '0'}"),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _handleCancel(bookingId),
                          child: const Text("Reject", style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _goToDispatch(booking),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          child: const Text("Dispatch Driver"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}