import 'package:flutter/material.dart';
import '../constants/status_enums.dart';
import '../theme/app_colors.dart';

class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.status});
  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      JobStatus.requested => AppColors.stormyLight,
      JobStatus.approved => AppColors.tealPrimary,
      JobStatus.assigned => AppColors.skyBlue,
      JobStatus.inProgress => Colors.orange,
      JobStatus.completed => AppColors.mintAccent,
      JobStatus.rejected || JobStatus.cancelled => AppColors.crimsonRed,
    };

    return StatusChip(
      text: status.value.toUpperCase(),
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
      AssignmentStatus.pending => AppColors.skyBlue,
      AssignmentStatus.accepted => AppColors.mintAccent,
      AssignmentStatus.rejected => AppColors.crimsonRed,
    };

    return StatusChip(
      text: status.value.toUpperCase(),
      color: color,
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 10,
    this.horizontalPadding = 10,
    this.verticalPadding = 6,
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
