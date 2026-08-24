import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/sort_button.dart';
import '../../../data/models/assignment.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../my_jobs/assignment_details_screen.dart';

final moverHistoryProvider = FutureProvider.autoDispose<List<Assignment>>((ref) {
  return ref.watch(moverAssignmentRepositoryProvider).getWorkHistory();
});

class MoverHistoryScreen extends ConsumerStatefulWidget {
  const MoverHistoryScreen({super.key});

  @override
  ConsumerState<MoverHistoryScreen> createState() => _MoverHistoryScreenState();
}

class _MoverHistoryScreenState extends ConsumerState<MoverHistoryScreen> {
  SortOrder _sortOrder = SortOrder.descending;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(moverHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
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
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (assignments) {
          if (assignments.isEmpty) {
            return const Center(child: Text('No completed jobs yet.'));
          }

          final sorted = List<Assignment>.from(assignments);
          if (_sortOrder == SortOrder.descending) {
            sorted.sort((a, b) => (b.job?.createdAt ?? DateTime(0)).compareTo(a.job?.createdAt ?? DateTime(0)));
          } else {
            sorted.sort((a, b) => (a.job?.createdAt ?? DateTime(0)).compareTo(b.job?.createdAt ?? DateTime(0)));
          }

          return Column(
            children: [
              _WorkSummaryHeader(assignments: assignments),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _HistoryCard(assignment: sorted[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkSummaryHeader extends ConsumerWidget {
  const _WorkSummaryHeader({required this.assignments});
  final List<Assignment> assignments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursAsync = ref.watch(moverTotalHoursProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E56A0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Completed Jobs', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${assignments.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total Work Hours', style: TextStyle(color: Colors.white70, fontSize: 13)),
              hoursAsync.when(
                loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
                data: (hours) => Text('${hours.toStringAsFixed(1)} hrs', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.assignment});
  final Assignment assignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(moverAssignedJobProvider(assignment.jobId));
    final timeLogsAsync = ref.watch(FutureProvider.autoDispose((ref) => 
      ref.watch(moverAssignmentRepositoryProvider).getJobTimeLogs(assignment.id)
    ));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E5EA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MoverAssignmentDetailsScreen(assignment: assignment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: jobAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => Text('Error loading job: $e'),
          data: (job) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  JobStatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('From: ${job.pickupAddress}', style: const TextStyle(fontSize: 13)),
              Text('To: ${job.destinationAddress}', style: const TextStyle(fontSize: 13)),
              const Divider(height: 24),
              timeLogsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const Text('Error loading time logs'),
                data: (logs) {
                  double totalHours = 0;
                  for (var log in logs) {
                    if (log['clock_in_at'] != null && log['clock_out_at'] != null) {
                      final inAt = DateTime.parse(log['clock_in_at']);
                      final outAt = DateTime.parse(log['clock_out_at']);
                      totalHours += outAt.difference(inAt).inMinutes / 60.0;
                    }
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Work Sessions: ${logs.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Total Hours: ${totalHours.toStringAsFixed(2)} hrs', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  );
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
