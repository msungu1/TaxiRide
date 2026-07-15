//
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
// // Import your actual Dispatch screen
// import 'package:sizemore_taxi/dispatch/DispatchManagementScreen.dart';
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
//   Future<void> _fetchPendingBookings() async {
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//
//     try {
//       final bookings = await AdminApiService.fetchAllTrips(status: 'requested');
//       setState(() {
//         _bookings = List<Map<String, dynamic>>.from(bookings);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       Fluttertoast.showToast(msg: "Failed to load bookings: $e", backgroundColor: Colors.red);
//     }
//   }
//
//   Future<void> _handleCancel(String tripId) async {
//     try {
//       await AdminApiService.cancelTrip(tripId, "Cancelled by Admin");
//       Fluttertoast.showToast(msg: "Trip Cancelled");
//       _fetchPendingBookings();
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Cancellation failed: $e");
//     }
//   }
//
//   // 🛠️ REPLACED: Now navigates to DispatchManagementScreen
//   void _goToDispatch(Map<String, dynamic> booking) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DispatchManagementScreen(
//           tripId: booking['_id'] ?? booking['id'],
//           rideData: booking,
//         ),
//       ),
//     ).then((_) {
//       // When the admin returns from Dispatching, refresh the list.
//       // Since the trip is now 'assigned', it won't show up in 'requested'.
//       _fetchPendingBookings();
//     });
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
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPendingBookings),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.white))
//           : _bookings.isEmpty
//           ? const Center(child: Text("No pending bookings", style: TextStyle(color: Colors.white70, fontSize: 18)))
//           : RefreshIndicator(
//         onRefresh: _fetchPendingBookings,
//         color: Colors.red,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: _bookings.length,
//           itemBuilder: (context, index) {
//             final booking = _bookings[index];
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
//                       "${booking['pickupLocation'] ?? 'N/A'} → ${booking['dropoffLocation'] ?? 'N/A'}",
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     const Divider(height: 20),
//                     Text("Passenger: ${booking['riderName'] ?? 'Unknown'}"),
//                     Text("Fare: Ksh ${booking['fare'] ?? '0'}"),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         TextButton(
//                           onPressed: () => _handleCancel(bookingId),
//                           child: const Text("Reject", style: TextStyle(color: Colors.red)),
//                         ),
//                         const SizedBox(width: 8),
//                         ElevatedButton(
//                           onPressed: () => _goToDispatch(booking),
//                           style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
//                           ),
//                           child: const Text("Dispatch Driver"),
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
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
// import 'package:sizemore_taxi/dispatch/DispatchManagementScreen.dart';
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
//   Future<void> _fetchPendingBookings() async {
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//
//     try {
//       // fetch BOTH normal dispatch-pending trips AND chopper pending-review trips
//       final bookings = await AdminApiService.fetchAllTrips(status: 'requested,pending');
//       setState(() {
//         _bookings = List<Map<String, dynamic>>.from(bookings);
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       Fluttertoast.showToast(msg: "Failed to load bookings: $e", backgroundColor: Colors.red);
//     }
//   }
//
//   Future<void> _handleCancel(String tripId) async {
//     try {
//       await AdminApiService.cancelTrip(tripId, "Cancelled by Admin");
//       Fluttertoast.showToast(msg: "Trip Cancelled");
//       _fetchPendingBookings();
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Cancellation failed: $e");
//     }
//   }
//
//   void _goToDispatch(Map<String, dynamic> booking) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DispatchManagementScreen(
//           tripId: booking['_id'] ?? booking['id'],
//           rideData: booking,
//         ),
//       ),
//     ).then((_) {
//       _fetchPendingBookings();
//     });
//   }
//
//   // contact action for Chopper "pending" bookings — no driver to dispatch
//   Future<void> _callPassenger(Map<String, dynamic> booking) async {
//     final phone = booking['rider']?['phone'] ?? booking['riderPhone'];
//     if (phone == null || phone.toString().isEmpty) {
//       Fluttertoast.showToast(msg: "No phone number on file for this passenger");
//       return;
//     }
//     final uri = Uri(scheme: 'tel', path: phone.toString());
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       Fluttertoast.showToast(msg: "Could not launch dialer");
//     }
//   }
//
//   Widget _buildPassengerDetails(Map<String, dynamic> booking) {
//     final rider = booking['rider'] as Map<String, dynamic>?;
//     final name = rider?['name'] ?? booking['riderName'] ?? 'Unknown';
//     final phone = rider?['phone'] ?? booking['riderPhone'] ?? 'No phone on file';
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Passenger: $name",
//           style: const TextStyle(fontWeight: FontWeight.w600),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 4),
//         Row(
//           children: [
//             const Icon(Icons.phone, size: 15, color: Colors.grey),
//             const SizedBox(width: 6),
//             Flexible(
//               child: Text(
//                 phone.toString(),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       ],
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
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPendingBookings),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.white))
//           : _bookings.isEmpty
//           ? const Center(child: Text("No pending bookings", style: TextStyle(color: Colors.white70, fontSize: 18)))
//           : RefreshIndicator(
//         onRefresh: _fetchPendingBookings,
//         color: Colors.red,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: _bookings.length,
//           itemBuilder: (context, index) {
//             final booking = _bookings[index];
//             final bookingId = booking['_id'] ?? booking['id'] ?? 'unknown';
//             final isChopperPending = booking['status'] == 'pending'; // flag
//
//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             "${booking['pickupLocation'] ?? 'N/A'} → ${booking['dropoffLocation'] ?? 'N/A'}",
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         if (isChopperPending)
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: Colors.deepPurple.withOpacity(0.15),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Text(
//                               "NEEDS CONTACT",
//                               style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 11),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const Divider(height: 20),
//
//                     _buildPassengerDetails(booking),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Pickup: ${booking['pickupLabel'] ?? booking['pickupLocation']?['address'] ?? 'N/A'}",
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Text(
//                       "Dropoff: ${booking['dropoffLabel'] ?? booking['dropoffLocation']?['address'] ?? 'N/A'}",
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Text("Fare: Ksh ${booking['fare'] ?? '0'}"),
//                     Text("Vehicle: ${booking['vehicleType'] ?? 'N/A'}"),
//                     if (booking['scheduledTime'] != null)
//                       Text(
//                         "Scheduled: ${booking['scheduledTime']}",
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         TextButton(
//                           onPressed: () => _handleCancel(bookingId),
//                           child: const Text("Reject", style: TextStyle(color: Colors.red)),
//                         ),
//                         const SizedBox(width: 8),
//
//                         // branch primary action: Chopper → call, otherwise → dispatch
//                         isChopperPending
//                             ? ElevatedButton.icon(
//                           onPressed: () => _callPassenger(booking),
//                           icon: const Icon(Icons.call, size: 18),
//                           label: const Text("Call Passenger"),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.deepPurple,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         )
//                             : ElevatedButton(
//                           onPressed: () => _goToDispatch(booking),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: const Text("Dispatch Driver"),
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
import 'package:url_launcher/url_launcher.dart';
import 'package:sizemore_taxi/adminapiservice/admin_api_service.dart';
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
      // fetch BOTH normal dispatch-pending trips AND chopper pending-review trips
      final bookings = await AdminApiService.fetchAllTrips(status: 'requested,pending');
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
      _fetchPendingBookings();
    });
  }

  // contact action for Chopper "pending" bookings — no driver to dispatch
  Future<void> _callPassenger(Map<String, dynamic> booking) async {
    final phone = booking['rider']?['phone'] ?? booking['riderPhone'];
    if (phone == null || phone.toString().isEmpty) {
      Fluttertoast.showToast(msg: "No phone number on file for this passenger");
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.toString());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Fluttertoast.showToast(msg: "Could not launch dialer");
    }
  }

  // ✅ Admin has manually called the passenger and worked things out —
  // this marks the Chopper trip as handled (pending -> accepted) so it
  // drops off this pending list. Hits the same endpoint the normal
  // "accept" flow uses; acceptTripByAdmin on the backend now allows
  // both "pending" and "requested" trips to transition to "accepted".
  Future<void> _markDispatched(String tripId) async {
    try {
      await AdminApiService.acceptTrip(tripId);
      Fluttertoast.showToast(msg: "Marked as dispatched");
      _fetchPendingBookings();
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update: $e", backgroundColor: Colors.red);
    }
  }

  Widget _buildPassengerDetails(Map<String, dynamic> booking) {
    final rider = booking['rider'] as Map<String, dynamic>?;
    final name = rider?['name'] ?? booking['riderName'] ?? 'Unknown';
    final phone = rider?['phone'] ?? booking['riderPhone'] ?? 'No phone on file';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Passenger: $name",
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.phone, size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                phone.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
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
            final isChopperPending = booking['status'] == 'pending'; // flag

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${booking['pickupLocation'] ?? 'N/A'} → ${booking['dropoffLocation'] ?? 'N/A'}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isChopperPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "NEEDS CONTACT",
                              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 20),

                    _buildPassengerDetails(booking),
                    const SizedBox(height: 8),
                    Text(
                      "Pickup: ${booking['pickupLabel'] ?? booking['pickupLocation']?['address'] ?? 'N/A'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Dropoff: ${booking['dropoffLabel'] ?? booking['dropoffLocation']?['address'] ?? 'N/A'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text("Fare: Ksh ${booking['fare'] ?? '0'}"),
                    Text("Vehicle: ${booking['vehicleType'] ?? 'N/A'}"),
                    if (booking['scheduledTime'] != null)
                      Text(
                        "Scheduled: ${booking['scheduledTime']}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _handleCancel(bookingId),
                          child: const Text("Reject", style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),

                        // Chopper (pending): manual call + a way to mark it handled.
                        // Everything else: straight into the normal dispatch flow.
                        if (isChopperPending) ...[
                          OutlinedButton.icon(
                            onPressed: () => _callPassenger(booking),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text("Call"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: const BorderSide(color: Colors.deepPurple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _markDispatched(bookingId),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text("Mark Dispatched"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ] else
                          ElevatedButton(
                            onPressed: () => _goToDispatch(booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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