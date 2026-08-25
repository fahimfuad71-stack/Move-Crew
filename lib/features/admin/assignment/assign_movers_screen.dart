import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/status_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/job_status_chip.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/sort_button.dart';
import '../../../data/models/admin_mover_assignment.dart';
import '../../../data/models/job.dart';
import '../../../data/models/mover_profile.dart';
import '../../../providers/admin_assignment_providers.dart';
import '../../../providers/admin_assignment_status_providers.dart';
import '../../../providers/theme_provider.dart';
import '../management/admin_mover_detail_screen.dart';

class AssignMoversScreen extends ConsumerStatefulWidget {
  const AssignMoversScreen({super.key});

  @override
  ConsumerState<AssignMoversScreen> createState() => _AssignMoversScreenState();
}

class _AssignMoversScreenState extends ConsumerState<AssignMoversScreen> {
  SortOrder _sortOrder = SortOrder.descending;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(approvedJobsProvider);
    final moversAsync = ref.watch(availableMoversProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Movers', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('APPROVED JOBS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor, letterSpacing: 1)),
                  SortButton(currentOrder: _sortOrder, onChanged: (o) => setState(() => _sortOrder = o)),
                ],
              ),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (jobs) {
                  return moversAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(e.toString())),
                    data: (movers) {
                      if (jobs.isEmpty) return const _EmptyView();

                      final sorted = List<Job>.from(jobs);
                      sorted.sort((a, b) => _sortOrder == SortOrder.descending
                          ? b.createdAt.compareTo(a.createdAt)
                          : a.createdAt.compareTo(b.createdAt));

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) => _JobAssignmentCard(job: sorted[index], movers: movers),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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
                        title: Row(
                          children: [
                            Text(mover.fullName),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AdminMoverDetailScreen(mover: mover)),
                                );
                              },
                              child: const Text('View Profile', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
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

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(job.jobCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              JobStatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 20),
          _AddressRow(icon: Icons.trip_origin_rounded, address: job.pickupAddress, label: 'PICKUP'),
          const Padding(
            padding: EdgeInsets.only(left: 11, top: 4, bottom: 4),
            child: SizedBox(height: 16, child: VerticalDivider(thickness: 2, width: 1)),
          ),
          _AddressRow(icon: Icons.location_on_rounded, address: job.destinationAddress, label: 'DESTINATION'),
          const Divider(height: 32),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 8),
              Text(job.moveDate.toString().split(' ')[0], style: TextStyle(color: Theme.of(context).hintColor)),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Text(job.startTime, style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
          const Divider(height: 32),
          const Text('ASSIGNED MOVERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.stormyLight, letterSpacing: 1)),
          const SizedBox(height: 12),
          assignmentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (assignments) {
              if (assignments.isEmpty) return Text('No movers assigned yet.', style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor));
              return Column(
                children: assignments.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MoverStatusRow(assignment: a),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          assignmentsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (assignments) {
              final hasRejected = assignments.any((a) => a.status == AssignmentStatus.rejected);
              final buttonText = assignments.isEmpty ? 'ASSIGN MOVERS' : hasRejected ? 'REASSIGN / ADD MOVERS' : 'ASSIGN MORE MOVERS';
              return ElevatedButton.icon(
                onPressed: () => _openMoverSelection(context: context, ref: ref, existingAssignments: assignments),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(buttonText),
              );
            },
          ),
        ],
      ),
    );
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
        color: AppColors.tealPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tealPrimary.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {
          final mover = MoverProfile(
            id: assignment.moverId,
            employeeCode: assignment.employeeCode,
            fullName: assignment.fullName,
            phone: assignment.phone,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminMoverDetailScreen(mover: mover)),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.tealPrimary.withOpacity(0.1),
              child: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.tealPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(assignment.employeeCode, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            AssignmentStatusChip(status: assignment.status),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.icon, required this.address, required this.label});
  final IconData icon;
  final String address;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.tealPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Theme.of(context).hintColor)),
              Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
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
