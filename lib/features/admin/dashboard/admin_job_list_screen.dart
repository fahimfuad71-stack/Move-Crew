import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/status_enums.dart';
import '../../../data/models/job.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../providers/admin_job_providers.dart';
import '../../../providers/admin_assignment_providers.dart';
import '../../../core/widgets/sort_button.dart';
import '../request/incoming_request_details_screen.dart';

final adminFilteredJobsProvider = FutureProvider.autoDispose.family<List<Job>, JobStatus?>((ref, status) {
  return ref.watch(adminJobRepositoryProvider).getAllJobs(status: status);
});

class AdminJobListScreen extends ConsumerStatefulWidget {
  const AdminJobListScreen({super.key, this.status});
  final JobStatus? status;

  @override
  ConsumerState<AdminJobListScreen> createState() => _AdminJobListScreenState();
}

class _AdminJobListScreenState extends ConsumerState<AdminJobListScreen> {
  SortOrder _sortOrder = SortOrder.descending;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(adminFilteredJobsProvider(widget.status));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(widget.status == null ? 'All Jobs' : '${widget.status!.value} Jobs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SortButton(
                  currentOrder: _sortOrder,
                  onChanged: (order) => setState(() => _sortOrder = order),
                ),
              ],
            ),
          ),
        ),
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs found.'));
          }

          final sortedJobs = List<Job>.from(jobs);
          if (_sortOrder == SortOrder.descending) {
            sortedJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else {
            sortedJobs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedJobs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _JobCard(job: sortedJobs[index]),
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E5EA)),
      ),
      child: InkWell(
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
                  Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _StatusChip(status: job.status, jobId: job.id),
                ],
              ),
              const SizedBox(height: 8),
              Text('From: ${job.pickupAddress}', style: const TextStyle(fontSize: 13)),
              Text('To: ${job.destinationAddress}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                'Requested: ${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  const _StatusChip({required this.status, required this.jobId});
  final JobStatus status;
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(jobAssignmentsProvider(jobId));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == JobStatus.assigned)
          assignmentsAsync.when(
            data: (list) {
              final hasRejected = list.any((a) => a.status == AssignmentStatus.rejected);
              if (hasRejected) {
                return const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: AssignmentStatusChip(status: AssignmentStatus.rejected),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        JobStatusChip(status: status),
      ],
    );
  }
}
