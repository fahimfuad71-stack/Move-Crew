import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../data/models/assignment.dart';
import '../../../data/models/job.dart';
import '../../../data/models/job_item.dart';
import '../../../providers/mover_assignment_providers.dart';
import '../active_job/start_job_controller.dart';

class MoverAssignmentDetailsScreen extends ConsumerStatefulWidget {
  const MoverAssignmentDetailsScreen({required this.assignment, super.key});

  final Assignment assignment;

  @override
  ConsumerState<MoverAssignmentDetailsScreen> createState() =>
      _MoverAssignmentDetailsScreenState();
}

class _MoverAssignmentDetailsScreenState
    extends ConsumerState<MoverAssignmentDetailsScreen> {
  bool _processing = false;

  Future<void> _respond({required Job job, required bool accept}) async {
    final action = accept ? 'Accept' : 'Reject';

    // -----------------------------------------------------
    // CONFIRMATION REQUIRED BEFORE ANY STATE CHANGE
    // -----------------------------------------------------

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action assignment?'),
          content: Text(
            accept
                ? 'Accept ${job.jobCode}? '
                      'You will be assigned to this moving job.'
                : 'Reject ${job.jobCode}? '
                      'MoveCrew Admin will see that you rejected this assignment.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accept
                    ? const Color(0xFF2E9E5B)
                    : const Color(0xFFD64545),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final repository = ref.read(moverAssignmentRepositoryProvider);

      final result = accept
          ? await repository.acceptAssignment(widget.assignment.id)
          : await repository.rejectAssignment(widget.assignment.id);

      ref.invalidate(myMoverAssignmentsProvider);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: Icon(
              accept
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              size: 48,
              color: accept ? const Color(0xFF2E9E5B) : const Color(0xFFD64545),
            ),
            title: Text(accept ? 'Assignment Accepted' : 'Assignment Rejected'),
            content: Text(
              '${job.jobCode} is now '
              '${result.newStatus.value} for you.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not respond to assignment: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(
      moverAssignedJobProvider(widget.assignment.jobId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Assignment Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(moverAssignedJobProvider(widget.assignment.jobId));
          },
        ),
        data: (job) {
          final itemsAsync = ref.watch(moverAssignedJobItemsProvider(job.id));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeaderCard(job: job, assignment: widget.assignment),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Move Information',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.trip_origin_rounded,
                      label: 'Pickup',
                      value: job.pickupAddress,
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Destination',
                      value: job.destinationAddress,
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Move Date',
                      value: _formatDate(job.moveDate),
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Start Time',
                      value: _formatTime(job.startTime),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Instructions',
                child: Text(
                  job.instructions == null || job.instructions!.trim().isEmpty
                      ? 'No special instructions provided.'
                      : job.instructions!,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Moving Items',
                child: itemsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Text('Could not load items: $error'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('No moving items found.');
                    }

                    return Column(
                      children: List.generate(items.length, (index) {
                        final item = items[index];

                        return Column(
                          children: [
                            _ItemRow(item: item),
                            if (index < items.length - 1)
                              const Divider(height: 24),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              if (widget.assignment.status == AssignmentStatus.pending)
                _ResponseButtons(
                  processing: _processing,
                  onAccept: () {
                    _respond(job: job, accept: true);
                  },
                  onReject: () {
                    _respond(job: job, accept: false);
                  },
                )
              else if (widget.assignment.status == AssignmentStatus.accepted)
                Column(
                  children: [
                    _RespondedCard(status: widget.assignment.status),
                    const SizedBox(height: 16),
                    _StartStopJobButtons(
                      assignmentId: widget.assignment.id,
                      moverId: widget.assignment.moverId,
                    ),
                  ],
                )
              else
                _RespondedCard(status: widget.assignment.status),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _formatTime(String time) {
    final parts = time.split(':');

    if (parts.length < 2) {
      return time;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return time;
    }

    final suffix = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    return '$displayHour:'
        '${minute.toString().padLeft(2, '0')} '
        '$suffix';
  }
}

class _ResponseButtons extends StatelessWidget {
  const _ResponseButtons({
    required this.processing,
    required this.onAccept,
    required this.onReject,
  });

  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD64545),
              minimumSize: const Size(0, 52),
            ),
            onPressed: processing ? null : onReject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject'),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E9E5B),
              minimumSize: const Size(0, 52),
            ),
            onPressed: processing ? null : onAccept,
            icon: processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(processing ? 'Processing...' : 'Accept'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EA)),
      ),
      child: Text(
        'You have already responded to this assignment.\n'
        'Current assignment status: ${status.value}',
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.5),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.jobCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _AssignmentStatusChip(status: assignment.status),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Job status: ASSIGNED',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AssignmentStatusChip extends StatelessWidget {
  const _AssignmentStatusChip({required this.status});

  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      AssignmentStatus.pending => 'Pending',
      AssignmentStatus.accepted => 'Accepted',
      AssignmentStatus.rejected => 'Rejected',
    };

    final color = switch (status) {
      AssignmentStatus.pending => const Color(0xFF9AA5B1),
      AssignmentStatus.accepted => const Color(0xFF2E9E5B),
      AssignmentStatus.rejected => const Color(0xFFD64545),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1E56A0)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C6470)),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final JobItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E56A0)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          'Qty: ${item.quantity}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52),
            const SizedBox(height: 12),
            const Text(
              'Could not load assignment',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartStopJobButtons extends ConsumerStatefulWidget {
  const _StartStopJobButtons({
    required this.assignmentId,
    required this.moverId,
  });

  final String assignmentId;
  final String moverId;

  @override
  ConsumerState<_StartStopJobButtons> createState() =>
      _StartStopJobButtonsState();
}

class _StartStopJobButtonsState extends ConsumerState<_StartStopJobButtons> {
  bool running = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRunningState();
  }

  Future<void> _loadRunningState() async {
    final controller = ref.read(startJobControllerProvider);

    final active = await controller.isActive(widget.assignmentId);

    if (active) {
      await controller.start(
        assignmentId: widget.assignmentId,
        moverId: widget.moverId,
      );
    }

    if (!mounted) return;

    setState(() {
      running = active;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: const Color(0xFF1E56A0),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Job & Enable Tracking'),

          onPressed: running
              ? null
              : () async {
                  await ref
                      .read(startJobControllerProvider)
                      .start(
                        assignmentId: widget.assignmentId,
                        moverId: widget.moverId,
                      );

                  setState(() {
                    running = true;
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Job started. Location tracking enabled.',
                        ),
                      ),
                    );
                  }
                },
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            foregroundColor: Colors.red,
          ),
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Clock Out & Stop Tracking'),

          onPressed: running
              ? () async {
                  await ref
                      .read(startJobControllerProvider)
                      .stop(assignmentId: widget.assignmentId);

                  setState(() {
                    running = false;
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clocked out. Tracking stopped.'),
                      ),
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }
}
