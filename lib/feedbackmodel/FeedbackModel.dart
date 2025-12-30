class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String message;
  final String timestamp;
  final bool handled;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.message,
    required this.timestamp,
    required this.handled,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['_id'],
      userId: json['userId'],
      userName: json['userName'],
      userRole: json['userRole'],
      message: json['message'],
      timestamp: json['timestamp'],
      handled: json['handled'],
    );
  }
}
