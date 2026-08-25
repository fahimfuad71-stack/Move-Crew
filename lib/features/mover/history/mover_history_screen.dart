import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('WORK HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1)),
                SortButton(
                  currentOrder: _sortOrder,
                  onChanged: (order) => setState(() => _sortOrder = order),
                ),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
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

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), // Increased bottom padding
                  itemCount: sorted.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _WorkSummaryHeader(assignments: assignments);
                    return _HistoryCard(assignment: sorted[index - 1]);
                  },
                );
              },
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.tealPrimary, AppColors.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealPrimary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('COMPLETED', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('${assignments.length} Jobs', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.white24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL HOURS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 4),
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

    return PremiumCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MoverAssignmentDetailsScreen(assignment: assignment),
          ),
        );
      },
      child: jobAsync.when(
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
        data: (job) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job.jobCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                JobStatusChip(status: job.status),
              ],
            ),
            const SizedBox(height: 16),
            _HistoryLocationItem(icon: Icons.trip_origin_rounded, address: job.pickupAddress, label: 'FROM'),
            const SizedBox(height: 12),
            _HistoryLocationItem(icon: Icons.location_on_rounded, address: job.destinationAddress, label: 'TO'),
            const Divider(height: 32),
            timeLogsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const Text('Error loading logs'),
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
                    Text('${logs.length} Sessions', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${totalHours.toStringAsFixed(1)} hrs logged', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryLocationItem extends StatelessWidget {
  const _HistoryLocationItem({required this.icon, required this.address, required this.label});
  final IconData icon;
  final String address;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.tealPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).hintColor)),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
