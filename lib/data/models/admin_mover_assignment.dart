import '../../core/constants/status_enums.dart';

class AdminMoverAssignment {
  const AdminMoverAssignment({
    required this.assignmentId,
    required this.moverId,
    required this.employeeCode,
    required this.fullName,
    required this.status,
    this.phone,
    this.respondedAt,
  });

  final String assignmentId;
  final String moverId;
  final String employeeCode;
  final String fullName;
  final String? phone;
  final AssignmentStatus status;
  final DateTime? respondedAt;
}
