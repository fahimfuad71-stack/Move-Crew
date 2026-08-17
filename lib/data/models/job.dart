import '../../core/constants/status_enums.dart';

class Job {
  const Job({
    required this.id,
    required this.jobCode,
    required this.customerId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.moveDate,
    required this.startTime,
    required this.status,
    required this.createdAt,
    this.instructions,
  });

  final String id;
  final String jobCode;
  final String customerId;

  final String pickupAddress;
  final String destinationAddress;

  final DateTime moveDate;

  /// Stored by PostgreSQL as TIME.
  ///
  /// Keeping this as a String in the data layer avoids
  /// coupling database models to Flutter UI classes.
  final String startTime;

  final String? instructions;

  final JobStatus status;

  final DateTime createdAt;

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      jobCode: map['job_code'] as String,
      customerId: map['customer_id'] as String,
      pickupAddress: map['pickup_address'] as String,
      destinationAddress: map['destination_address'] as String,
      moveDate: DateTime.parse(map['move_date'] as String),
      startTime: map['start_time'] as String,
      instructions: map['instructions'] as String?,
      status: JobStatus.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
