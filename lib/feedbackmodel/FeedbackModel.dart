// class FeedbackModel {
//
//   final String id;
//   final String userId;
//   final String userName;
//   final String userRole;
//
//   final String message;
//
//   final String type;
//
//   final String? tripId;
//   final String? driverId;
//   final String? driverName;    // new: populated info if present
//
//   final int rating;
//
//   final String timestamp;
//
//   final bool handled;
//
//   FeedbackModel({
//     required this.id,
//     required this.userId,
//     required this.userName,
//     required this.userRole,
//     required this.message,
//     required this.type,
//     this.tripId,
//     this.driverId,
//     this.driverName,
//     required this.rating,
//     required this.timestamp,
//     required this.handled,
//   });
//
//   factory FeedbackModel.fromJson(
//       Map<String, dynamic> json) {
//
//     return FeedbackModel(
//       id: json['_id'] ?? '',
//
//       userId: json['userId'] ?? '',
//
//       userName: json['userName'] ?? '',
//
//       userRole: json['userRole'] ?? '',
//
//       message: json['message'] ?? '',
//
//       type: json['type'] ?? 'feedback',
//
//       tripId: json['tripId'],
//
//       driverId: json['driverId'],
//
//       rating: json['rating'] ?? 0,
//
//       timestamp: json['timestamp'] ?? '',
//
//       handled: json['handled'] ?? false,
//     );
//   }
// }
class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String message;
  final String type;
  final String? tripId;
  final String? driverId;      // keep as the id
  final String? driverName;    // new: populated info if present
  final int rating;
  final String timestamp;
  final bool handled;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.message,
    required this.type,
    this.tripId,
    this.driverId,
    this.driverName,
    required this.rating,
    required this.timestamp,
    required this.handled,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    // driverId can be a plain string OR a populated object — handle both
    String? driverIdValue;
    String? driverNameValue;
    final rawDriver = json['driverId'];
    if (rawDriver is Map<String, dynamic>) {
      driverIdValue = rawDriver['_id']?.toString();
      driverNameValue = rawDriver['name']?.toString();
    } else if (rawDriver != null) {
      driverIdValue = rawDriver.toString();
    }

    // same defensive treatment for tripId, just in case you ever populate it too
    final rawTrip = json['tripId'];
    final tripIdValue = rawTrip is Map<String, dynamic>
        ? rawTrip['_id']?.toString()
        : rawTrip?.toString();

    return FeedbackModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userRole: json['userRole'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'feedback',
      tripId: tripIdValue,
      driverId: driverIdValue,
      driverName: driverNameValue,
      rating: json['rating'] ?? 0,
      timestamp: json['createdAt'] ?? json['timestamp'] ?? '',
      handled: json['handled'] ?? false,
    );
  }
}