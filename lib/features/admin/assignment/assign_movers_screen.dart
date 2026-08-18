import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../data/models/admin_mover_assignment.dart';
import '../../../data/models/job.dart';
import '../../../data/models/mover_profile.dart';
import '../../../providers/admin_assignment_providers.dart';
import '../../../providers/admin_assignment_status_providers.dart';

class AssignMoversScreen extends ConsumerWidget {
  const AssignMoversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(approvedJobsProvider);

    final moversAsync = ref.watch(availableMoversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Assign Movers',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(approvedJobsProvider);

          ref.invalidate(availableMoversProvider);

          await Future.wait([
            ref.read(approvedJobsProvider.future),
            ref.read(availableMoversProvider.future),
          ]);
        },
        child: jobsAsync.when(
          loading: () => const _LoadingView(),
          error: (error, stackTrace) => _ErrorView(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(approvedJobsProvider);
            },
          ),
          data: (jobs) {
            return moversAsync.when(
              loading: () => const _LoadingView(),
              error: (error, stackTrace) => _ErrorView(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(availableMoversProvider);
                },
              ),
              data: (movers) {
                if (jobs.isEmpty) {
                  return const _EmptyView();
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: jobs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _JobAssignmentCard(job: jobs[index], movers: movers);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _JobAssignmentCard extends ConsumerWidget {
  const _JobAssignmentCard({required this.job, required this.movers});

  final Job job;
  final List<MoverProfile> movers;

  Future<void> _openMoverSelection({
    required BuildContext context,
    required WidgetRef ref,
    required List<AdminMoverAssignment> existingAssignments,
  }) async {
    if (movers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No movers are available.')));

      return;
    }

    final assignmentByMover = <String, AdminMoverAssignment>{
      for (final assignment in existingAssignments)
        assignment.moverId: assignment,
    };

    final selectedIds = <String>{};

    final hasSelectableMover = movers.any((mover) {
      final current = assignmentByMover[mover.id];

      return current == null || current.status == AssignmentStatus.rejected;
    });

    if (!hasSelectableMover) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No additional movers are currently available for this job.',
          ),
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assign movers to ${job.jobCode}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text('Select one or more movers:'),

                    const SizedBox(height: 12),

                    ...movers.map((mover) {
                      final existing = assignmentByMover[mover.id];

                      final canSelect =
                          existing == null ||
                          existing.status == AssignmentStatus.rejected;

                      final selected = selectedIds.contains(mover.id);

                      String statusText;

                      if (existing == null) {
                        statusText = 'Not assigned';
                      } else {
                        statusText = existing.status.value;
                      }

                      final phone =
                          mover.phone == null || mover.phone!.trim().isEmpty
                          ? ''
                          : ' - ${mover.phone}';

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selected,
                        onChanged: canSelect
                            ? (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedIds.add(mover.id);
                                  } else {
                                    selectedIds.remove(mover.id);
                                  }
                                });
                              }
                            : null,
                        title: Text(mover.fullName),
                        subtitle: Text(
                          '${mover.employeeCode}$phone\n'
                          'Status: $statusText',
                        ),
                        isThreeLine: true,
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(true);
                        },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedIds.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final finalConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm assignment'),
          content: Text(
            'Assign ${selectedIds.length} '
            'mover${selectedIds.length == 1 ? '' : 's'} '
            'to ${job.jobCode}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    if (finalConfirmed != true) {
      return;
    }

    try {
      final result = await ref
          .read(adminAssignmentRepositoryProvider)
          .assignMovers(jobId: job.id, moverIds: selectedIds.toList());

      ref.invalidate(approvedJobsProvider);

      ref.invalidate(jobAssignmentsProvider(job.id));

      ref.invalidate(adminMoverAssignmentsProvider(job.id));

      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: Color(0xFF2E9E5B),
            ),
            title: const Text('Movers Assigned'),
            content: Text(
              '${result.jobCode} is now '
              '${result.newStatus.value}.\n\n'
              '${result.assignedCount} '
              'assignment'
              '${result.assignedCount == 1 ? '' : 's'} '
              'created or updated.',
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
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not assign movers: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(adminMoverAssignmentsProvider(job.id));

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E5EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.jobCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _JobStatusChip(status: job.status.value),
              ],
            ),

            const SizedBox(height: 16),

            _InfoRow(
              icon: Icons.trip_origin_rounded,
              label: 'Pickup',
              value: job.pickupAddress,
            ),

            const SizedBox(height: 10),

            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Destination',
              value: job.destinationAddress,
            ),

            const Divider(height: 28),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF5C6470),
                ),
                const SizedBox(width: 8),
                Text(_formatDate(job.moveDate)),
                const Spacer(),
                const Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: Color(0xFF5C6470),
                ),
                const SizedBox(width: 6),
                Text(_formatTime(job.startTime)),
              ],
            ),

            const Divider(height: 32),

            const Text(
              'Assigned Movers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            assignmentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (error, stackTrace) =>
                  Text('Could not load mover statuses: $error'),
              data: (assignments) {
                if (assignments.isEmpty) {
                  return const Text(
                    'No movers assigned yet.',
                    style: TextStyle(color: Color(0xFF5C6470)),
                  );
                }

                return Column(
                  children: assignments
                      .map(
                        (assignment) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MoverStatusRow(assignment: assignment),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 12),

            assignmentsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (assignments) {
                final hasRejected = assignments.any(
                  (assignment) =>
                      assignment.status == AssignmentStatus.rejected,
                );

                final buttonText = assignments.isEmpty
                    ? 'Assign Movers'
                    : hasRejected
                    ? 'Reassign / Add Movers'
                    : 'Assign More Movers';

                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E56A0),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () => _openMoverSelection(
                      context: context,
                      ref: ref,
                      existingAssignments: assignments,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(buttonText),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/'
        '${date.month}/'
        '${date.year}';
  }

  static String _formatTime(String time) {
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

class _MoverStatusRow extends StatelessWidget {
  const _MoverStatusRow({required this.assignment});

  final AdminMoverAssignment assignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFD7E6F7),
            child: Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: Color(0xFF1E56A0),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  assignment.employeeCode,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5C6470),
                  ),
                ),
              ],
            ),
          ),

          _AssignmentStatusChip(status: assignment.status),
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
    late final Color color;

    switch (status) {
      case AssignmentStatus.pending:
        color = const Color(0xFF9AA5B1);
        break;

      case AssignmentStatus.accepted:
        color = const Color(0xFF2E9E5B);
        break;

      case AssignmentStatus.rejected:
        color = const Color(0xFFD64545);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _JobStatusChip extends StatelessWidget {
  const _JobStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final assigned = status == 'ASSIGNED';

    final color = assigned ? const Color(0xFF1E7FCB) : const Color(0xFF2E9E5B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
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
        Icon(icon, size: 20, color: const Color(0xFF1E56A0)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C6470)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: const [
        SizedBox(height: 170),
        Icon(
          Icons.assignment_turned_in_outlined,
          size: 72,
          color: Color(0xFF9AA5B1),
        ),
        SizedBox(height: 20),
        Text(
          'No jobs waiting for movers',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Approved or assigned jobs that can receive movers will appear here.',
          textAlign: TextAlign.center,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline_rounded, size: 52),
        const SizedBox(height: 12),
        const Text(
          'Could not load assignment data',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}
