class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? photoUrl;
  final bool isBlocked;
  final String? nationalId;

  // Driver-specific fields
  final String? carModel;
  final String? carNumber;
  final String? carType;
  final String? licenseNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    required this.isBlocked,
    this.nationalId,
    this.carModel,
    this.carNumber,
    this.carType,
    this.licenseNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      photoUrl: json['photoUrl'],
      isBlocked: json['isBlocked'] ?? false,
      nationalId: json['nationalId'],
      carModel: json['carModel'],
      carNumber: json['carNumber'],
      carType: json['carType'],
      licenseNumber: json['licenseNumber'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'isBlocked': isBlocked,
    if (nationalId != null) 'nationalId': nationalId,
    if (carModel != null) 'carModel': carModel,
    if (carNumber != null) 'carNumber': carNumber,
    if (carType != null) 'carType': carType,
    if (licenseNumber != null) 'licenseNumber': licenseNumber,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? photoUrl,
    bool? isBlocked,
    String? nationalId,
    String? carModel,
    String? carNumber,
    String? carType,
    String? licenseNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      isBlocked: isBlocked ?? this.isBlocked,
      nationalId: nationalId ?? this.nationalId,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      carType: carType ?? this.carType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
