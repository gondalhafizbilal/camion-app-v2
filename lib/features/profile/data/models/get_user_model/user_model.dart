class GetUserModel {
  final String id;
  final String email;
  final String phone;
  final String? password;
  final String fullName;
  final bool isActive;
  final String code;
  final String role;
  final String notificationToken;
  final DateTime? markedForDeletionAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GetUserModel({
    required this.id,
    required this.email,
    required this.phone,
    this.password,
    required this.fullName,
    required this.isActive,
    required this.code,
    required this.role,
    required this.notificationToken,
    this.markedForDeletionAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GetUserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      final raw = value?.toString() ?? '';
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return GetUserModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      email: (json['email'] ?? json['emailAddress'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      password: json['password'],
      fullName: (json['fullName'] ?? '').toString(),
      isActive: (json['isActive'] ?? true) == true,
      code: (json['code'] ?? '').toString(),
      role: (json['role'] ?? 'customer').toString(),
      notificationToken: (json['notificationToken'] ?? '').toString(),
      markedForDeletionAt: (() {
        final raw = (json['markedForDeletionAt'] ?? '').toString();
        return raw.trim().isEmpty ? null : DateTime.tryParse(raw);
      })(),
      deletedAt: (() {
        final raw = (json['deletedAt'] ?? '').toString();
        return raw.trim().isEmpty ? null : DateTime.tryParse(raw);
      })(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'password': password,
      'fullName': fullName,
      'isActive': isActive,
      'code': code,
      'role': role,
      'notificationToken': notificationToken,
      'markedForDeletionAt': markedForDeletionAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
