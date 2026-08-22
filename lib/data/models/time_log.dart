class TimeLog {
  final String? id;
  final String assignmentId;
  final String moverId;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final String status;

  TimeLog({
    this.id,
    required this.assignmentId,
    required this.moverId,
    this.clockInAt,
    this.clockOutAt,
    required this.status,
  });

  factory TimeLog.fromMap(Map<String, dynamic> map) {
    return TimeLog(
      id: map['id'],
      assignmentId: map['assignment_id'],
      moverId: map['mover_id'],
      clockInAt: map['clock_in_at'] != null
          ? DateTime.parse(map['clock_in_at'])
          : null,
      clockOutAt: map['clock_out_at'] != null
          ? DateTime.parse(map['clock_out_at'])
          : null,
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'mover_id': moverId,
      'clock_in_at': clockInAt?.toIso8601String(),
      'clock_out_at': clockOutAt?.toIso8601String(),
      'status': status,
    };
  }
}
