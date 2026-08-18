class MoverProfile {
  const MoverProfile({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.phone,
  });

  final String id;
  final String employeeCode;
  final String fullName;
  final String? phone;

  factory MoverProfile.fromMaps({
    required Map<String, dynamic> mover,
    required Map<String, dynamic> user,
  }) {
    return MoverProfile(
      id: mover['id'] as String,
      employeeCode: mover['employee_code'] as String,
      fullName: user['full_name'] as String,
      phone: user['phone'] as String?,
    );
  }
}
