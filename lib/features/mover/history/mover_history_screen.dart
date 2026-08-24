import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/assignment.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../my_jobs/assignment_details_screen.dart';

final moverHistoryProvider = FutureProvider.autoDispose<List<Assignment>>((ref) {
  return ref.watch(moverAssignmentRepositoryProvider).getWorkHistory();
});

class MoverHistoryScreen extends ConsumerWidget {
  const MoverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(moverHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (assignments) {
        if (assignments.isEmpty) {
          return const Center(child: Text('No completed jobs yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _HistoryCard(assignment: assignments[index]),
        );
      },
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
                  const Text('COMPLETED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
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
