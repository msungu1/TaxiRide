class RatingModel {
  final String id;
  final String riderName;
  final String riderPhone;
  final String driverName;
  final String driverPhone;
  final String carModel;
  final String carNumber;
  final int stars;
  final String timestamp;

  RatingModel({
    required this.id,
    required this.riderName,
    required this.riderPhone,
    required this.driverName,
    required this.driverPhone,
    required this.carModel,
    required this.carNumber,
    required this.stars,
    required this.timestamp,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    final rider = json['rider'] ?? {};
    final driver = json['driver'] ?? {};

    return RatingModel(
      id: json['_id'] ?? '',
      riderName: rider['name'] ?? 'Unknown Rider',
      riderPhone: rider['phone'] ?? '',
      driverName: driver['name'] ?? 'Unknown Driver',
      driverPhone: driver['phone'] ?? '',
      carModel: driver['carModel'] ?? '',
      carNumber: driver['carNumber'] ?? '',
      stars: json['stars'] ?? 0,
      timestamp: json['createdAt'] ?? '',
    );
  }
}