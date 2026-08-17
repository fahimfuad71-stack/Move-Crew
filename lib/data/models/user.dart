import '../../core/constants/status_enums.dart';

class AppUser {
  final String id;
  final String fullName;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      role: UserRole.fromString(json['role'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
