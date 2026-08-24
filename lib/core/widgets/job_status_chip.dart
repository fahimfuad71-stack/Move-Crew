import 'package:flutter/material.dart';
import '../constants/status_enums.dart';

class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.status});
  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      JobStatus.requested => Colors.grey,
      JobStatus.approved => Colors.green,
      JobStatus.assigned => Colors.blue,
      JobStatus.inProgress => Colors.orange,
      JobStatus.completed => Colors.teal,
      JobStatus.rejected || JobStatus.cancelled => Colors.red,
    };

    return StatusChip(
      text: status.value,
      color: color,
    );
  }
}

class AssignmentStatusChip extends StatelessWidget {
  const AssignmentStatusChip({super.key, required this.status});
  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AssignmentStatus.pending => Colors.blue,
      AssignmentStatus.accepted => Colors.green,
      AssignmentStatus.rejected => Colors.red,
    };

    return StatusChip(
      text: status.value,
      color: color,
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 11,
    this.horizontalPadding = 8,
    this.verticalPadding = 4,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
