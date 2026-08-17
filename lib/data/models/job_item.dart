import '../../core/constants/status_enums.dart';

class JobItem {
  const JobItem({
    required this.id,
    required this.jobId,
    required this.name,
    required this.quantity,
    required this.status,
  });

  final int id;
  final String jobId;

  final String name;
  final int quantity;

  final JobItemStatus status;

  factory JobItem.fromMap(Map<String, dynamic> map) {
    return JobItem(
      id: (map['id'] as num).toInt(),
      jobId: map['job_id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toInt(),
      status: JobItemStatus.fromString(map['status'] as String),
    );
  }
}
