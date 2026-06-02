class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? photoUrl;
  final bool isBlocked;
  final String? nationalId;
  final bool isOnline;
  final Map<String, dynamic>? currentLocation;
  final bool isRiding;
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
    this.isBlocked = false,
    this.nationalId,
    this.isOnline = false,
    this.isRiding = false,
    this.currentLocation,
    this.carModel,
    this.carNumber,
    this.carType,
    this.licenseNumber,
    this.createdAt,
    this.updatedAt,
  });

  // --- HELPER GETTERS FOR GOOGLE MAPS ---
  // These ensure that 'lat' and 'lng' are always doubles even if the backend
  // sends them as ints, preventing type cast errors in Flutter.
  double? get lat {
    if (currentLocation == null || currentLocation!['lat'] == null) return null;
    return (currentLocation!['lat'] as num).toDouble();
  }

  double? get lng {
    if (currentLocation == null || currentLocation!['lng'] == null) return null;
    return (currentLocation!['lng'] as num).toDouble();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      photoUrl: json['photoUrl'],
      isBlocked: json['isBlocked'] ?? false,
      nationalId: json['nationalId']?.toString(),
      carModel: json['carModel'],
      carNumber: json['carNumber'],
      carType: json['carType'],
      licenseNumber: json['licenseNumber'],
      isOnline: json['isOnline'] ?? false,
      isRiding: json['isRiding'] ?? false,
      // Handle potential nested Map structure from backend
      currentLocation: json['currentLocation'] is Map
          ? Map<String, dynamic>.from(json['currentLocation'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? photoUrl,
    bool? isBlocked,
    String? nationalId,
    bool? isOnline,
    Map<String, dynamic>? currentLocation,
    bool? isRiding,
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
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      isRiding: isRiding ?? this.isRiding,
      carModel: carModel ?? this.carModel,
      carNumber: carNumber ?? this.carNumber,
      carType: carType ?? this.carType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}