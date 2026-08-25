import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/mover_profile.dart';
import '../../../providers/admin_job_providers.dart';
import '../../../providers/review_providers.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../../../providers/theme_provider.dart';
import '../request/incoming_request_details_screen.dart';

class AdminMoverDetailScreen extends ConsumerWidget {
  const AdminMoverDetailScreen({super.key, required this.mover});
  final MoverProfile mover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminMoverHistoryProvider(mover.id));
    final reviewsAsync = ref.watch(moverReviewsProvider(mover.id));
    final logsAsync = ref.watch(adminMoverTimeLogsProvider(mover.id));
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(mover.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggle();
              },
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            ),
            const SizedBox(width: 8),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              _buildSectionHeader('Current / In Progress', isDark),
              ...active.map((a) => _JobHistoryCard(assignment: a)),
              const SizedBox(height: 24),
            ],
            if (pending.isNotEmpty) ...[
              _buildSectionHeader('Pending Response', isDark),
              ...pending.map((a) => _JobHistoryCard(assignment: a)),
              const SizedBox(height: 24),
            ],
            if (completed.isNotEmpty) ...[
              _buildSectionHeader('Completed Jobs', isDark),
              ...completed.map((a) => _JobHistoryCard(assignment: a)),
              const SizedBox(height: 24),
            ],
            if (rejected.isNotEmpty) ...[
              _buildSectionHeader('Rejected by Mover', isDark),
              ...rejected.map((a) => _JobHistoryCard(assignment: a)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : const Color(0xFF5C6470),
        ),
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

    return PremiumCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => IncomingRequestDetailsScreen(jobId: job.id)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusChip(assignment),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.tealPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(job.pickupAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.tealPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(job.destinationAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
        ],
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
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            final jobAsync = ref.watch(moverAssignedJobProvider(review.jobId));
            
            return PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.orange, size: 18)),
                      ),
                      jobAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (job) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.tealPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(job.jobCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (review.comment != null) Text(review.comment!, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 12),
                  Text('${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: PremiumCard(
                color: AppColors.tealPrimary,
                child: Column(
                  children: [
                    const Text('TOTAL WORK HOURS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('${totalHours.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final assignment = log['assignments'];
                  final jobMap = assignment is Map ? assignment['jobs'] : null;
                  final jobCode = jobMap is Map ? jobMap['job_code'] : 'Unknown Job';
                  
                  final clockIn = log['clock_in_at'] != null ? DateTime.parse(log['clock_in_at']) : null;
                  final clockOut = log['clock_out_at'] != null ? DateTime.parse(log['clock_out_at']) : null;
                  
                  return PremiumCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.tealPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.timer_outlined, color: AppColors.tealPrimary, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(clockIn != null ? '${clockIn.hour}:${clockIn.minute.toString().padLeft(2,'0')} - ${clockOut != null ? '${clockOut.hour}:${clockOut.minute.toString().padLeft(2,'0')}' : '--'}' : 'Pending', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (clockOut != null)
                          Text('${(clockOut.difference(clockIn!).inMinutes / 60.0).toStringAsFixed(1)}h', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                      ],
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
