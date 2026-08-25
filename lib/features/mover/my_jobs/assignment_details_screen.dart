import 'package:flutter/material.dart';
import '../active_job/mover_live_map_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/job.dart';
import '../../../data/models/job_item.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../../../providers/job_item_provider.dart';
import '../../../providers/theme_provider.dart';
import '../active_job/start_job_controller.dart';

class MoverAssignmentDetailsScreen extends ConsumerStatefulWidget {
  const MoverAssignmentDetailsScreen({required this.assignment, super.key});

  final Assignment assignment;

  @override
  ConsumerState<MoverAssignmentDetailsScreen> createState() => _MoverAssignmentDetailsScreenState();
}

class _MoverAssignmentDetailsScreenState extends ConsumerState<MoverAssignmentDetailsScreen> {
  bool _processing = false;

  Future<void> _respond({required Job job, required bool accept}) async {
    final action = accept ? 'Accept' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action assignment?'),
          content: Text(
            accept
                ? 'Accept ${job.jobCode}? You will be assigned to this moving job.'
                : 'Reject ${job.jobCode}? MoveCrew Admin will see that you rejected this assignment.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accept ? AppColors.tealPrimary : AppColors.crimsonRed,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _processing = true);

    try {
      final repository = ref.read(moverAssignmentRepositoryProvider);
      final result = accept
          ? await repository.acceptAssignment(widget.assignment.id)
          : await repository.rejectAssignment(widget.assignment.id);

      ref.invalidate(myMoverAssignmentsProvider);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: Icon(
              accept ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              size: 48,
              color: accept ? AppColors.tealPrimary : AppColors.crimsonRed,
            ),
            title: Text(accept ? 'Assignment Accepted' : 'Assignment Rejected'),
            content: Text('${job.jobCode} is now ${result.newStatus.value} for you.'),
            actions: [
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Done')),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(moverAssignedJobProvider(widget.assignment.jobId));
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (job) {
          final itemsAsync = ref.watch(moverAssignedJobItemsProvider(job.id));

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _HeaderCard(job: job, assignment: widget.assignment),
              const SizedBox(height: 24),
              const Text('MOVE INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              PremiumCard(
                child: Column(
                  children: [
                    _DetailItem(icon: Icons.trip_origin_rounded, label: 'PICKUP', value: job.pickupAddress),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                    _DetailItem(icon: Icons.location_on_rounded, label: 'DESTINATION', value: job.destinationAddress),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                    Row(
                      children: [
                        Expanded(child: _DetailItem(icon: Icons.calendar_today_rounded, label: 'DATE', value: job.moveDate.toString().split(' ')[0])),
                        Expanded(child: _DetailItem(icon: Icons.access_time_rounded, label: 'TIME', value: job.startTime)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('INSTRUCTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              PremiumCard(
                child: Text(
                  job.instructions == null || job.instructions!.trim().isEmpty ? 'No special instructions provided.' : job.instructions!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text('MOVING ITEMS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (items) => PremiumCard(
                  child: items.isEmpty
                      ? const Text('No items found.')
                      : Column(
                          children: List.generate(items.length, (index) {
                            return Column(
                              children: [
                                _ItemRow(item: items[index], jobId: job.id, assignmentStatus: widget.assignment.status),
                                if (index < items.length - 1) const Divider(height: 24),
                              ],
                            );
                          }),
                        ),
                ),
              ),
              const SizedBox(height: 32),
              if (widget.assignment.status == AssignmentStatus.pending)
                _ResponseButtons(
                  processing: _processing,
                  onAccept: () => _respond(job: job, accept: true),
                  onReject: () => _respond(job: job, accept: false),
                )
              else if (widget.assignment.status == AssignmentStatus.accepted)
                Column(
                  children: [
                    _RespondedCard(status: widget.assignment.status),
                    const SizedBox(height: 16),
                    _StartStopJobButtons(
                      assignmentId: widget.assignment.id,
                      moverId: widget.assignment.moverId,
                      jobId: job.id,
                      jobStatus: job.status,
                    ),
                    const SizedBox(height: 16),
                    _CompleteJobButton(job: job, assignmentId: widget.assignment.id),
                  ],
                )
              else
                _RespondedCard(status: widget.assignment.status),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.job, required this.assignment});
  final Job job;
  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.tealPrimary.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.tealPrimary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.assignment_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.jobCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('YOUR ASSIGNMENT', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
              ],
            ),
          ),
          _AssignmentStatusChip(assignmentStatus: assignment.status, jobStatus: job.status),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

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
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item, required this.jobId, required this.assignmentStatus});
  final JobItem item;
  final String jobId;
  final AssignmentStatus assignmentStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAccepted = assignmentStatus == AssignmentStatus.accepted;
    return Row(
      children: [
        const Icon(Icons.inventory_2_rounded, size: 20, color: AppColors.tealPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Qty: ${item.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        if (isAccepted)
          TextButton(
            onPressed: () async {
              final newStatus = item.status == JobItemStatus.pending ? 'COLLECTED' : 'DELIVERED';
              if (item.status == JobItemStatus.delivered) return;
              await ref.read(jobItemRepositoryProvider).updateStatus(itemId: item.id, status: newStatus);
              ref.invalidate(moverAssignedJobItemsProvider(jobId));
            },
            child: Text(
              item.status == JobItemStatus.pending ? 'COLLECT' : item.status == JobItemStatus.collected ? 'DELIVER' : 'DONE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: item.status == JobItemStatus.delivered ? Colors.grey : AppColors.tealPrimary,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(item.status.value.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
      ],
    );
  }
}

class _ResponseButtons extends StatelessWidget {
  const _ResponseButtons({required this.processing, required this.onAccept, required this.onReject});
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: processing ? null : onReject,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.crimsonRed), foregroundColor: AppColors.crimsonRed, minimumSize: const Size(0, 56)),
            child: const Text('REJECT'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: processing ? null : onAccept,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary, minimumSize: const Size(0, 56)),
            child: processing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ACCEPT'),
          ),
        ),
      ],
    );
  }
}

class _RespondedCard extends StatelessWidget {
  const _RespondedCard({required this.status});
  final AssignmentStatus status;
  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: Colors.grey.withOpacity(0.1),
      child: Center(
        child: Text(
          'Assignment ${status.value.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _AssignmentStatusChip extends StatelessWidget {
  const _AssignmentStatusChip({required this.assignmentStatus, required this.jobStatus});
  final AssignmentStatus assignmentStatus;
  final JobStatus jobStatus;
  @override
  Widget build(BuildContext context) {
    final status = (assignmentStatus == AssignmentStatus.accepted && jobStatus == JobStatus.inProgress)
        ? JobStatus.inProgress
        : (assignmentStatus == AssignmentStatus.accepted && jobStatus == JobStatus.completed)
            ? JobStatus.completed
            : null;
    if (status != null) return JobStatusChip(status: status);
    return JobStatusChip(status: JobStatus.requested); // Fallback to a styled chip
  }
}

class _StartStopJobButtons extends ConsumerStatefulWidget {
  const _StartStopJobButtons({required this.assignmentId, required this.moverId, required this.jobId, required this.jobStatus});
  final String assignmentId;
  final String moverId;
  final String jobId;
  final JobStatus jobStatus;
  @override
  ConsumerState<_StartStopJobButtons> createState() => _StartStopJobButtonsState();
}

class _StartStopJobButtonsState extends ConsumerState<_StartStopJobButtons> {
  bool running = false;
  @override
  void initState() {
    super.initState();
    _checkActive();
  }
  Future<void> _checkActive() async {
    final active = await ref.read(startJobControllerProvider).isActive(widget.assignmentId);
    if (mounted) setState(() => running = active);
  }
  @override
  Widget build(BuildContext context) {
    if (widget.jobStatus == JobStatus.completed) return const SizedBox.shrink();
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: running ? null : () async {
            await ref.read(startJobControllerProvider).start(assignmentId: widget.assignmentId, moverId: widget.moverId);
            ref.invalidate(moverAssignedJobProvider(widget.jobId));
            setState(() => running = true);
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('START JOB & TRACKING'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
        ),
        const SizedBox(height: 12),
        if (running)
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MoverLiveMapScreen(assignmentId: widget.assignmentId))),
            icon: const Icon(Icons.map_rounded),
            label: const Text('VIEW LIVE MAP'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue, minimumSize: const Size(double.infinity, 56)),
          ),
        const SizedBox(height: 12),
        if (running)
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(startJobControllerProvider).stop(assignmentId: widget.assignmentId);
              ref.invalidate(moverAssignedJobProvider(widget.jobId));
              setState(() => running = false);
            },
            icon: const Icon(Icons.stop_rounded),
            label: const Text('STOP TRACKING'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.crimsonRed, side: const BorderSide(color: AppColors.crimsonRed), minimumSize: const Size(double.infinity, 56)),
          ),
      ],
    );
  }
}

class _CompleteJobButton extends ConsumerWidget {
  const _CompleteJobButton({required this.job, required this.assignmentId});
  final Job job;
  final String assignmentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (job.status == JobStatus.completed) return const SizedBox.shrink();
    final itemsAsync = ref.watch(moverAssignedJobItemsProvider(job.id));
    return itemsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final allDelivered = items.isNotEmpty && items.every((i) => i.status == JobItemStatus.delivered);
        return ElevatedButton(
          onPressed: allDelivered ? () async {
            // Automatically stop tracking/clock out if still running
            final controller = ref.read(startJobControllerProvider);
            final isActive = await controller.isActive(assignmentId);
            if (isActive) {
              await controller.stop(assignmentId: assignmentId);
            }

            await ref.read(moverAssignmentRepositoryProvider).completeJob(job.id);
            ref.invalidate(moverAssignedJobProvider(job.id));
            ref.invalidate(myMoverAssignmentsProvider);
            ref.invalidate(moverTotalHoursProvider);
          } : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.mintAccent, minimumSize: const Size(double.infinity, 60)),
          child: Text(allDelivered ? 'MARK AS COMPLETED' : 'DELIVER ALL ITEMS TO COMPLETE'),
        );
      },
    );
  }
}
