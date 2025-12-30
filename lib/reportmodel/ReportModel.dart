class ReportModel {
  final String id;
  final String userId;
  final String message;
  final DateTime date;
  final String status; // "Pending", "Resolved", "Escalated"

  ReportModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.date,
    required this.status,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['_id'],
      userId: json['userId'],
      message: json['message'],
      date: DateTime.parse(json['date']),
      status: json['status'],
    );
  }
}
