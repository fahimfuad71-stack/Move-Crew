import '../../core/constants/status_enums.dart';

class Assignment {
  const Assignment({
    required this.id,
    required this.jobId,
    required this.moverId,
    required this.status,
    this.respondedAt,
  });

  final String id;
  final String jobId;
  final String moverId;
  final AssignmentStatus status;
  final DateTime? respondedAt;

  factory Assignment.fromMap(Map<String, dynamic> map) {
    final respondedAtValue = map['responded_at'];

    return Assignment(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      moverId: map['mover_id'] as String,
      status: AssignmentStatus.fromString(map['status'] as String),
      respondedAt: respondedAtValue == null
          ? null
          : DateTime.parse(respondedAtValue as String),
    );
  }
}
