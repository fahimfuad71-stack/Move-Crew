import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/status_enums.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/mover_profile.dart';
import '../../../providers/admin_job_providers.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../request/incoming_request_details_screen.dart';

class AdminMoverDetailScreen extends ConsumerWidget {
  const AdminMoverDetailScreen({super.key, required this.mover});
  final MoverProfile mover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminMoverHistoryProvider(mover.id));
    final reviewsAsync = ref.watch(moverReviewsProvider(mover.id));
    final logsAsync = ref.watch(adminMoverTimeLogsProvider(mover.id));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(mover.fullName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Reviews'),
              Tab(text: 'Time Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MoverHistoryTab(historyAsync: historyAsync),
            _MoverReviewsTab(reviewsAsync: reviewsAsync),
            _MoverTimeLogsTab(logsAsync: logsAsync),
          ],
        ),
      ),
    );
  }
}

class _MoverHistoryTab extends StatelessWidget {
  const _MoverHistoryTab({required this.historyAsync});
  final AsyncValue<List<Assignment>> historyAsync;

  @override
  Widget build(BuildContext context) {
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (assignments) {
        if (assignments.isEmpty) return const Center(child: Text('No job history.'));

        final completed = assignments.where((a) => a.job?.status == JobStatus.completed).toList();
        final active = assignments.where((a) => a.job?.status != JobStatus.completed && a.status == AssignmentStatus.accepted).toList();
        final rejected = assignments.where((a) => a.status == AssignmentStatus.rejected).toList();
        final pending = assignments.where((a) => a.status == AssignmentStatus.pending).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (active.isNotEmpty) ...[
              _buildSectionHeader('Current / In Progress'),
              ...active.map((a) => _JobHistoryCard(assignment: a)),
              const SizedBox(height: 24),
            ],
            if (pending.isNotEmpty) ...[
              _buildSectionHeader('Pending Response'),
              ...pending.map((a) => _JobHistoryCard(assignment: a)),
              const SizedBox(height: 24),
            ],
            if (completed.isNotEmpty) ...[
              _buildSectionHeader('Completed Jobs'),
              ...completed.map((a) => _JobHistoryCard(assignment: a)),
              const SizedBox(height: 24),
            ],
            if (rejected.isNotEmpty) ...[
              _buildSectionHeader('Rejected by Mover'),
              ...rejected.map((a) => _JobHistoryCard(assignment: a)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5C6470)),
      ),
    );
  }
}

class _JobHistoryCard extends StatelessWidget {
  const _JobHistoryCard({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final job = assignment.job;
    if (job == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E5EA))),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => IncomingRequestDetailsScreen(jobId: job.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  _buildStatusChip(assignment),
                ],
              ),
              const SizedBox(height: 8),
              Text('${job.pickupAddress} -> ${job.destinationAddress}', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Assignment assignment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (assignment.status == AssignmentStatus.rejected)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: AssignmentStatusChip(status: AssignmentStatus.rejected),
          ),
        JobStatusChip(status: assignment.job?.status ?? JobStatus.requested),
      ],
    );
  }
}

class _MoverReviewsTab extends ConsumerWidget {
  const _MoverReviewsTab({required this.reviewsAsync});
  final AsyncValue reviewsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (reviews) {
        if (reviews.isEmpty) return const Center(child: Text('No reviews yet.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = reviews[index];
            final jobAsync = ref.watch(moverAssignedJobProvider(review.jobId));
            
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E5EA))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.orange, size: 16)),
                        ),
                        jobAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (job) => Text(
                            job.jobCode,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E56A0)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (review.comment != null) Text(review.comment!),
                    const SizedBox(height: 8),
                    Text('Date: ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MoverTimeLogsTab extends StatelessWidget {
  const _MoverTimeLogsTab({required this.logsAsync});
  final AsyncValue logsAsync;

  @override
  Widget build(BuildContext context) {
    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (logs) {
        if (logs.isEmpty) return const Center(child: Text('No time logs recorded.'));

        double totalHours = 0;
        for (var log in logs) {
          if (log['clock_in_at'] != null && log['clock_out_at'] != null) {
            final inAt = DateTime.parse(log['clock_in_at']);
            final outAt = DateTime.parse(log['clock_out_at']);
            totalHours += outAt.difference(inAt).inMinutes / 60.0;
          }
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                children: [
                  const Text('Total Lifetime Work', style: TextStyle(color: Colors.grey)),
                  Text('${totalHours.toStringAsFixed(2)} hrs', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E56A0))),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  // Handle deep nesting from simplified select
                  final assignment = log['assignments'];
                  final jobMap = assignment is Map ? assignment['jobs'] : null;
                  final jobCode = jobMap is Map ? jobMap['job_code'] : 'Unknown Job';
                  
                  final clockIn = log['clock_in_at'] != null ? DateTime.parse(log['clock_in_at']) : null;
                  final clockOut = log['clock_out_at'] != null ? DateTime.parse(log['clock_out_at']) : null;
                  
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E5EA))),
                    child: ListTile(
                      title: Text(jobCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(clockIn != null ? 'In: ${clockIn.hour}:${clockIn.minute.toString().padLeft(2,'0')} | Out: ${clockOut?.hour ?? '--'}:${clockOut?.minute.toString().padLeft(2,'0') ?? '--'}' : 'Pending'),
                      trailing: Text(clockOut != null ? '${(clockOut.difference(clockIn!).inMinutes / 60.0).toStringAsFixed(1)}h' : '--', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
